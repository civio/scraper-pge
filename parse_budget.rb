#!/usr/bin/env ruby

# Notes:
#
# The output includes both line items and subtotals. We expect whoever is using this data
# to take care of avoiding double counting. In order to deduplicate the data here we would
# need to guess what the consumer wants to do with the data (does it care about details
# or just chapter subtotals? ...)
#
# We do however remove the programme-level (could be convinced about changing this) and 
# public-body-level subtotals (because they don't fit well with the output file structure).
#
# This is also related to the fact that the budget breakdown doesn't go to the same level
# of detail for all bodies or chapters, so the output is less consistent that we'd like:
# budget expenses are organized in chapters > articles > headings > items. When looking at 
# an expense breakdown, the sum of all the chapters (codes of the form 'n') equals the sum of all 
# articles (codes 'nn') and the sum of all expenses (codes 'nnn'). I.e. the breakdown is exhaustive 
# down to that level. Note however that not all headings are broken into items (codes 'nnnnn'); 
# hence, just adding up all the items will result in a much smaller amount.
#
# To keep things interesting, in some cases (at least chapter 6 for Social Security, see 
# ProgrammeBreakdown notes) a chapter is not even broken down into articles.
#
require 'csv'
require 'unicode_utils'

require_relative 'lib/budget'

budget_id = ARGV[0]
year = budget_id[0..3]  # Sometimes there's a P for 'Proposed' at the end. Ignore that bit
is_final = (budget_id.length == 4)
output_path = File.join(".", "output", budget_id)


# RETRIEVE BUDGET LINES
#
# Note: the breakdowns in the Green books (Serie Verde) have more detail on the line
#       items, but they do not include the Social Security programmes. So we need to
#       combine both in order to get the full budget. (Or we could use only the Red ones, 
#       but we'd lose quite a bit of detail. Compare f.ex. the chapter 1/2 detail for
#       programme 333A in the green [1] vs red [2] pages.)
#
# [1]: http://www.sepg.pap.minhap.gob.es/Presup/PGE2013Ley/MaestroDocumentos/PGE-ROM/doc/HTM/N_13_E_V_1_101_1_1_2_2_118_1_2.HTM
# [2]: http://www.sepg.pap.minhap.gob.es/Presup/PGE2013Ley/MaestroDocumentos/PGE-ROM/doc/HTM/N_13_E_R_31_118_1_1_1_1333A_2.HTM
#
income = []
expenses = []
additional_institutions = []

Budget.new(budget_id, is_final).entity_breakdowns.each do |bkdown|
  expenses.concat bkdown.expenses
end
Budget.new(budget_id, is_final).programme_breakdowns.each do |bkdown|
  expenses.concat bkdown.expenses

  # Because of the way we're extracting Social Security budget (from programme breakdowns,
  # not entity ones), we don't get the list of organization subtotals in the main list, 
  # and these subtotals are the ones we use to recreate the insititutional hierarchy. 
  # So we have to go and explicitely search for them, and add them later on.
  # (Alternatively, we could get the whole insitutional hierarchy from programme
  # breakdowns, but I see no point in changing what's already working.)
  additional_institutions.concat bkdown.institutions
end

Budget.new(budget_id, is_final).income_breakdowns.each do |bkdown|
  income.concat bkdown.income

  additional_institutions.concat bkdown.institutions
end


#
# OUTPUT DATA SPREAD ACROSS A NUMBER OF FILES
#

# These policy ids and names don't change, at least since 2009
def get_default_policies_and_programmes
  {
    "0" => { description: "Transferencias internas" },
    "1" => { description: "Servicios públicos básicos" },
    "2" => { description: "Protección y promoción social" },
    "3" => { description: "Bienes públicos de carácter preferente" },
    "4" => { description: "Actuaciones de carácter económico" },
    "9" => { description: "Actuaciones de carácter general" },
    "00" => { description: "Transferencias internas" },
    "11" => { description: "Justicia" },
    "12" => { description: "Defensa" },
    "13" => { description: "Seguridad ciudadana e instituciones penitenciarias" },
    "14" => { description: "Política exterior" },
    "21" => { description: "Pensiones" },
    "22" => { description: "Otras prestaciones económicas" },
    "23" => { description: "Servicios sociales y promoción social" },
    "24" => { description: "Fomento del empleo" },
    "25" => { description: "Desempleo" },
    "26" => { description: "Acceso a la vivienda y fomento de la edificación" },
    "28" => { description: "Gestión y administración de Trabajo y Economía Social" },
    "29" => { description: "Gestión y administración de la Seguridad Social" },
    "31" => { description: "Sanidad" },
    "32" => { description: "Educación" },
    "33" => { description: "Cultura" },
    "41" => { description: "Agricultura, pesca y alimentación" },
    "42" => { description: "Industria y energía" },
    "43" => { description: "Comercio, turismo y PYMES" },
    "44" => { description: "Subvenciones al transporte" },
    "45" => { description: "Infraestructuras" },
    "46" => { description: "Investigación, desarrollo e innovación" },
    "49" => { description: "Otras actuaciones de carácter económico" },
    "91" => { description: "Alta dirección" },
    "92" => { description: "Servicios de carácter general" },
    "93" => { description: "Administración financiera y tributaria" },
    "94" => { description: "Transferencias a otras admones. públicas" },
    "95" => { description: "Deuda pública" }    
  }
end

# The entity id is now five digits: section(2)+service(3, zero filled)
def get_entity_id(section, service)
  return section if service.nil? or service.empty?
  section+service.rjust(3, '0')
end

# Capitalize (initial uppercase, rest lowercase) a string if it's all uppercase.
# That way we beautify the result a bit when needed, but don't lose any data
# for strings that already have valid mixed case.
def capitalize_description_if_needed(description)
  return description if description.match(/\p{Lower}/)  # Some lowercase in there, do nothing
  description = UnicodeUtils.downcase(description)  # There's no capitalize method!?
  description[0] = UnicodeUtils.upcase(description[0])
  description
end

# Collect categories first, then output, to avoid duplicated chapters and articles.
# Important note: descriptions are consistent across the PGE budgets for chapters (x)
# and articles (xx), but not headings (xxx), which vary _a lot_ across different programmes.
# So we are forced to do some gymnastics, and include the entity id (i.e. section plus
# department/service) in the category id.
# Note: I initially thought income headings were consistent, but they are not: see for
# example, [1][2]; code 398. They are _almost_ consistent, but nope. Then I thought 
# programme would be enough on the expense side. It's not. I thought section would be 
# enough on both sides... It is not. We need section and department/service.
# Note: I also thought that I could start tagging items once a conflict was detected,
# leaving the previous items with the original short code. Wrong. Because which item gets 
# the short code would depend on the particular data of each year's budget, and that
# did mess the descriptions on the web (code 753 in year 2011 is not the same as code
# 753 in year 2012). So, if there's a conflict _all_ items get tagged.
#
# [1]: http://www.sepg.pap.minhap.gob.es/Presup/PGE2014Proyecto/MaestroDocumentos/PGE-ROM/doc/HTM/N_14_A_R_2_105_1_2_160_1_104_1.HTM
# [2]: http://www.sepg.pap.minhap.gob.es/Presup/PGE2014Proyecto/MaestroDocumentos/PGE-ROM/doc/HTM/N_14_A_R_2_104_1_2_115_1_1302_1.HTM
#
def get_economic_categories_from_budget_items_list(items)
  def count_different_descriptions(items)
    items.map{|i| i[:description]}.uniq.count
  end

  # First, group items by economic concept
  buckets = {}
  items.each do |item|
    concept = item[:economic_concept]
    next if concept.nil? or concept.empty?
    next if concept.length > 4     # Budget item
    # Note: We don't need economic categories for budget items (concept length==5), they are 
    # just items belonging to a heading. At one point the obstacle to this was distinguishing 
    # heading subtotals from the items themselves in the output files, but we've sorted that 
    # out through a new 'budget item' column in the output (see below).

    buckets[concept] = [] if buckets[concept].nil? 
    buckets[concept].push item
  end

  # Then, for each bucket, decide whether we need to tag the economic concept
  categories = {}
  buckets.each do |concept, items|
    if count_different_descriptions(items) > 1  # We need to tag the concept
      # We expect this to happen only for headings
      if concept.length < 3
        puts "Warning: inconsistent descriptions for article or chapter #{concept}!"
      end

      # Create a category for each item, and modify the items to point to them
      items.each do |item|
        tagged_concept = "#{concept}/#{get_entity_id(item[:section], item[:service])}"
        item[:economic_concept] = tagged_concept
        categories[tagged_concept] = item[:description]
      end
    else
      categories[concept] = items.first[:description]  # Pick the first, they're all the same
    end
  end
  categories
end

expense_categories = get_economic_categories_from_budget_items_list(expenses)
income_categories = get_economic_categories_from_budget_items_list(income)
CSV.open(File.join(output_path, "estructura_economica.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO", "GASTO/INGRESO", "CAPITULO", "ARTICULO", "CONCEPTO", "SUBCONCEPTO", "DESCRIPCION CORTA", "DESCRIPCION LARGA"]
  expense_categories.sort.each do |concept, description|
    csv << [year, 
            "G",
            concept[0], 
            concept.length >= 2 ? concept[0..1] : nil,
            concept.length >= 3 ? concept : nil,
            nil,  # We don't use subheadings
            nil,  # Short description, not used
            capitalize_description_if_needed(description) ]
  end

  income_categories.sort.each do |concept, description|
    csv << [year, 
            "I",
            concept[0], 
            concept.length >= 2 ? concept[0..1] : nil,
            concept.length >= 3 ? concept : nil,
            nil,  # We don't use subheadings
            nil,  # Short description, not used
            capitalize_description_if_needed(description) ]
  end
end

# Collect programmes first, then output, to avoid duplicates
CSV.open(File.join(output_path, "estructura_funcional.csv"), "w", col_sep: ';') do |csv|
  programmes = get_default_policies_and_programmes
  expenses.each do |line|
    programme = line[:programme]
    next if programme.nil? or programme.empty?
    next unless line[:economic_concept].nil? or line[:economic_concept].empty?
    programmes[programme] = line
  end

  csv << ["EJERCICIO","GRUPO","FUNCION","SUBFUNCION","PROGRAMA","DESCRIPCION CORTA","DESCRIPCION LARGA"]
  programmes.sort.each do |programme, line|
    csv << [year,
            programme[0],
            programme.length >= 2 ? programme[0..1] : nil,
            programme.length >= 3 ? programme[0..2] : nil,
            programme.length >= 4 ? programme : nil,
            nil,  # Short description, not used
            line[:description] ]
  end
end

CSV.open(File.join(output_path, "estructura_organica.csv"), "w", col_sep: ';') do |csv|
  bodies = {}
  expenses.each do |line|
    next unless line[:programme].nil? or line[:programme].empty?
    bodies[get_entity_id(line[:section], line[:service])] = line
  end
  additional_institutions.each do |line|
    entity_id = get_entity_id(line[:section], line[:service])
    if !bodies[entity_id].nil? and bodies[entity_id][:description] != line[:description]
      puts "Warning: different descriptions for institution #{entity_id}: had #{bodies[entity_id][:description]}, now got #{line[:description]}"
    end
    bodies[entity_id] = line
  end

  csv << ["EJERCICIO","CENTRO GESTOR","DESCRIPCION CORTA","DESCRIPCION LARGA"]
  bodies.sort.each do |body_id, line|
    csv << [year,
            body_id,
            nil,  # Short description, not used
            # The data is all uppercase; title case looks better
            UnicodeUtils.titlecase(line[:description])]
  end
end

def gather_budget_items(lines)
  budget_items = []
  lines.each do |line|
    next if line[:economic_concept].nil? or line[:economic_concept].empty?
    line[:body_id] = get_entity_id(line[:section], line[:service])  # Convenient
    budget_items.push line
  end
  budget_items
end

def break_down_economic_code(line, economic_categories)
    concept = line[:economic_concept]
    item_number = nil

    # Pick the first 3 digits of the economic concept (i.e. ignore the last two digits of a
    # subheading=budget item), unless it's a tagged heading, in which case we need the full code.
    # Note that a five-digit economic code (xxxxx) is actually a budget item belonging to a
    # heading (xxx or xxx/sssss). We don't discard the last two digits in the output file, we
    # put them in the 'item number' column as it's useful (basically) to distinguish the items 
    # from the heading subtotal.
    if concept.include?('/') 
      # We have a heading, a tagged one; nothing to do

    else
      if concept.length == 5 # We have a budget item
        item_number = concept[3..4]
        concept = concept[0..2]

        # We may have been forced to tag the parent economic code to work around inconsitencies.
        # Find out, and if so, use the tagged economic code instead.
        extended_concept = "#{concept}/#{get_entity_id(line[:section], line[:service])}"   
        concept = extended_concept if !economic_categories[extended_concept].nil?

      else
        concept = concept[0..2]

      end
    end

    [concept, item_number]
end

CSV.open(File.join(output_path, "gastos.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO","CENTRO GESTOR","FUNCIONAL","ECONOMICA","FINANCIACION","ITEM","DESCRIPCION","IMPORTE"]
  gather_budget_items(expenses).sort do |a,b| 
    [a[:programme], a[:body_id], a[:economic_concept]] <=> [b[:programme], b[:body_id], b[:economic_concept]]
  end.each do |expense|
    concept, item_number = break_down_economic_code(expense, expense_categories)
    csv << [year, 
            expense[:body_id],
            expense[:programme], 
            concept, 
            nil, 
            item_number,
            expense[:description],
            Budget.convert_number(expense[:amount]) ]
  end
end

CSV.open(File.join(output_path, "ingresos.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO","CENTRO GESTOR","ECONOMICA","FINANCIACION","ITEM","DESCRIPCION","IMPORTE"]
  gather_budget_items(income).sort do |a,b| 
    [a[:economic_concept], a[:body_id]] <=> [b[:economic_concept], b[:body_id]]
  end.each do |item|
    concept, item_number = break_down_economic_code(item, income_categories)
    csv << [year, 
            item[:body_id],
            concept, 
            nil, 
            item_number,
            item[:description],
            Budget.convert_number(item[:amount]) ]
  end
end

