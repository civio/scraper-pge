require_relative 'test_helper'

require 'csv'

# End to end run of the parser over the fixture pages. The fixture deliberately mixes the
# three page formats, so this is a smoke test of the whole pipeline rather than a check of
# a real budget: assertions stick to rows that can only have come from the 2013 pages.
class BudgetParserTest < Minitest::Test
  include TestHelper

  def setup
    @output = Dir.mktmpdir
    with_fixture_source do |source|
      BudgetParser.new(Budget.new(source, true), '2013', @output).run
    end
  end

  def teardown
    FileUtils.remove_entry(@output)
  end

  def test_writes_the_five_output_files
    assert_equal %w[estructura_economica.csv estructura_funcional.csv estructura_organica.csv
                    gastos.csv ingresos.csv],
                 Dir.children(@output).sort
  end

  def test_creates_the_output_folder_if_it_is_not_there_yet
    nested = File.join(@output, 'nope', '2013')
    with_fixture_source do |source|
      BudgetParser.new(Budget.new(source, true), '2013', nested).run
    end

    assert File.exist?(File.join(nested, 'gastos.csv'))
  end

  def test_writes_semicolon_separated_files_with_a_header
    assert_equal %w[EJERCICIO CENTRO\ GESTOR FUNCIONAL ECONOMICA FINANCIACION ITEM DESCRIPCION IMPORTE],
                 read('gastos.csv').first
  end

  def test_builds_the_entity_id_out_of_section_and_service
    bodies = read('estructura_organica.csv').drop(1).to_h { |row| [row[1], row[3]] }

    assert_equal 'Casa De Su Majestad El Rey', bodies['01']
    assert_equal 'Casa De Su Majestad El Rey', bodies['01001']
    assert_equal 'Comisionado Para El Mercado De Tabacos', bodies['15104']
  end

  def test_keeps_the_default_policies_even_when_no_page_mentions_them
    programmes = read('estructura_funcional.csv').drop(1).to_h { |row| [row[4] || row[2] || row[1], row[6]] }

    assert_equal 'Deuda pública', programmes['95']
    assert_equal 'Prestaciones económicas por cese de actividad', programmes['224M']
  end

  def test_converts_amounts_from_thousands_of_euros
    income = read('ingresos.csv').drop(1)
    tasas = income.find { |row| row[1] == '15104' && row[2] == '30' && row[4].nil? }

    assert_equal '19500000', tasas[6]
  end

  # Chapter and article descriptions are shared across the whole budget, so they end up in
  # the economic structure file once, uppercased into something readable.
  def test_collects_the_economic_categories
    categories = read('estructura_economica.csv').drop(1)
    expenses = categories.select { |row| row[1] == 'G' }.to_h { |row| [row[4] || row[3] || row[2], row[7]] }

    assert_equal 'Gastos de personal', expenses['1']
    assert_equal 'Funcionarios', expenses['12']
  end

  private

  def read(filename)
    CSV.read(File.join(@output, filename), col_sep: ';')
  end
end
