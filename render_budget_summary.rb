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

Total: X

###Gastos

Total: X
TEMPLATE

# Render the output file
summary_filename = File.join(output_path, "README.md")
File.open(summary_filename, 'w') do |file|
  file.write Mustache.render(template, year: year)
end
