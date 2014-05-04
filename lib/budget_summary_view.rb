# Class containing the summary data for the Mustache template

require 'mustache'

class BudgetSummaryView < Mustache
  def initialize(year)
    @year = year
    @income = {
      estado: {},
      ooaa: {},
      agencias: {},
      otros: {},
      seg_social: {},
      transferencias: {},
      consolidado: {}
    }
    @expenses = {
      estado: {},
      ooaa: {},
      agencias: {},
      otros: {},
      seg_social: {},
      transferencias: {},
      consolidado: {}
    }
  end

  def year; @year end

  def ingresos(type)
    "#{beautify sum(@income[type], 7)}|#{beautify sum(@income[type], 8)}|#{beautify sum(@income[type], 9)}"
  end
  def ingresos_estado; ingresos(:estado) end
  def ingresos_ooaa; ingresos(:ooaa) end
  def ingresos_agencias; ingresos(:agencias) end
  def ingresos_otros; ingresos(:otros) end
  def ingresos_seg_social; ingresos(:seg_social) end
  def ingresos_transferencias; ingresos(:transferencias) end
  def ingresos_consolidado; ingresos(:consolidado) end

  def gastos(type)
    "#{beautify sum(@expenses[type], 7)}|#{beautify sum(@expenses[type], 8)}|#{beautify sum(@expenses[type], 9)}"
  end
  def gastos_estado; gastos(:estado) end
  def gastos_ooaa; gastos(:ooaa) end
  def gastos_agencias; gastos(:agencias) end
  def gastos_otros; gastos(:otros) end
  def gastos_seg_social; gastos(:seg_social) end
  def gastos_transferencias; gastos(:transferencias) end
  def gastos_consolidado; gastos(:consolidado) end

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
      breakdown = root_breakdown[:seg_social]
    else
      case entity[2]
      when '1', '2'
        breakdown = root_breakdown[:ooaa]
      when '3'
        breakdown = root_breakdown[:otros]
      when '4'
        breakdown = root_breakdown[:agencias]
      else  # 0
        breakdown = root_breakdown[:estado]
      end
    end

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
      root_breakdown[:transferencias][chapter] = (root_breakdown[:transferencias][chapter]||0) - amount
      root_breakdown[:consolidado][chapter] = (root_breakdown[:consolidado][chapter]||0) - amount
    end
  end

  def check_budget
    checks = []
    checks << check_equal("Transferencias internas ingresos = gastos", 
                          beautify(sum(@income[:transferencias], 9)),
                          beautify(sum(@expenses[:transferencias], 9)) )
    checks.join('\n')
  end

  private
  
  def sum(breakdown, limit)
    (1..limit).inject(0) {|sum, chapter| sum + (breakdown[chapter.to_s]||0) }
  end

  def beautify(i)
    # See http://stackoverflow.com/questions/6458990/how-to-format-a-number-1000-as-1-000
    i.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
  end

  # Poor man's unit test... for budgets
  def check_equal(message, a, b)
    if a==b
      " * #{message}: OK"
    else
      " * #{message}: ERROR #{a} != #{b}"
    end
  end
end
