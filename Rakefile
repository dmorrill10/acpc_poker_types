#!/usr/bin/env rake

require 'bundler/gem_tasks'
require 'rake'
require 'rspec/core/rake_task'

require File.expand_path('../lib/acpc_poker_types/version', __FILE__)

RSpec::Core::RakeTask.new(:spec) do |t|
  ruby_opts = "-w"
end

desc 'Build gem'
task :default => :build

task :tag => :build do
  puts "Tagging #{AcpcPokerTypes::VERSION}..."
  system "git tag -a #{AcpcPokerTypes::VERSION} -m 'Tagging #{AcpcPokerTypes::VERSION}'"
  puts "Pushing #{AcpcPokerTypes::VERSION} to git..."
  system "git push --tags"
end
