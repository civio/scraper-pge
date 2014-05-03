
namespace 'budget' do
  
  desc "Extract all information from budget files"
  task :parse, [:year] do |t, args|
    puts "Parsing budget for year #{args.year}."
    puts `ruby "#{File.dirname(__FILE__)}/parse_budget.rb" "#{args.year}"`
  end

  desc "Generate a summary with budget key figures"
  task :summary, [:year] do |t, args|
    puts "Rendering budget summary for year #{args.year}."
    puts `ruby "#{File.dirname(__FILE__)}/render_budget_summary.rb" "#{args.year}"`
  end
end