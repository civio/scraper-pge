
namespace 'parse' do
  
  desc "Extract all information from budget files"
  task :budget, [:year] do |t, args|
    puts `ruby "#{File.dirname(__FILE__)}/parse_budget.rb" "#{args.year}"`
    puts "Parsed budget for year #{args.year}."
  end

end