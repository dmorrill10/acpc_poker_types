#!/usr/bin/env rake
require "bundler/gem_tasks"

require 'rake'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "lib" << 'spec/support'
  t.test_files = FileList['spec/**/*_spec.rb']
  t.verbose = false
  t.warning = true
end

task :default => :test
