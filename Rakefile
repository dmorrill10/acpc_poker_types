require 'bundler/gem_tasks'
require 'rake'
require 'rake/extensiontask'
require 'rspec/core/rake_task'

require File.expand_path('../lib/version', __FILE__)
require File.expand_path('../tasks', __FILE__)

include Tasks

Rake::ExtensionTask.new('hand_evaluator')

RSpec::Core::RakeTask.new(:spec) do |t|
   ruby_opts = "-w"
end

desc 'Compile, build, tag, and run specs'
task :default => :compile do
   Rake::Task[:spec].invoke
   Rake::Task[:tag].invoke
end

task :build => :compile do
   Rake::Task[:spec].invoke
   system "gem build acpc_poker_types.gemspec"
end

task :tag => :build do
   tag_gem_version AcpcPokerTypes::VERSION
end

task :install => :compile do
end
