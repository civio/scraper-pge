# Class containing the summary data for the Mustache template

require 'mustache'

class BudgetSummaryView < Mustache
  def initialize(budget, year)
    @budget = budget
    @year = year
    @income = {
      estado: {},
      ooaa: {},
      agencias: {},
      otros: {},
      seg_social: {},
      consolidado: {}
    }
    @expenses = {
      estado: {},
      ooaa: {},
      agencias: {},
      otros: {},
      seg_social: {},
      consolidado: {}
    }
  end

  def year; @year end

  def ingresos(type)
    "#{beautify sum(@income[type], 7)}|" \
    "#{beautify sum(@income[type], 8)}|" \
    "#{beautify sum(@income[type], 9)}|" \
    "#{beautify( sum(@income[type], 9)+@income[type][:transferencias] )}"
  end
  def ingresos_estado; ingresos(:estado) end
  def ingresos_ooaa; ingresos(:ooaa) end
  def ingresos_agencias; ingresos(:agencias) end
  def ingresos_otros; ingresos(:otros) end
  def ingresos_seg_social; ingresos(:seg_social) end
  def ingresos_consolidado; ingresos(:consolidado) end
  def ingresos_transferencias
    total_transfers = beautify(@income[:consolidado][:transferencias])
    "#{total_transfers}|#{total_transfers}|#{total_transfers}|" 
  end

  def gastos(type)
    "#{beautify sum(@expenses[type], 7)}|" \
    "#{beautify sum(@expenses[type], 8)}|" \
    "#{beautify sum(@expenses[type], 9)}|" \
    "#{beautify( sum(@expenses[type], 9)+(@expenses[type][:transferencias]||0) )}"
  end
  def gastos_estado; gastos(:estado) end
  def gastos_ooaa; gastos(:ooaa) end
  def gastos_agencias; gastos(:agencias) end
  def gastos_otros; gastos(:otros) end
  def gastos_seg_social; gastos(:seg_social) end
  def gastos_consolidado; gastos(:consolidado) end
  def gastos_transferencias
    total_transfers = beautify(@expenses[:consolidado][:transferencias])
    "#{total_transfers}|#{total_transfers}|#{total_transfers}|" 
  end

  def add_item(item)
    # Extract basic details
    is_income = (item.size == 7)
    root_breakdown = is_income ? @income : @expenses
    concept = item[is_income ? 2 : 3]
    entity = item[1]
    section = entity[0..1]
    amount = item[is_income ? 6 : 7].to_i

    # Find out which sector the item belongs to
    if section == '60'
      category = :seg_social
    else
      case entity[2]
      when '1', '2'
        category = :ooaa
      when '3'
        category = :otros
      when '4'
        category = :agencias
      else  # 0
        category = :estado
      end
    end
    breakdown = root_breakdown[category]

    # Add it up
    if concept.length == 1  # We add only chapters, i.e. top-level concepts
      breakdown[concept] = (breakdown[concept]||0) + amount
      root_breakdown[:consolidado][concept] = (root_breakdown[:consolidado][concept]||0) + amount
    end

    # Is it an internal transfer?
    if is_income
      is_internal_transfer = (concept.length == 2 and ['40', '41', '42', '43', '70', '71', '72', '73'].include? concept)
    else
      is_internal_transfer = (concept.length == 1 and item[2] == '000X')
    end
    if is_internal_transfer
      chapter = concept[0]
      breakdown[:transferencias] = (breakdown[:transferencias]||0) - amount
      root_breakdown[:consolidado][chapter] = (root_breakdown[:consolidado][chapter]||0) - amount
      root_breakdown[:consolidado][:transferencias] = (root_breakdown[:consolidado][:transferencias]||0) - amount
    end
  end

  def check_budget
    checks = []

    # Internal consistency
    checks << check_equal("Transferencias internas ingresos = gastos", 
                          beautify(@income[:consolidado][:transferencias]),
                          beautify(@expenses[:consolidado][:transferencias]) )

    # Expenses
    checks.concat check_expenses('R_6_2_801_1_3', "Estado", :estado)
    checks.concat check_expenses('R_6_2_802_1_3', "Organismos Autónomos", :ooaa)
    checks.concat check_expenses('R_6_2_803_1_3', "Agencias estatales", :agencias)
    checks.concat check_expenses('R_6_2_804_1_3', "Otros organismos", :otros)
    checks.concat check_expenses('R_6_2_805_1_3', "Seguridad Social", :seg_social)

    # Income
    checks.concat check_income('R_6_1_101_1_5_1', "Estado", :estado)
    checks.concat check_income('R_6_1_102_1_4_1', "Organismos Autónomos", :ooaa)
    checks.concat check_income('R_6_1_103_1_4_1', "Agencias estatales", :agencias)
    checks.concat check_income('R_6_1_104_1_4_1', "Otros organismos", :otros)
    checks.concat check_income('R_6_1_105_1_5_1', "Seguridad Social", :seg_social)

    # Return results
    checks.join("\n")
  end

  private
  
  def sum(breakdown, limit)
    (1..limit).inject(0) {|sum, chapter| sum + (breakdown[chapter.to_s]||0) }
  end

  def get_official_value(breakdown, description)
    beautify(Budget.convert_number(breakdown.get_value_by_description(description)))
  end

  def beautify(i)
    # See http://stackoverflow.com/questions/6458990/how-to-format-a-number-1000-as-1-000
    i.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
  end

  # Convenience
  def check_expenses(breakdown_id, entity_description, entity_id)
    checks = []

    expenses = @budget.generic_breakdown(@year, breakdown_id)
    url = expenses.get_url()
    checks << check_equal("Gastos #{entity_description} - operaciones no financieros", 
                          get_official_value(expenses, "TOTAL OPERACIONES NO FINANCIERAS"),
                          beautify(sum(@expenses[entity_id], 7)),
                          url )
    checks << check_equal("Gastos #{entity_description} - capítulos I-VIII", 
                          get_official_value(expenses, "TOTAL Capítulos 1-8"),
                          beautify(sum(@expenses[entity_id], 8)),
                          url ) unless entity_id==:otros
    checks << check_equal("Gastos #{entity_description} - presupuesto total", 
                          get_official_value(expenses, "TOTAL PRESUPUESTO"),
                          beautify(sum(@expenses[entity_id], 9)),
                          url )

    checks
  end

  def check_income(breakdown_id, entity_description, entity_id)
    checks = []

    income = @budget.generic_breakdown(@year, breakdown_id)
    url = income.get_url()
    checks << check_equal("Ingresos #{entity_description} - operaciones no financieros", 
                          get_official_value(income, "TOTAL OPERACIONES NO FINANCIERAS"),
                          beautify(sum(@income[entity_id], 7)),
                          url )
    # the sum of chapters I-VIII is not there, so ignore that
    checks << check_equal("Ingresos #{entity_description} - presupuesto total", 
                          get_official_value(income, "TOTAL"),
                          beautify(sum(@income[entity_id], 9)),
                          url )

    checks
  end

  # Poor man's unit test... for budgets
  def check_equal(message, a, b, source=nil)
    if a==b
      output = " * #{message}: OK (#{a})"
    else
      output = " * **#{message}: ERROR #{a} != #{b}**"
    end
    output = output + "   [fuente](#{source})" unless source.nil?
    output
  end
end
