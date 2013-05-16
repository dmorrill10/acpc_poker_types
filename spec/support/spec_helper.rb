require 'simplecov'
SimpleCov.start

require 'minitest/spec'

begin
  require 'turn'

  Turn.config do |c|
    # use one of output formats:
    # :outline  - turn's original case/test outline mode [default]
    # :progress - indicates progress with progress bar
    # :dotted   - test/unit's traditional dot-progress mode
    # :pretty   - new pretty reporter
    # :marshal  - dump output as YAML (normal run mode only)
    # :cue      - interactive testing
    c.format  = :dotted
    # use humanized test names (works only with :outline format)
    c.natural = true
  end

  require 'awesome_print'
  module Minitest::Assertions
    def mu_pp(obj)
      obj.awesome_inspect
    end
  end

  require 'pry-rescue/minitest'
  require 'mocha/setup'
rescue LoadError
end

# Match log information in dealer_logs
class MatchLog
  DEALER_LOG_DIRECTORY = File.expand_path('../dealer_logs', __FILE__)

  attr_reader :results_file_name, :actions_file_name, :player_names, :dealer_log_directory

  def self.all
    [
      MatchLog.new(
        '2p.limit.h1000.r0.log',
        '2p.limit.h1000.r0.actions.log',
        ['p1', 'p2']
      ),
      MatchLog.new(
        '2p.nolimit.h1000.r0.log',
        '2p.nolimit.h1000.r0.actions.log',
        ['p1', 'p2']
      ),
      MatchLog.new(
        '3p.limit.h1000.r0.log',
        '3p.limit.h1000.r0.actions.log',
        ['p1', 'p2', 'p3']
      ),
      MatchLog.new(
        '3p.nolimit.h1000.r0.log',
        '3p.nolimit.h1000.r0.actions.log',
        ['p1', 'p2', 'p3']
      )
    ]
  end

  def initialize(results_file_name, actions_file_name, player_names)
    @results_file_name = results_file_name
    @actions_file_name = actions_file_name
    @player_names = player_names
  end

  def actions_file_path
    "#{DEALER_LOG_DIRECTORY}/#{@actions_file_name}"
  end

  def results_file_path
    "#{DEALER_LOG_DIRECTORY}/#{@results_file_name}"
  end
end