require_relative 'test_helper'

# Every archive the ministry publishes keeps its pages at PGE-ROM/doc/HTM, and an extracted
# copy mirrors it. These tests pin down what counts as a budget page, and what happens to an
# archive laid out any other way.
class BudgetSourceTest < Minitest::Test
  include TestHelper

  def test_finds_the_pages_of_a_budget
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

  # The fixture pages are plain files, but a budget is normally read straight out of its
  # .zip, so both ways of reading them have to agree page for page and byte for byte.
  def test_reads_a_zip_archive_just_like_an_extracted_copy
    from_folder = with_fixture_source { |source| pages(source) }
    from_zip = with_fixture_archive { |archive| BudgetSource.open(archive) { |source| pages(source) } }

    assert_equal 11, from_zip.size
    assert_equal from_folder, from_zip
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

  def pages(source)
    source.documents.map { |document| [document.name, document.read] }
  end
end
