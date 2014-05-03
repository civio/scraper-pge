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

 | No Financieros (I-VII) | Total (I-IX)
:--|---------------------:|-------------:
Estado|{{ingresos_estado_1_7}}|{{ingresos_estado_1_9}}
Organismos autónomos|{{ingresos_ooaa_1_7}}|{{ingresos_ooaa_1_9}}
Agencias estatales|{{ingresos_agencias_1_7}}|{{ingresos_agencias_1_9}}
Otros organismos|{{ingresos_otros_1_7}}|{{ingresos_otros_1_9}}
Seguridad Social|{{ingresos_seg_social_1_7}}|{{ingresos_seg_social_1_9}}
(- transferencias internas)|{{ingresos_transferencias_1_7}}|{{ingresos_transferencias_1_9}}
**TOTAL**|{{ingresos_consolidado_1_7}}|{{ingresos_consolidado_1_9}}

###Gastos

 | No Financieros (I-VII) | Total (I-IX)
:--|---------------------:|-------------:
Estado|{{gastos_estado_1_7}}|{{gastos_estado_1_9}}
Organismos autónomos|{{gastos_ooaa_1_7}}|{{gastos_ooaa_1_9}}
Agencias estatales|{{gastos_agencias_1_7}}|{{gastos_agencias_1_9}}
Otros organismos|{{gastos_otros_1_7}}|{{gastos_otros_1_9}}
Seguridad Social|{{gastos_seg_social_1_7}}|{{gastos_seg_social_1_9}}
(- transferencias internas)|{{gastos_transferencias_1_7}}|{{gastos_transferencias_1_9}}
**TOTAL**|{{gastos_consolidado_1_7}}|{{gastos_consolidado_1_9}}
TEMPLATE

# Render the output file
summary_filename = File.join(output_path, "README.md")
File.open(summary_filename, 'w') do |file|
  file.write Mustache.render(template, summary)
end
