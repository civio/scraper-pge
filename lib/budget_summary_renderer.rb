require 'csv'
require 'fileutils'
require 'mustache'

require_relative 'budget'
require_relative 'budget_summary_view'

# Generate a summary with the key figures of a budget, in Markdown, so it can be
# explored more easily in Github, f.ex.
class BudgetSummaryRenderer
  # Inline template
  TEMPLATE = <<TEMPLATE
## Presupuesto {{year}}

### Ingresos

|                             | No Financieros (I-VII) | I-VIII | Total (I-IX) | Consolidado |
| :-------------------------- | ---------------------: | -----: | -----------: | ----------: |
| **Estado**                  | {{ingresos_estado}}
| **Organismos autónomos**    | {{ingresos_ooaa}}
| **Agencias estatales**      | {{ingresos_agencias}}
| **Otros organismos**        | {{ingresos_otros}}
| **Seguridad Social**        | {{ingresos_seg_social}}
| (- transferencias internas) | {{ingresos_transferencias}}
| **TOTAL**                   | {{ingresos_consolidado}}

### Gastos

|                             | No Financieros (I-VII) | I-VIII | Total (I-IX) | Consolidado |
| :-------------------------- |----------------------: | -----: | -----------: | ----------: |
| **Estado**                  | {{gastos_estado}}
| **Organismos autónomos**    | {{gastos_ooaa}}
| **Agencias estatales**      | {{gastos_agencias}}
| **Otros organismos**        | {{gastos_otros}}
| **Seguridad Social**        | {{gastos_seg_social}}
| (- transferencias internas) | {{gastos_transferencias}}
| **TOTAL**                   | {{gastos_consolidado}}

### Comprobaciones

{{{check_budget}}}
TEMPLATE

  def initialize(budget, year, output_path)
    @budget = budget
    @year = year
    @output_path = output_path
  end

  # Reads back the CSV files written by BudgetParser, adds the figures up and compares
  # them against the summaries published as part of the official budget.
  def run
    summary = BudgetSummaryView.new(@budget, @year)
    CSV.foreach(File.join(@output_path, "ingresos.csv"), col_sep: ';') do |row|
      summary.add_item row
    end
    CSV.foreach(File.join(@output_path, "gastos.csv"), col_sep: ';') do |row|
      summary.add_item row
    end

    FileUtils.mkdir_p @output_path
    summary_filename = File.join(@output_path, "README.md")
    File.open(summary_filename, 'w') do |file|
      file.write Mustache.render(TEMPLATE, summary)
    end
    summary_filename
  end
end
