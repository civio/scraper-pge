require_relative 'test_helper'

require 'zip'

# The archives published by the ministry are not consistent with each other, and used to
# be dealt with by unzipping them by hand and pointing a symlink at the result. These tests
# pin down the layouts BudgetSource has to cope with.
class BudgetSourceTest < Minitest::Test
  include TestHelper

  def test_finds_the_pages_in_a_zip_archive
    with_fixture_source do |source|
      assert_equal 11, source.documents.size
    end
  end

  def test_documents_are_named_after_the_page_not_its_folder
    with_fixture_source do |source|
      assert_includes source.documents.map(&:name), 'N_13_E_R_6_2_801_1_3.HTM'
      refute source.documents.any? { |document| document.name.include?('/') }
    end
  end

  # Several steps of the parser keep the first (or the last) description they see for a
  # given code, so the order pages come back in ends up in the output files.
  def test_documents_come_back_in_a_stable_order
    with_fixture_source do |source|
      names = source.documents.map(&:name)
      assert_equal names.sort, names
    end
  end

  def test_looks_up_a_single_page_by_name
    with_fixture_source do |source|
      assert_equal 'N_13_E_R_6_2_801_1_3.HTM', source.document('N_13_E_R_6_2_801_1_3.HTM').name
      assert_nil source.document('N_13_E_R_6_2_899_9_9.HTM')
    end
  end

  # Pages are windows-1252, and declare as much in a meta tag. Handing Nokogiri a string
  # tagged as UTF-8 would mangle every accent, so the source has to return raw bytes.
  def test_pages_are_read_as_binary
    with_fixture_source do |source|
      contents = source.document('N_13_E_R_2_102_1_2_115_1_1104_1.HTM').read
      assert_equal Encoding::ASCII_8BIT, contents.encoding
    end
  end

  def test_reads_an_extracted_archive_just_like_the_zip
    Dir.mktmpdir do |dir|
      system('unzip', '-q', FIXTURE_ZIP, '-d', dir, exception: true)

      from_zip = BudgetSource.open(FIXTURE_ZIP) { |s| s.documents.map { |d| [d.name, d.read] } }
      from_dir = BudgetSource.open(dir) { |s| s.documents.map { |d| [d.name, d.read] } }

      assert_equal from_zip, from_dir
    end
  end

  # An archive holds a great deal more than the pages we parse: PDFs, CSVs, images and the
  # frame pages of the browsable version.
  def test_ignores_everything_that_is_not_a_budget_page
    with_archive(
      'PGE-ROM/doc/HTM/N_23_E_R_6_2_801_1_3.HTM' => '<html></html>',
      'PGE-ROM/doc/HTM/img/EscudoColor.gif' => 'an image',
      'PGE-ROM/doc/CSV/N_23_E_R_6_2_801_1_3.CSV' => 'the same data, as CSV',
      'PGE-ROM.htm' => 'the frame page'
    ) do |archive|
      BudgetSource.open(archive) do |source|
        assert_equal ['N_23_E_R_6_2_801_1_3.HTM'], source.documents.map(&:name)
      end
    end
  end

  # Some archives used to carry a wrapping folder and a pile of AppleDouble files, from
  # having been unzipped and rezipped on a Mac. They have all been replaced with the
  # ministry's originals, so anything laid out differently is now rejected outright rather
  # than quietly parsed into a set of empty files.
  def test_complains_when_the_pages_are_not_where_they_should_be
    with_archive('2023P/PGE-ROM/doc/HTM/N_23_E_R_6_2_801_1_3.HTM' => '<html></html>') do |archive|
      error = assert_raises(RuntimeError) do
        BudgetSource.open(archive, &:documents)
      end
      assert_match 'PGE-ROM/doc/HTM', error.message
    end
  end

  def test_complains_about_a_missing_archive
    assert_raises(ArgumentError) { BudgetSource.open('raw/1999.zip') }
  end

  private

  def with_archive(entries)
    Dir.mktmpdir do |dir|
      archive = File.join(dir, 'budget.zip')
      Zip::File.open(archive, create: true) do |zip|
        entries.each { |name, contents| zip.get_output_stream(name) { |io| io.write contents } }
      end
      yield archive
    end
  end
end
