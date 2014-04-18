#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'

# About the entity type:
#   - State: ministries and their parts (departments, for example). Marked as type 1
#   - Non-state: autonomus bodies (type 2), dependent agencies (3) and other bodies (4)
#
class EntityBreakdown
  attr_reader :year, :section, :entity, :entity_type, :filename

  def initialize(filename)
    # The filename structure changed in 2012, so we need to start by finding out the year
    @year = EntityBreakdown.get_year(filename)
    
    # Once the year is known, we can extract additional details from the filename
    @filename = filename
    filename =~ EntityBreakdown.get_expense_breakdown_filename_regex(@year, is_state_entity?)
    @entity_type = $2                       # Always 1 for state entities, 2-4 for non-state
    @section = $3                           # Parent section
    @entity = $4 unless is_state_entity?    # Id of the non-state entity
  end
  
  def is_state_entity?
    @filename =~ EntityBreakdown.get_expense_breakdown_filename_regex(@year, true)    
  end
  
  def name
    # Note: the name may include accented characters, so '\w' doesn't work in regex
    if is_state_entity?
      # TODO: check years before 2008
      section_css_class = (year=='2008') ? '.S0ESTILO4' : (year=='2014' ? '.S0ESTILO3' : '.S0ESTILO2')
      doc.css(section_css_class).text.strip =~ /^Sección: \d\d (.+)$/
    else
      year == '2012' || year == '2013' || year == '2014' ? 
        doc.css('.S0ESTILO4')[1].text.strip =~ /^Organismo: \d\d\d (.+)$/ :
        doc.css('.S0ESTILO3').last.text.strip =~ /^Organismo: \d\d\d (.+)$/
    end
    $1
  end
  
  def children
    is_state_entity? ?
      expenses.map {|row| {:id=>row[:service], :name=>row[:description]} if row[:programme].empty? }.compact :
      [{:id => @entity, :name => name}]
  end
  
  def expenses
    # Breakdowns for state entities contain many sub-entities, whose id is contained in the rows.
    # Breakdowns for non-state entities apply to only one child entity, which we know in advance.
    last_service = is_state_entity? ? '' : entity
    last_programme = ''
    
    # Iterate through HTML table, skipping header
    expenses = []
    rows = doc.css('table.S0ESTILO9 tr')[1..-1]               # 2008 (and earlier?)
    rows = doc.css('table.S0ESTILO8 tr')[1..-1] if rows.nil?  # 2009 onwards
    rows.each do |row|
      columns = row.css('td').map{|td| td.text.strip}
      columns.shift if year == '2012' or year == '2013' or year == '2014'
      columns.insert(0,'') unless is_state_entity? # They lack the first column, 'service'
      expense = {
        :service => columns[0], 
        :programme => columns[1], 
        :expense_concept => columns[2], 
        :description => columns[3],
        :amount => (columns[4] != '') ? columns[4] : columns[5] 
      }
      next if expense[:description].empty?  # Skip empty lines (no description)

      # Fill blanks in row and save result
      if expense[:service].empty?
        expense[:service] = last_service
      else
        last_service = expense[:service]
        last_programme = ''
      end
      
      if expense[:programme].empty?
        expense[:programme] = last_programme
      else
        last_programme = expense[:programme] 
      end
      
      expenses << expense      
    end
    expenses
  end
  
  # TODO: Refactor all this messy filename handling logic! :/
  def self.entity_breakdown? (filename)
    year = EntityBreakdown.get_year(filename)
    filename =~ get_expense_breakdown_filename_regex(year, true) || filename =~ get_expense_breakdown_filename_regex(year, false)
  end

  private  
  
  def self.get_year(filename)
    filename =~ /N_(\d\d)_[AE]/
    return '20'+$1
  end
  
  def self.get_expense_breakdown_filename_regex(year, is_state_entity)
    if year == '2012' || year == '2013' || year == '2014'
      is_state_entity ? 
        /N_(\d\d)_[AE]_V_1_10([1234])_1_1_2_2_[1234](\d\d)_1_2.HTM/ :
        /N_(\d\d)_[AE]_V_1_10([1234])_2_1_[1234](\d\d)_1_1(\d\d\d)_2_2_1.HTM/;
    else
      is_state_entity ? 
        /N_(\d\d)_[AE]_V_1_10([1234])_2_2_2_1(\d\d)_1_[12]_1.HTM/ :
        /N_(\d\d)_[AE]_V_1_10([1234])_2_2_2_1(\d\d)_1_[12]_1(\d\d\d)_1.HTM/;
    end
  end
  
  def doc
    @doc = Nokogiri::HTML(open(@filename)) if @doc.nil?  # Lazy parsing of doc, only when needed
    @doc
  end
end