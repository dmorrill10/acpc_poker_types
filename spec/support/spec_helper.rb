
require 'simplecov'
SimpleCov.start

require 'mocha'

RSpec.configure do |config|
   # == Mock Framework
   config.mock_with :mocha
end

LIB_ACPC_POKER_TYPES_PATH = File.expand_path('../../../lib/acpc_poker_types', __FILE__)
