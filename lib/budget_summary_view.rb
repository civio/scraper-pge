# Class containing the summary data for the Mustache template

require 'mustache'

class BudgetSummaryView < Mustache
  def initialize(year)
    @year = year
    @summary = {
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

  def estado_1_7; beautify sum(@summary[:estado], 7) end
  def estado_1_9; beautify sum(@summary[:estado], 9) end

  def ooaa_1_7; beautify sum(@summary[:ooaa], 7) end
  def ooaa_1_9; beautify sum(@summary[:ooaa], 9) end

  def agencias_1_7; beautify sum(@summary[:agencias], 7) end
  def agencias_1_9; beautify sum(@summary[:agencias], 9) end

  def otros_1_7; beautify sum(@summary[:otros], 7) end
  def otros_1_9; beautify sum(@summary[:otros], 9) end

  def seg_social_1_7; beautify sum(@summary[:seg_social], 7) end
  def seg_social_1_9; beautify sum(@summary[:seg_social], 9) end

  def transferencias_1_7; beautify sum(@summary[:transferencias], 7) end
  def transferencias_1_9; beautify sum(@summary[:transferencias], 9) end

  def consolidado_1_7; beautify sum(@summary[:consolidado], 7) end
  def consolidado_1_9; beautify sum(@summary[:consolidado], 9) end

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
    concept = item[is_income ? 2 : 3]
    entity = item[1]
    section = entity[0..1]
    amount = item[is_income ? 6 : 7].to_i

    # Find out which sector the item belongs to
    if section == '60'
      breakdown = @summary[:seg_social]
    else
      case entity[2]
      when '1', '2'
        breakdown = @summary[:ooaa]
      when '3'
        breakdown = @summary[:otros]
      when '4'
        breakdown = @summary[:agencias]
      else  # 0
        breakdown = @summary[:estado]
      end
    end

    # Add it up
    if concept.length == 1  # We add only chapters, i.e. top-level concepts
      breakdown[concept] = (breakdown[concept]||0) + amount
      @summary[:consolidado][concept] = (@summary[:consolidado][concept]||0) + amount
    end

    # Is it an internal transfer?
    if concept.length == 2 and ['40', '41', '42', '43', '70', '71', '72', '73'].include? concept
      chapter = concept[0]
      @summary[:transferencias][chapter] = (@summary[:transferencias][chapter]||0) - amount
      @summary[:consolidado][chapter] = (@summary[:consolidado][chapter]||0) - amount
    end
  end
end
