#!/usr/bin/env ruby

# Generate a summary with the key figures of a budget, in Markdown, so it can be
# explored more easily in Github, f.ex.

require 'csv'
require 'mustache'

# XXX: This command line stuff is duplicated in the parser, should clean up
budget_id = ARGV[0]
year = budget_id[0..3]  # Sometimes there's a P for 'Proposed' at the end. Ignore that bit
output_path = File.join(".", "output", budget_id)

# Class containing the summary data
class BudgetSummary < Mustache
  def initialize(year)
    @year = year
    @summary = {
      estado: {},
      ooaa: {},
      agencias: {},
      otros: {},
      seg_social: {}
    }
  end

  def year; @year end

  def estado_1_7; beautify sum(@summary[:estado], 7) end
  def estado_1_9; beautify sum(@summary[:estado], 9) end
  def estado_transfer; 0 end
  def estado_total; beautify (sum(@summary[:estado], 9)-estado_transfer) end

  def sum(breakdown, limit)
    (1..limit).inject(0) {|sum, chapter| sum + breakdown[chapter.to_s] }
  end

  def beautify(i)
    i.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
  end

  def add_item(item)
    is_income = (item.size == 7)
    concept = item[is_income ? 2 : 3]
    entity = item[1]
    amount = item[is_income ? 6 : 7].to_i

    return if concept.length > 1  # We need only top-level chapters
    @summary[:estado][concept] = (@summary[:estado][concept]||0) + amount
  end
end

# Do the calculations
summary = BudgetSummary.new(year)
CSV.foreach(File.join(output_path, "ingresos.csv"), col_sep: ';') do |row|
  summary.add_item row
end

# Inline template
template = <<TEMPLATE
##Presupuesto {{year}}

###Ingresos

 | No Financieros (I-VII) | Total (I-IX) | Transferencias | Total Consolidado
:--|---------------------:|-------------:|---------------:|-----------------:
Estado|{{estado_1_7}}|{{estado_1_9}}|{{estado_transfer}}|{{estado_total}}
Organismos autónomos|{{ooaa_1_7}}|{{ooaa_1_9}}|{{ooaa_transfer}}|{{ooaa_total}}
Agencias estatales|{{agencias_1_7}}|{{agencias_1_9}}|{{agencias_transfer}}|{{agencias_total}}
Otros organismos|{{otros_1_7}}|{{otros_1_9}}|{{otros_transfer}}|{{otros_total}}
Seguridad Social|{{seg_social_1_7}}|{{seg_social_1_9}}|{{seg_social_transfer}}|{{seg_social_total}}

###Gastos

Total: X
TEMPLATE

# Render the output file
summary_filename = File.join(output_path, "README.md")
File.open(summary_filename, 'w') do |file|
  file.write Mustache.render(template, summary)
end
