require 'simplecov'
SimpleCov.start
$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)

require 'minitest/autorun'
require 'minitest/spec'

begin
  require 'awesome_print'
  module Minitest::Assertions
    def mu_pp(obj)
      obj.awesome_inspect
    end
  end

  require 'mocha/setup'
rescue LoadError
end

module MapWithIndex
  refine Array do
    def map_with_index
      i = 0
      map do |elem|
        result = yield elem, i
        i += 1
        result
      end
    end
  end
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
