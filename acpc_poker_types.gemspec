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
  s.license     = 'MIT'

  s.add_dependency 'process_runner', '~> 0.0'
  s.add_dependency 'acpc_dealer', '~> 3.0'
  s.add_dependency 'celluloid', '~> 0.14'
  s.add_dependency 'contextual_exceptions', '~> 0.0'
  s.add_dependency 'inflections', '~> 3.2'

  s.files         = Dir.glob("lib/**/*") + %w(Rakefile acpc_poker_types.gemspec README.md)
  s.test_files    = Dir.glob "spec/**/*"
  s.require_paths = ["lib"]

  s.add_development_dependency 'minitest', '~> 5.5'
  s.add_development_dependency 'mocha', '~> 0.13'
  s.add_development_dependency 'awesome_print', '~> 1.0'
  s.add_development_dependency 'simplecov', '~> 0.7'
end
