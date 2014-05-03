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

  def ingresos_estado_1_7; beautify sum(@income[:estado], 7) end
  def ingresos_estado_1_9; beautify sum(@income[:estado], 9) end
  def ingresos_ooaa_1_7; beautify sum(@income[:ooaa], 7) end
  def ingresos_ooaa_1_9; beautify sum(@income[:ooaa], 9) end
  def ingresos_agencias_1_7; beautify sum(@income[:agencias], 7) end
  def ingresos_agencias_1_9; beautify sum(@income[:agencias], 9) end
  def ingresos_otros_1_7; beautify sum(@income[:otros], 7) end
  def ingresos_otros_1_9; beautify sum(@income[:otros], 9) end
  def ingresos_seg_social_1_7; beautify sum(@income[:seg_social], 7) end
  def ingresos_seg_social_1_9; beautify sum(@income[:seg_social], 9) end
  def ingresos_transferencias_1_7; beautify sum(@income[:transferencias], 7) end
  def ingresos_transferencias_1_9; beautify sum(@income[:transferencias], 9) end
  def ingresos_consolidado_1_7; beautify sum(@income[:consolidado], 7) end
  def ingresos_consolidado_1_9; beautify sum(@income[:consolidado], 9) end

  def gastos_estado_1_7; beautify sum(@expenses[:estado], 7) end
  def gastos_estado_1_9; beautify sum(@expenses[:estado], 9) end
  def gastos_ooaa_1_7; beautify sum(@expenses[:ooaa], 7) end
  def gastos_ooaa_1_9; beautify sum(@expenses[:ooaa], 9) end
  def gastos_agencias_1_7; beautify sum(@expenses[:agencias], 7) end
  def gastos_agencias_1_9; beautify sum(@expenses[:agencias], 9) end
  def gastos_otros_1_7; beautify sum(@expenses[:otros], 7) end
  def gastos_otros_1_9; beautify sum(@expenses[:otros], 9) end
  def gastos_seg_social_1_7; beautify sum(@expenses[:seg_social], 7) end
  def gastos_seg_social_1_9; beautify sum(@expenses[:seg_social], 9) end
  def gastos_transferencias_1_7; beautify sum(@expenses[:transferencias], 7) end
  def gastos_transferencias_1_9; beautify sum(@expenses[:transferencias], 9) end
  def gastos_consolidado_1_7; beautify sum(@expenses[:consolidado], 7) end
  def gastos_consolidado_1_9; beautify sum(@expenses[:consolidado], 9) end

  def sum(breakdown, limit)
    (1..limit).inject(0) {|sum, chapter| sum + (breakdown[chapter.to_s]||0) }
  end

  def beautify(i)
    # See http://stackoverflow.com/questions/6458990/how-to-format-a-number-1000-as-1-000
    i.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
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
end
