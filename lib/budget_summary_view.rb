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

  def ingresos_estado; summary_line(@income, :estado) end
  def ingresos_ooaa; summary_line(@income, :ooaa) end
  def ingresos_agencias; summary_line(@income, :agencias) end
  def ingresos_otros; summary_line(@income, :otros) end
  def ingresos_seg_social; summary_line(@income, :seg_social) end
  def ingresos_transferencias; transfer_line(@income) end
  def ingresos_consolidado; total_line(@income) end

  def gastos_estado; summary_line(@expenses, :estado) end
  def gastos_ooaa; summary_line(@expenses, :ooaa) end
  def gastos_agencias; summary_line(@expenses, :agencias) end
  def gastos_otros; summary_line(@expenses, :otros) end
  def gastos_seg_social; summary_line(@expenses, :seg_social) end
  def gastos_transferencias; transfer_line(@expenses) end
  def gastos_consolidado; total_line(@expenses) end

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

  # Performs a series of tests comparing our aggregated figures with the summary
  # ones published as part of the official budget. Automated testing for budget parsing!
  #
  # Note: I considered using as valid the global summaries published in the Yellow series [1].
  # But they are NOT correct. That's correct: some of the summaries included in the budget
  # are incorrect! Just compare f.ex. the total expense for 'other bodies' in [1] with the 
  # corresponding detailed breakdown at [2]. The sums in [1] are being done using ROUNDED
  # numbers, and the totals never corrected, so they are WRONG!
  #
  # [1]: http://www.sepg.pap.minhap.gob.es/Presup/PGE2014proyecto/MaestroDocumentos/PGE-ROM/N_14_A_A_3.htm
  # [2]: http://www.sepg.pap.minhap.gob.es/Presup/PGE2014proyecto/MaestroDocumentos/PGE-ROM/doc/HTM/N_14_A_R_6_1_102_1_4_1.HTM
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

  def summary_line(breakdown, type)
    "#{beautify sum(breakdown[type], 7)}|" \
    "#{beautify sum(breakdown[type], 8)}|" \
    "#{beautify sum(breakdown[type], 9)}|" \
    "#{beautify( sum(breakdown[type], 9)+(breakdown[type][:transferencias]||0) )}"
  end

  def transfer_line(breakdown)
    total_transfers = beautify(breakdown[:consolidado][:transferencias])
    "#{total_transfers}|#{total_transfers}|#{total_transfers}|" 
  end

  def total_line(breakdown)
    "**#{beautify sum(breakdown[:consolidado], 7)}**|" \
    "**#{beautify sum(breakdown[:consolidado], 8)}**|" \
    "**#{beautify sum(breakdown[:consolidado], 9)}**|" \
    "**#{beautify sum(breakdown[:consolidado], 9)}**"
  end

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

    # Does the official budget summary substract the internal transfers at the end, after
    # adding up gross figures for the different chapters? Or does it add net figures, and 
    # add the transfers at the end to get the overall gross figure. Well, it depends on the 
    # year of the budget! Oh yeah!
    add_gross_figures = ['2014'].include? @year
    if add_gross_figures
      gross_total_name = "TOTAL PRESUPUESTO"
    else
      gross_total_name = "TOTAL"
    end

    expenses = @budget.generic_breakdown(@year, breakdown_id)
    # We know that all transfers sit in chapters <= 7, so we just use the total everywhere
    transfers = @expenses[entity_id][:transferencias]||0
    url = expenses.get_url()
    checks << check_equal("Gastos #{entity_description} - operaciones no financieros", 
                          get_official_value(expenses, "TOTAL OPERACIONES NO FINANCIERAS"),
                          beautify(sum(@expenses[entity_id], 7) + (add_gross_figures ? 0 : transfers)),
                          url )
    checks << check_equal("Gastos #{entity_description} - capítulos I-VIII", 
                          get_official_value(expenses, "TOTAL Capítulos 1-8"),
                          beautify(sum(@expenses[entity_id], 8) + (add_gross_figures ? 0 : transfers)),
                          url ) unless entity_id==:otros
    checks << check_equal("Gastos #{entity_description} - presupuesto total", 
                          get_official_value(expenses, gross_total_name),
                          beautify(sum(@expenses[entity_id], 9)),
                          url )

    if transfers != 0 or ['2014'].include? @year # snif
      checks << check_equal("Gastos #{entity_description} - presupuesto consolidado", 
                            get_official_value(expenses, "TOTAL CONSOLIDADO"),
                            beautify(sum(@expenses[entity_id], 9)+transfers),
                            url )
    else
      # If there are no internal transfers we check the consolidated figure
      # in the official documentation is missing
      checks << check_equal("Gastos #{entity_description} - presupuesto consolidado", 
                            get_official_value(expenses, "TOTAL CONSOLIDADO"),
                            '',
                            url )
    end

    checks
  end

  # Compared to the expense checks:
  #  - the sum of chapters I-VIII is not there, so we can't test it
  #  - we don't have consolidated figures, i.e. without internal transfers
  def check_income(breakdown_id, entity_description, entity_id)
    checks = []

    income = @budget.generic_breakdown(@year, breakdown_id)
    url = income.get_url()
    checks << check_equal("Ingresos #{entity_description} - operaciones no financieros", 
                          get_official_value(income, "TOTAL OPERACIONES NO FINANCIERAS"),
                          beautify(sum(@income[entity_id], 7)),
                          url )
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
