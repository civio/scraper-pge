#!/usr/bin/env ruby

# Generate a summary with the key figures of a budget, in Markdown, so it can be
# explored more easily in Github, f.ex.

require 'mustache'

# XXX: This command line stuff is duplicated in the parser, should clean up
budget_id = ARGV[0]
year = budget_id[0..3]  # Sometimes there's a P for 'Proposed' at the end. Ignore that bit
output_path = File.join(".", "output", budget_id)

# Inline template
template = <<TEMPLATE
##Presupuesto {{year}}

###Ingresos

||No Financieros (I-VII)|Total (I-IX)|Transferencias|Total Consolidado|
|:-|-------------------:|-----------:|-------------:|----------------:|
|Estado|{{estado_1_7}}|{{estado_1_9}}|{{estado_transfer}}|{{estado_total}}|
|Organismos autónomos|{{ooaa_1_7}}|{{ooaa_1_9}}|{{ooaa_transfer}}|{{ooaa_total}}|
|Agencias estatales|{{agencias_1_7}}|{{agencias_1_9}}|{{agencias_transfer}}|{{agencias_total}}|
|Otros organismos|{{otros_1_7}}|{{otros_1_9}}|{{otros_transfer}}|{{otros_total}}|
|Seguridad Social|{{seg_social_1_7}}|{{seg_social_1_9}}|{{seg_social_transfer}}|{{seg_social_total}}|

###Gastos

Total: X
TEMPLATE

# Render the output file
summary_filename = File.join(output_path, "README.md")
File.open(summary_filename, 'w') do |file|
  file.write Mustache.render(template, year: year)
end
