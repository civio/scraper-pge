require_relative 'test_helper'

require 'stringio'

# Reparses each budget from its raw archive and checks it still produces exactly the files
# published under output/. This is the real regression net: the fixture tests above cover
# the parsing of individual pages, this one covers 300.000 lines of real output.
#
# The archives are ~10 GB and not in the repository, so a budget whose archive is missing
# is skipped rather than failed. Set PGE_BUDGETS=2013,2023 to check just a couple of them.
class GoldenOutputTest < Minitest::Test
  include TestHelper

  OUTPUT_FILES = %w[
    estructura_economica.csv estructura_funcional.csv estructura_organica.csv
    gastos.csv ingresos.csv README.md
  ].freeze

  budget_ids = Dir.children(File.join(TestHelper::ROOT, 'output')).grep(/\A\d{4}P?\z/).sort
  budget_ids &= ENV['PGE_BUDGETS'].split(',') if ENV['PGE_BUDGETS']

  budget_ids.each do |budget_id|
    define_method("test_#{budget_id}_reparses_to_the_published_files") do
      archive = archive_for(budget_id)
      skip "raw archive for #{budget_id} is not available" if archive.nil?

      Dir.mktmpdir do |produced|
        regenerate(budget_id, archive, produced)

        OUTPUT_FILES.each do |filename|
          published = File.join(TestHelper::ROOT, 'output', budget_id, filename)
          assert_equal_files published, File.join(produced, filename), budget_id
        end
      end
    end
  end

  private

  def archive_for(budget_id)
    [File.join(TestHelper::ROOT, 'raw', "#{budget_id}.zip"),
     File.join(TestHelper::ROOT, 'raw', budget_id)].find { |path| File.exist?(path) }
  end

  def regenerate(budget_id, archive, output_path)
    year = budget_id[0..3]
    is_final = (budget_id.length == 4)
    corrections = File.join(TestHelper::ROOT, 'corrections', "#{budget_id}.csv")

    silently do
      BudgetSource.open(archive) do |source|
        budget = Budget.new(source, is_final)
        BudgetParser.new(budget, year, output_path, corrections).run
        BudgetSummaryRenderer.new(budget, year, output_path).run
      end
    end
  end

  # The parser reports inconsistencies in the source data on stdout, which would otherwise
  # be scattered through the test output
  def silently
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end

  # assert_equal on files this size would dump megabytes on failure, so report which lines
  # actually appeared or disappeared instead
  def assert_equal_files(published, produced, budget_id)
    expected = File.readlines(published)
    actual = File.readlines(produced)
    return if expected == actual

    only_published = expected - actual
    only_produced = actual - expected
    first = expected.zip(actual).index { |a, b| a != b }

    details = ["  #{only_published.size} line(s) only in output/, #{only_produced.size} only in the new run"]
    details << "  first difference at line #{first + 1}:" unless first.nil?
    details << "    published: #{expected[first].inspect}" unless first.nil?
    details << "    produced:  #{actual[first].inspect}" unless first.nil?
    only_published.first(3).each { |line| details << "    only in output/: #{line.inspect}" }
    only_produced.first(3).each { |line| details << "    only in new run: #{line.inspect}" }

    flunk "#{budget_id}/#{File.basename(published)} changed " \
          "(#{expected.size} lines published, #{actual.size} produced):\n#{details.join("\n")}"
  end
end
