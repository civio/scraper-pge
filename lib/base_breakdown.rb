class BaseBreakdown

  # Returns a list of budget items and subtotals. Because of the convoluted format of the 
  # input file, with subtotals being split across two lines, some massaging is needed.
  def merge_subtotals(data_grid, year, section, open_subtotals=[])
    lines = []
    data_grid.each do |row|
      partial_line = {
        year: year,
        section: section,
        service: row[:service],
        programme: row[:programme],
        economic_concept: row[:expense_concept],
        description: row[:description]
      }
    
      if ( row[:amount].empty? )              # opening heading
        open_subtotals << partial_line
      elsif ( row[:expense_concept].empty? )  # closing heading
        last_heading = open_subtotals.pop()
        lines.push( last_heading.merge({ amount: row[:amount] }) ) unless last_heading.nil?
      else                                    # standard data row
        lines.push( partial_line.merge({ amount: row[:amount] }) )
      end
    end
    lines
  end

end