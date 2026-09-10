require 'zip'

# The collection of HTML pages that make up one budget, read either straight from one of
# the .zip archives published by the ministry or from an already extracted copy of one.
# Reading the archive directly is the normal case: it avoids unzipping ~850 MB to disk,
# and we only ever need a few hundred of the ~5.000 pages inside.
#
# Both flavours expose the same interface: `documents` returns the budget pages, each
# responding to `name` (the bare file name, i.e. 'N_23_E_R_2_101_1.HTM') and `read` (the
# contents, as binary, so that Nokogiri picks up the windows-1252 charset declared in the
# page itself rather than assuming UTF-8).
class BudgetSource
  # Every archive the ministry publishes lays the pages out the same way, and an extracted
  # copy mirrors it
  PAGES_FOLDER = 'PGE-ROM/doc/HTM'.freeze
  HTM_PAGE = %r{\A#{PAGES_FOLDER}/[^/]+\.HTM\z}i

  # Opens whatever `path` points at: a .zip archive or an extracted folder. Given a block,
  # the source is closed when it returns.
  def self.open(path)
    source = File.directory?(path) ? DirectorySource.new(path) : ZipSource.new(path)
    return source unless block_given?

    begin
      yield source
    ensure
      source.close
    end
  end

  def initialize(path)
    @path = path
  end

  # The budget pages, in a stable order. Sorting matters: several steps of the parser keep
  # the first (or the last) description they see for a given code, so the order pages are
  # visited in shows up in the output files.
  def documents
    @documents ||= build_documents.sort_by(&:name).tap do |documents|
      # Rather than parse a budget into a set of empty files. An archive that doesn't hold
      # the pages where it should is either not a budget, or has been repacked on the way
      # here: every one of them downloaded from the ministry has this same layout.
      raise "No budget pages under #{PAGES_FOLDER} in #{@path}" if documents.empty?
    end
  end

  # The single page with the given file name, or nil when the budget doesn't include it.
  def document(name)
    documents_by_name[name]
  end

  def close; end

  private

  def documents_by_name
    @documents_by_name ||= documents.to_h { |document| [document.name, document] }
  end
end

# One budget page inside a .zip archive.
class ZipDocument
  attr_reader :name

  def initialize(entry)
    @entry = entry
    @name = File.basename(entry.name)
  end

  def read
    @entry.get_input_stream(&:read)
  end
end

# One budget page on disk.
class FileDocument
  attr_reader :name

  def initialize(path)
    @path = path
    @name = File.basename(path)
  end

  def read
    File.binread(@path)
  end
end

class ZipSource < BudgetSource
  def initialize(path)
    raise ArgumentError, "No such budget archive: #{path}" unless File.file?(path)

    super
    @zip = Zip::File.open(path)
  end

  def close
    @zip.close
  end

  private

  def build_documents
    @zip.entries.select { |entry| entry.name =~ HTM_PAGE }.map { |entry| ZipDocument.new(entry) }
  end
end

class DirectorySource < BudgetSource
  private

  def build_documents
    Dir.glob(File.join(@path, PAGES_FOLDER, '*.HTM'), File::FNM_CASEFOLD).
      map { |path| FileDocument.new(path) }
  end
end
