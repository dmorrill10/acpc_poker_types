# -*- encoding: utf-8 -*-
require File.expand_path('../lib/acpc_poker_types/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "acpc_poker_types"
  s.version     = AcpcPokerTypes::VERSION
  s.authors     = ["Dustin Morrill"]
  s.email       = ["morrill@ualberta.ca"]
  s.homepage    = ""
  s.summary     = %q{ACPC Poker Types}
  s.description = %q{Poker classes and constants that conform to the standards of the Annual Computer Poker Competition.}

  s.add_dependency 'rake-compiler'
  s.add_dependency 'dmorrill10-utils'
  
  s.files         = Dir.glob("lib/**/*") + Dir.glob("ext/**/*") + %w(Rakefile acpc_poker_types.gemspec tasks.rb README.md)
  s.test_files    = Dir.glob "spec/**/*"
  s.extensions    = Dir.glob "ext/**/extconf.rb"
  s.require_paths = ["lib"]

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'piston'
end
