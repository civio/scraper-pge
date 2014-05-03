#!/usr/bin/env ruby

# Generate a summary with the key figures of a budget, in Markdown, so it can be
# explored more easily in Github, f.ex.

require 'csv'
require 'mustache'

require_relative 'lib/budget_summary_view'

# XXX: This command line stuff is duplicated in the parser, should clean up
budget_id = ARGV[0]
year = budget_id[0..3]  # Sometimes there's a P for 'Proposed' at the end. Ignore that bit
output_path = File.join(".", "output", budget_id)


# Do the calculations
summary = BudgetSummaryView.new(year)
CSV.foreach(File.join(output_path, "ingresos.csv"), col_sep: ';') do |row|
  summary.add_item row
end

# Inline template
template = <<TEMPLATE
##Presupuesto {{year}}

###Ingresos

 | No Financieros (I-VII) | Total (I-IX)
:--|---------------------:|-------------:
Estado|{{estado_1_7}}|{{estado_1_9}}
Organismos autónomos|{{ooaa_1_7}}|{{ooaa_1_9}}
Agencias estatales|{{agencias_1_7}}|{{agencias_1_9}}
Otros organismos|{{otros_1_7}}|{{otros_1_9}}
Seguridad Social|{{seg_social_1_7}}|{{seg_social_1_9}}
(- transferencias internas)|{{transferencias_1_7}}|{{transferencias_1_9}}
**TOTAL**|{{consolidado_1_7}}|{{consolidado_1_9}}

###Gastos

Total: X
TEMPLATE

# Render the output file
summary_filename = File.join(output_path, "README.md")
File.open(summary_filename, 'w') do |file|
  file.write Mustache.render(template, summary)
end
