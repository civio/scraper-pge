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
  # Every archive keeps the pages in a 'doc/HTM' folder, but what sits above it varies:
  # 'PGE-ROM/doc/HTM' most years, '2023P/PGE-ROM/doc/HTM' in others. A couple of archives
  # were also rezipped on a Mac and carry AppleDouble leftovers ('__MACOSX/…/._N_23_….HTM')
  # whose names would otherwise match the breakdown patterns, so we skip those too.
  HTM_PAGE = %r{(?:\A|/)doc/HTM/(?!\._)[^/]+\.HTM\z}i

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

  # The pages whose name matches `pattern`, in a stable order. Sorting matters: several
  # steps of the parser keep the first (or last) description they see for a given code, so
  # the order pages are visited in shows up in the output files.
  def documents(pattern = //)
    all_documents.select { |document| document.name =~ pattern }
  end

  # The single page with the given file name, or nil when the budget doesn't include it.
  def document(name)
    documents_by_name[name]
  end

  def close; end

  private

  def documents_by_name
    @documents_by_name ||= all_documents.to_h { |document| [document.name, document] }
  end

  def all_documents
    @all_documents ||= build_documents.sort_by(&:name)
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
  def initialize(path)
    @path = path
  end

  private

  def build_documents
    # '**/' also matches zero folders, so this finds the pages whether `path` is the root
    # of an extracted archive or the folder holding 'doc/HTM' itself.
    Dir.glob(File.join(@path, '**', 'doc', 'HTM', '*.HTM'), File::FNM_CASEFOLD).
      reject { |path| File.basename(path).start_with?('._') }.
      map { |path| FileDocument.new(path) }
  end
end
