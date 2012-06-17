require File.expand_path("../acpc_poker_types/version", __FILE__)

module AcpcPokerTypes
  # @todo Move to project_acpc_server gem
  # @return [Hash<Symbol, String>] File names of the game definitions understood by this application.
  GAME_DEFINITION_FILE_NAMES = lambda do
    path_to_project_acpc_server_directory = File.expand_path('../../ext/project_acpc_server', __FILE__)

    {
      holdem_limit_2p_reverse_blinds_game: "#{path_to_project_acpc_server_directory}/holdem.limit.2p.reverse_blinds.game",
      holdem_no_limit_2p_reverse_blinds_game: "#{path_to_project_acpc_server_directory}/holdem.nolimit.2p.reverse_blinds.game",
      holdem_limit_3p_reverse_blinds_game: "#{path_to_project_acpc_server_directory}/holdem.limit.3p.game",
      holdem_no_limit_3p_reverse_blinds_game: "#{path_to_project_acpc_server_directory}/holdem.nolimit.3p.game"
    }
  end.call
end

require File.expand_path("../hand_evaluator", __FILE__)
require File.expand_path("../acpc_poker_types/board_cards", __FILE__)
require File.expand_path("../acpc_poker_types/card", __FILE__)
require File.expand_path("../acpc_poker_types/chip_stack", __FILE__)
require File.expand_path("../acpc_poker_types/game_definition", __FILE__)
require File.expand_path("../acpc_poker_types/hand", __FILE__)
require File.expand_path("../acpc_poker_types/match_state", __FILE__)
require File.expand_path("../acpc_poker_types/pile_of_cards", __FILE__)
require File.expand_path("../acpc_poker_types/player", __FILE__)
require File.expand_path("../acpc_poker_types/rank", __FILE__)
require File.expand_path("../acpc_poker_types/suit", __FILE__)
