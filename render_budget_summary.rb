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
CSV.foreach(File.join(output_path, "gastos.csv"), col_sep: ';') do |row|
  summary.add_item row
end

# Inline template
template = <<TEMPLATE
##Presupuesto {{year}}

###Ingresos

 | No Financieros (I-VII) | I-VIII | Total (I-IX)
:--|---------------------:|-------:|-------------:
Estado|{{ingresos_estado}}
Organismos autónomos|{{ingresos_ooaa}}
Agencias estatales|{{ingresos_agencias}}
Otros organismos|{{ingresos_otros}}
Seguridad Social|{{ingresos_seg_social}}
(- transferencias internas)|{{ingresos_transferencias}}
**TOTAL**|{{ingresos_consolidado}}

###Gastos

 | No Financieros (I-VII) | I-VIII | Total (I-IX)
:--|---------------------:|-------:|-------------:
Estado|{{gastos_estado}}
Organismos autónomos|{{gastos_ooaa}}
Agencias estatales|{{gastos_agencias}}
Otros organismos|{{gastos_otros}}
Seguridad Social|{{gastos_seg_social}}
(- transferencias internas)|{{gastos_transferencias}}
**TOTAL**|{{gastos_consolidado}}

###Comprobaciones

{{{check_budget}}}
TEMPLATE

# Render the output file
summary_filename = File.join(output_path, "README.md")
File.open(summary_filename, 'w') do |file|
  file.write Mustache.render(template, summary)
end
