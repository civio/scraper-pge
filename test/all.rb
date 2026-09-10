# Runs the whole suite: bundle exec ruby test/all.rb
Dir[File.expand_path('*_test.rb', __dir__)].sort.each { |test| require test }
