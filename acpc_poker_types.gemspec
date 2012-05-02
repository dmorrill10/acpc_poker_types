# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'version'
require 'rake/extensiontask'

Gem::Specification.new do |s|
  s.name        = "acpc_poker_types"
  s.version     = AcpcPokerTypes::VERSION
  s.authors     = ["Dustin Morrill"]
  s.email       = ["morrill@ualberta.ca"]
  s.homepage    = ""
  s.summary     = %q{ACPC Poker Types }
  s.description = %q{Poker classes and constants that conform to the standards of the Annual Computer Poker Competition.}

  s.add_dependency 'rake-compiler'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'simplecov'
  
  s.rubyforge_project = "acpc_poker_types"

  s.files         = Dir.glob("lib/**/*") + Dir.glob("ext/**/*") + Dir.glob("external/**/*") + %w(Rakefile acpc_poker_types.gemspec tasks.rb README.md)
  s.test_files    = Dir.glob "spec/**/*"
  s.extensions    = FileList["ext/**/extconf.rb"]
  s.require_paths = ["lib"]
end
