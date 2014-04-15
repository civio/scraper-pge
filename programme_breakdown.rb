#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'

# Parser for programme expense breakdowns (Serie Roja / Red books)
#
# Note: the breakdowns in the Green books (Serie Verde) have more detail on the line
#       items, but they do not include the Social Security expenses. So we need to
#       combine both. (Or use only the Red ones, but since I started with the green
#       ones... oh, well.)
#
# NOTE: WORKS ONLY FOR SOCIAL SECURITY PROGRAMMES RIGHT NOW (FIXME?!?)
#
class ProgrammeBreakdown
  attr_reader :year, :programme

  def initialize(filename)
    filename =~ PROGRAMME_EXPENSES_BKDOWN
    @year = '20'+$1
    @programme = $2         # Programme id (of the form '123A')
    @filename = filename
  end
  
  def section
    doc.css('.S0ESTILO3').first.text.strip =~ /^Sección: (\d\d) .+$/
    $1
  end

  # Note: as opposed to the case of the EntityBreakdown, we can't know from the 
  #       programme breakdown what type of entity is doing the expense, i.e. whether 
  #       it's part of the state (type 1) or it's a dependent agency (types 2-4).
  #       The entity breakdown parser extracts this information, but it's not actually used
  #       at the moment, so it's not an issue. If needed, there should exist an Entity table
  #       with this type of info, instead of having one single data table (TODO).
  #
  def entity_type
    '1'
  end
  
  def programme_name
    doc.css('.S0ESTILO3').last.text.strip =~ /^Programa: \d\d\d\w (.+)$/
    $1
  end
  
  def expenses    
    expenses = []
    last_service = ''

    # Iterate through HTML table, skipping header
    rows = doc.css('table.S0ESTILO8 tr')[1..-1]               # 2008 onwards (earlier?)
    rows.map do |row|
      columns = row.css('td').map{|td| td.text.strip}
      expense = {
        :service => columns[0].slice(3..4), # section.service comes in the form xx.xx
        :programme => @programme, 
        :expense_concept => columns[1], 
        :description => columns[2],
        :amount => (columns[3] != '') ? columns[3] : columns[4] 
      }
      next if expense[:description].empty?  # Skip empty lines (no description)

      # Fill blanks in row and save result
      if expense[:service].nil?
        expense[:service] = last_service
      else
        last_service = expense[:service]
        
        # Bit of a hack (again). We want the subtotals from this breakdown to look like
        # the ones extracted from an EntityBreakdown, but here the data is presented
        # as programme>entity>expense, while there they look like entity>programme>expense.
        # So we need to change the subtotal description to include the programme name.
        # TODO: Using the subtotals provided in the input files was convenient at the 
        #       beginning, but it's getting complicated. Should get rid of them. Maybe
        #       keep the programme-level ones, but only those.
        expense[:description] = programme_name
      end
      expenses << expense      
    end
    expenses
  end
  
  def self.programme_breakdown? (filename)
    filename=~PROGRAMME_EXPENSES_BKDOWN
  end
  
  private
  
  PROGRAMME_EXPENSES_BKDOWN =      /N_(\d\d)_[AE]_R_31_2_1_G_1_1_1(\d\d\d\w)_P.HTM/;
  # Note:                                              ^ 
  #       This will catch only Social Security programme breakdowns (see Budget class for info).
  #       It's what I need for now. Note it doesn't pick up internal transfers either. 
  
  def doc
    @doc = Nokogiri::HTML(open(@filename)) if @doc.nil?  # Lazy parsing of doc, only when needed
    @doc
  end
end