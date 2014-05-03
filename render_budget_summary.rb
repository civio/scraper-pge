#!/usr/bin/env ruby

# Generate a summary with the key figures of a budget, in Markdown, so it can be 
# explored more easily in Github, f.ex.

# XXX: This command line stuff is duplicated in the parser, should clean up
budget_id = ARGV[0]
year = budget_id[0..3]  # Sometimes there's a P for 'Proposed' at the end. Ignore that bit
output_path = File.join(".", "output", budget_id)

summary_filename = File.join(output_path, "README.md")
File.open(summary_filename, 'w') { |file| file.write("Hello world") }