require 'rake'
require 'rake/testtask'

desc "Run the unit tests"
task :default => 'test'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "revo-ssl_requirement"
    gemspec.summary = "Allow controller actions to force SSL on specific parts of the site."
    gemspec.description = "SSL requirement adds a declarative way of specifying that certain actions should only be allowed to run under SSL, and if they're accessed without it, they should be redirected."
    gemspec.email = 'percival@umamibud.com'
    gemspec.homepage = 'http://github.com/revo/ssl_requirement'
    gemspec.authors = ['RailsJedi', 'David Heinemeier Hansson', 'jcnetdev', 'bcurren', 'bmpercy']
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

Rake::TestTask.new(:test) do |t|
  t.pattern = 'test/**/*_test.rb'
  t.ruby_opts << '-rubygems'
  t.libs << 'test'
  t.verbose = true
end
