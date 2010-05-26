require 'rake'
require 'jeweler'

begin
  Jeweler::Tasks.new do |gem|
    gem.name = "fgraph"
    gem.summary = "Ruby Facebook Graph API"
    gem.description = "Ruby Facebook Graph API"
    gem.email = "herryanto@gmail.com"
    gem.homepage = "http://github.com/jugend/fgraph"
    gem.authors = ["Herryanto Siatono"]
    gem.files = FileList["[A-Z]*", "{examples,lib,test,rails,tasks,templates}/**/*"]
    
    gem.add_dependency("httparty", "~> 0.5.0")
    
    gem.add_development_dependency("shoulda", "~> 2.10.0")
    gem.add_development_dependency("jnunemaker-matchy", "~> 0.4.0")
    gem.add_development_dependency("mocha", "~> 0.9.0")
    gem.add_development_dependency("fakeweb", "~> 1.2.0")
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

Jeweler::GemcutterTasks.new

require "rake/testtask"
Rake::TestTask.new(:test) do |test|
  test.libs << "test"
  test.ruby_opts << "-rubygems"
  test.pattern = "test/**/*_test.rb"
  test.verbose = true
end

task :default  => :test
task :test     => :check_dependencies