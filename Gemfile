source 'https://rubygems.org'

ruby '>= 3.2'

# Parsing the budget HTML pages
gem 'nokogiri'

# Reading the raw budget archives without unzipping them first
gem 'rubyzip'

# Rendering the budget summary README
gem 'mustache'

# Bundled gems since Ruby 3.4, so they have to be declared explicitly
gem 'bigdecimal'
gem 'csv'

group :development, :test do
  gem 'minitest'

  # Run in CI. `require: false` because nothing in the project loads these, they are
  # commands: bundle-audit checks the lockfile against the advisory database, and rubocop
  # holds new code to a standard the old code is exempted from in .rubocop_todo.yml.
  gem 'bundler-audit', require: false
  gem 'rubocop', require: false
  gem 'rubocop-minitest', require: false
end
