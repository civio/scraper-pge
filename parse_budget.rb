#!/usr/bin/env ruby

require 'csv'
require 'bigdecimal'

require_relative 'lib/budget'

year = ARGV[0]
output_path = File.join(".", "output", year)


# Retrieve expenses
# Budget expenses are organized in chapters > articles > concepts > subconcepts. When looking at 
# an expense breakdown, the sum of all the chapters (codes of the form 'n') equals the sum of all 
# articles (codes 'nn') and the sum of all expenses (codes 'nnn'). I.e. the breakdown is exhaustive 
# down to that level. Note however that not all concepts are broken into sub-concepts (codes 'nnnnn'); 
# hence, adding up all the subconcepts will result in a much smaller amount.

def add_line(lines, line, amount)
  lines.push( line.merge({amount: amount}) )
end

def extract_lines(lines, bkdown, open_headings)
  bkdown.expenses.each do |row|
    partial_line = {
      year: bkdown.year,
      section: bkdown.section,
      entity_type: bkdown.entity_type,
      service: row[:service],
      programme: row[:programme],
      economic_concept: row[:expense_concept],
      description: row[:description]
    }
  
    # The total amounts for service/programme/chapter headings is shown when the heading is closed,
    # not opened, so we need to keep track of the open ones, and print them when closed.
    # TODO: All this may not be needed if we just throw away the chapter-level subtotals, I think
    # (Hmm, but we use that for the other categories, right?)
    if ( row[:amount].empty? )              # opening heading
      open_headings << partial_line
    elsif ( row[:expense_concept].empty? )  # closing heading
      last_heading = open_headings.pop()
      add_line(lines, last_heading, row[:amount]) unless last_heading.nil?
    else                                    # standard data row
      add_line(lines, partial_line, row[:amount])
    end
  end
end

lines = []
Budget.new(year).entity_breakdowns.each do |bkdown|
  # Note: there is an unmatched closing amount, without an opening heading, at the end
  # of the page, containing the amount for the whole section/entity, so we don't start with
  # an empty vector here, we add the 'missing' opening line
  open_headings = [{
    year: bkdown.year,
    section: bkdown.section,
    entity_type: bkdown.entity_type,
    service: bkdown.is_state_entity? ? '' : bkdown.entity,
    description: bkdown.name
  }]
  extract_lines(lines, bkdown, open_headings)
end


# Output data spread across a number of files

# Reads a number in spanish notation. Also note input number is in thousands of euros.
def convert_number(amount)
  BigDecimal.new( amount.delete('.').tr(',','.') ) * 1000
end

def output_default_policies(csv, year)
  policies = [["11", "JUSTICIA"],
              ["12", "DEFENSA"],
              ["13", "SEGURIDAD CIUDADANA E INSTITUCIONES PENITENCIARIAS"],
              ["14", "POLÍTICA EXTERIOR"],
              ["21", "PENSIONES"],
              ["22", "OTRAS PRESTACIONES ECONÓMICAS"],
              ["23", "SERVICIOS SOCIALES Y PROMOCIÓN SOCIAL"],
              ["24", "FOMENTO DEL EMPLEO"],
              ["25", "DESEMPLEO"],
              ["26", "ACCESO A LA VIVIENDA Y FOMENTO DE LA EDIFICACIÓN"],
              ["29", "GESTIÓN Y ADMINISTRACIÓN DE LA SEGURIDAD SOCIAL"],
              ["31", "SANIDAD"],
              ["32", "EDUCACIÓN"],
              ["33", "CULTURA"],
              ["41", "AGRICULTURA, PESCA Y ALIMENTACIÓN"],
              ["42", "INDUSTRIA Y ENERGIA"],
              ["43", "COMERCIO, TURISMO Y PYMES"],
              ["44", "SUBVENCIONES AL TRANSPORTE"],
              ["45", "INFRAESTRUCTURAS"],
              ["46", "INVESTIGACIÓN, DESARROLLO E INNOVACIÓN"],
              ["49", "OTRAS ACTUACIONES DE CARÁCTER ECONÓMICO"],
              ["91", "ALTA DIRECCIÓN"],
              ["92", "SERVICIOS DE CARÁCTER GENERAL"],
              ["93", "ADMINISTRACIÓN FINANCIERA Y TRIBUTARIA"],
              ["94", "TRANSFERENCIAS A OTRAS ADMONES. PÚBLICAS"],
              ["95", "DEUDA PÚBLICA"] ]
  policies.each do |policy|
    policy_id = policy[0]
    description = policy[1]
    csv << [year,
            policy_id[0],
            policy_id,
            nil,
            nil,
            nil,  # Short description, not used
            description ]
  end
end

# The entity id is now five digits: section(2)+service(3, zero filled)
# TODO: There's no need for the entity type, since the ids are already distinct. So remove
def get_entity_id(section, service)
  return section if service.nil? or service.empty?
  section+service.rjust(3, '0')
end

CSV.open(File.join(output_path, "estructura_economica.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO", "GASTO/INGRESO", "CAPITULO", "ARTICULO", "CONCEPTO", "SUBCONCEPTO", "DESCRIPCION CORTA", "DESCRIPCION LARGA"]
  lines.each do |line|
    next if line[:economic_concept].nil? or line[:economic_concept].empty?
    next if line[:economic_concept].length > 2  # FIXME
    concept = line[:economic_concept]
    csv << [year, 
            "G",
            concept[0], 
            concept.length >= 2 ? concept[0..1] : nil,
            nil,  # FIXME
            nil,  # FIXME
            nil,  # Short description, not used
            line[:description] ]
  end
end

CSV.open(File.join(output_path, "estructura_financiacion.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO", "GASTO/INGRESO", "ORIGEN", "FONDO", "FINANCIACION", "DESCRIPCION CORTA", "DESCRIPCION LARGA"]
  csv << [year, "G", "X", "XX", "XXX", "Gastos", ""]
end

# FIXME: This generates duplicates. Not 100% that's ok
CSV.open(File.join(output_path, "estructura_funcional.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO","GRUPO","FUNCION","SUBFUNCION","PROGRAMA","DESCRIPCION CORTA","DESCRIPCION LARGA"]
  output_default_policies(csv, year)
  lines.each do |line|
    next if line[:programme].nil? or line[:programme].empty?
    next unless line[:economic_concept].nil? or line[:economic_concept].empty?
    programme = line[:programme]
    csv << [year,
            programme[0],
            programme[0..1],
            programme[0..2],
            programme,
            nil,  # Short description, not used
            line[:description] ]
  end
end

CSV.open(File.join(output_path, "estructura_organica.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO","CENTRO GESTOR","DESCRIPCION CORTA","DESCRIPCION LARGA"]
  lines.each do |line|
    next unless line[:programme].nil? or line[:programme].empty?
    csv << [year,
            get_entity_id(line[:section], line[:service]),
            nil,  # Short description, not used
            line[:description]]
  end
end

CSV.open(File.join(output_path, "gastos.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO","CENTRO GESTOR","FUNCIONAL","ECONOMICA","FINANCIACION","DESCRIPCION","IMPORTE"]
  lines.each do |line|
    next if line[:economic_concept].nil? or line[:economic_concept].empty?
    next if line[:economic_concept].length != 2  # FIXME
    csv << [year, 
            get_entity_id(line[:section], line[:service]),
            line[:programme], 
            line[:economic_concept], 
            'XXX', 
            line[:description],
            convert_number(line[:amount]).to_int ]
  end
end

CSV.open(File.join(output_path, "ingresos.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO","CENTRO GESTOR","ECONOMICA","FINANCIACION","DESCRIPCION","IMPORTE"]
end

