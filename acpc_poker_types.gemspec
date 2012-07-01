# -*- encoding: utf-8 -*-
require File.expand_path('../lib/acpc_poker_types/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "acpc_poker_types"
  s.version     = AcpcPokerTypes::VERSION
  s.authors     = ["Dustin Morrill"]
  s.email       = ["morrill@ualberta.ca"]
  s.homepage    = "https://github.com/dmorrill10/acpc_poker_types"
  s.summary     = %q{ACPC Poker Types}
  s.description = %q{Poker classes and constants that conform to the standards of the Annual Computer Poker Competition.}
  
  s.files         = Dir.glob("lib/**/*") + %w(Rakefile acpc_poker_types.gemspec README.md)
  s.test_files    = Dir.glob "spec/**/*"
  s.require_paths = ["lib"]

  s.add_dependency 'dmorrill10-utils'
  s.add_dependency 'acpc_dealer'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'simplecov'
end
