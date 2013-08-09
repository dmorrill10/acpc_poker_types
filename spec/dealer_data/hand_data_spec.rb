# Spec helper (must include first to track code coverage with SimpleCov)
require_relative '../support/spec_helper'

require 'mocha/setup'

require 'acpc_dealer'
require 'acpc_poker_types/match_state'
require 'acpc_poker_types/poker_action'

require 'acpc_poker_types/dealer_data/action_messages'
require 'acpc_poker_types/dealer_data/hand_data'
require 'acpc_poker_types/dealer_data/hand_results'
require 'acpc_poker_types/dealer_data/match_definition'

describe AcpcPokerTypes::DealerData::HandData do
  before do
    @patient = nil
    @chip_distribution = nil
    @match_def = nil
    @current_match_state = nil
    @last_match_state = nil
    @turn_number = nil
    @seat = 0
    @turn_data = nil
    @next_action = nil
    @last_action = nil
    @final_turn = nil
  end

  describe 'raises an exception' do
    it 'if the given action data does not have the proper format' do
      init_data do |action_data, result|
        ->() do
          @patient = AcpcPokerTypes::DealerData::HandData.new(
            @match_def,
            (action_data.data.first + [action_data.data.first.last]).flatten,
            result.data.first
          )
        end.must_raise AcpcPokerTypes::DealerData::HandData::InvalidData
      end
    end
  end

  it 'reports the chip distribution for every seat' do
    init_data do |action_data, result|
      @patient = AcpcPokerTypes::DealerData::HandData.new @match_def, action_data.data.first, result.data.first

      check_patient
    end
  end

  it 'works properly on every turn for every seat' do
    init_data do |action_data, result|
      @match_def.game_def.number_of_players.times do |seat|
        @seat = seat

        @last_match_state = nil
        @current_match_state = nil

        @last_action = nil
        @next_action = nil

        @patient = AcpcPokerTypes::DealerData::HandData.new @match_def, action_data.data.first, result.data.first

        @turn_number = 0
        @patient.for_every_turn!(@seat) do
          @final_turn = @turn_number >= @turn_data.length - 1

          @last_match_state = @current_match_state
          @current_match_state = @turn_data[@turn_number].state_messages[@seat]

          @last_action = @next_action
          @next_action = @turn_data[@turn_number].action_message

          check_patient

          @turn_number += 1
        end
      end
    end
  end

  def check_patient
    @patient.chip_distribution.must_equal @chip_distribution
    @patient.match_def.must_equal @match_def
    @patient.turn_number.must_equal @turn_number
    @patient.data.must_equal @turn_data
    @patient.seat.must_equal @seat
    @patient.current_match_state.must_equal @current_match_state
    @patient.last_match_state.must_equal @last_match_state
    @patient.next_action.must_equal @next_action
    @patient.last_action.must_equal @last_action
    @patient.final_turn?.must_equal @final_turn
  end

  def init_data
    data.each do |game, data_hash|
      @chip_distribution = data_hash[:chip_distribution]
      @turn_data = data_hash[:turn_data]
      @action_data = AcpcPokerTypes::DealerData::ActionMessages.parse(
        data_hash[:action_messages],
        data_hash[:player_names],
        AcpcDealer::DEALER_DIRECTORY
      )
      @hand_result = AcpcPokerTypes::DealerData::HandResults.parse(
        data_hash[:result_message],
        data_hash[:player_names],
        AcpcDealer::DEALER_DIRECTORY
      )
      @match_def = @hand_result.match_def

      yield @action_data, @hand_result
    end
  end

  def data
    {
      two_player_limit: {
        action_messages: [
          "# name/game/hands/seed 2p.limit.h1000.r0 holdem.limit.2p.reverse_blinds.game 1000 0\n",
          "TO 1 at 1341696000.058613 MATCHSTATE:1:999:crc/cc/cc/:|TdQd/As6d6h/7h/4s\n",
          "TO 2 at 1341696000.058634 MATCHSTATE:0:999:crc/cc/cc/:Jc8d|/As6d6h/7h/4s\n",
          "FROM 2 at 1341696000.058641 MATCHSTATE:0:999:crc/cc/cc/:Jc8d|/As6d6h/7h/4s:r\n",
          "TO 1 at 1341696000.058664 MATCHSTATE:1:999:crc/cc/cc/r:|TdQd/As6d6h/7h/4s\n",
          "TO 2 at 1341696000.058681 MATCHSTATE:0:999:crc/cc/cc/r:Jc8d|/As6d6h/7h/4s\n",
          "FROM 1 at 1341696000.058688 MATCHSTATE:1:999:crc/cc/cc/r:|TdQd/As6d6h/7h/4s:c\n",
          "TO 1 at 1341696000.058712 MATCHSTATE:1:999:crc/cc/cc/rc:Jc8d|TdQd/As6d6h/7h/4s\n",
          "TO 2 at 1341696000.058732 MATCHSTATE:0:999:crc/cc/cc/rc:Jc8d|TdQd/As6d6h/7h/4s\n",
          "FINISHED at 1341696000.058664\n",
          'SCORE:455|-455:p1|p2'
        ],
        result_message: [
          "# name/game/hands/seed 2p.limit.h1000.r0 holdem.limit.2p.reverse_blinds.game 1000 0\n",
          "STATE:999:crc/cc/cc/rc:Jc8d|TdQd/As6d6h/7h/4s:-60|60:p2|p1\n"
        ],
        chip_distribution: [60, -60],
        player_names:  ['p1', 'p2'],
        turn_data: [
          AcpcPokerTypes::DealerData::HandData::Turn.new(
            [
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999:crc/cc/cc/:|TdQd/As6d6h/7h/4s'),
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:999:crc/cc/cc/:Jc8d|/As6d6h/7h/4s')
            ],
            AcpcPokerTypes::DealerData::ActionMessages::FromMessage.new(
              1,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:999:crc/cc/cc/:Jc8d|/As6d6h/7h/4s'),
              AcpcPokerTypes::PokerAction.new('r')
            )
          ),
          AcpcPokerTypes::DealerData::HandData::Turn.new(
            [
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999:crc/cc/cc/r:|TdQd/As6d6h/7h/4s'),
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:999:crc/cc/cc/r:Jc8d|/As6d6h/7h/4s')
            ],
            AcpcPokerTypes::DealerData::ActionMessages::FromMessage.new(
              0,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999:crc/cc/cc/r:|TdQd/As6d6h/7h/4s'),
              AcpcPokerTypes::PokerAction.new('c')
            )
          ),
          AcpcPokerTypes::DealerData::HandData::Turn.new(
            [
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999:crc/cc/cc/rc:Jc8d|TdQd/As6d6h/7h/4s'),
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:999:crc/cc/cc/rc:Jc8d|TdQd/As6d6h/7h/4s')
            ],
            nil
          )
        ]
      },
      two_player_nolimit: {
        action_messages: [
          "# name/game/hands/seed 2p.nolimit.h1000.r0 holdem.nolimit.2p.reverse_blinds.game 1000 0\n",
          "TO 1 at 1341695921.617268 MATCHSTATE:1:999::|TdQd\n",
          "TO 2 at 1341695921.617309 MATCHSTATE:0:999::Jc8d|\n",
          "FROM 1 at 1341695921.617324 MATCHSTATE:1:999::|TdQd:f\n",
          "TO 1 at 1341695921.617377 MATCHSTATE:1:999:f:|TdQd\n",
          "TO 2 at 1341695921.617415 MATCHSTATE:0:999:f:Jc8d|\n",
          "FINISHED at 1341695921.617268\n",
          "SCORE:-64658|64658:p1|p2"
        ],
        result_message: [
          "# name/game/hands/seed 2p.nolimit.h1000.r0 holdem.nolimit.2p.reverse_blinds.game 1000 0\n",
          "STATE:999:crc/cc/cc/rc:Jc8d|TdQd/As6d6h/7h/4s:-19718|19718:p2|p1\n"
        ],
        chip_distribution: [19718, -19718],
        player_names:  ['p1', 'p2'],
        turn_data: [
          AcpcPokerTypes::DealerData::HandData::Turn.new(
            [
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999::|TdQd'),
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:999::Jc8d|')
            ],
            AcpcPokerTypes::DealerData::ActionMessages::FromMessage.new(
              0,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999::|TdQd'),
              AcpcPokerTypes::PokerAction.new('f')
            )
          ),
          AcpcPokerTypes::DealerData::HandData::Turn.new(
            [
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999:f:|TdQd'),
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:999:f:Jc8d|')
            ],
            nil
          )
        ]
      },
      three_player_limit: {
        action_messages: [
          "# name/game/hands/seed 3p.limit.h1000.r0 holdem.limit.3p.game 1000 0\n",
          "TO 1 at 1341696046.871086 MATCHSTATE:0:999:ccc/ccc/rrcc/rrrfr:QsAs||/4d6d2d/5d/2c\n",
          "TO 2 at 1341696046.871128 MATCHSTATE:1:999:ccc/ccc/rrcc/rrrfr:|3s8h|/4d6d2d/5d/2c\n",
          "TO 3 at 1341696046.871175 MATCHSTATE:2:999:ccc/ccc/rrcc/rrrfr:||Qd3c/4d6d2d/5d/2c\n",
          "FROM 3 at 1341696046.871201 MATCHSTATE:2:999:ccc/ccc/rrcc/rrrfr:||Qd3c/4d6d2d/5d/2c:c\n",
          "TO 1 at 1341696046.871245 MATCHSTATE:0:999:ccc/ccc/rrcc/rrrfrc:QsAs|3s8h|Qd3c/4d6d2d/5d/2c\n",
          "TO 2 at 1341696046.871267 MATCHSTATE:1:999:ccc/ccc/rrcc/rrrfrc:|3s8h|Qd3c/4d6d2d/5d/2c\n",
          "TO 3 at 1341696046.871313 MATCHSTATE:2:999:ccc/ccc/rrcc/rrrfrc:|3s8h|Qd3c/4d6d2d/5d/2c\n",
          "FINISHED at 1341696046.871175\n",
          "SCORE:-4330|625|3705:p1|p2|p3"
        ],
        result_message: [
          "# name/game/hands/seed 3p.limit.h1000.r0 holdem.limit.3p.game 1000 0\n",
          "STATE:999:ccc/rrcrcrcc/rcrrcc/crcrcrcrfc:Kd2d|6c2s|8hTh/2c4h9s/Ad/As:360|-190|-170:p1|p2|p3\n"
        ],
        chip_distribution: [360, -190, -170],
        player_names:  ['p1', 'p2', 'p3'],
        turn_data: [
          AcpcPokerTypes::DealerData::HandData::Turn.new(
            [
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:999:ccc/ccc/rrcc/rrrfr:QsAs||/4d6d2d/5d/2c'),
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999:ccc/ccc/rrcc/rrrfr:|3s8h|/4d6d2d/5d/2c'),
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:2:999:ccc/ccc/rrcc/rrrfr:||Qd3c/4d6d2d/5d/2c')
            ],
            AcpcPokerTypes::DealerData::ActionMessages::FromMessage.new(
              2,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:2:999:ccc/ccc/rrcc/rrrfr:||Qd3c/4d6d2d/5d/2c'),
              AcpcPokerTypes::PokerAction.new('c')
            )
          ),
          AcpcPokerTypes::DealerData::HandData::Turn.new(
            [
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:999:ccc/ccc/rrcc/rrrfrc:QsAs|3s8h|Qd3c/4d6d2d/5d/2c'),
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999:ccc/ccc/rrcc/rrrfrc:|3s8h|Qd3c/4d6d2d/5d/2c'),
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:2:999:ccc/ccc/rrcc/rrrfrc:|3s8h|Qd3c/4d6d2d/5d/2c')
            ],
            nil
          )
        ]
      },
      three_player_nolimit: {
        action_messages: [
          "# name/game/hands/seed 3p.nolimit.h1000.r0 holdem.nolimit.3p.game 1000 0\n",
          "TO 1 at 1341715420.129997 MATCHSTATE:0:999:ccr12926r20000c:QsAs||\n",
          "TO 2 at 1341715420.130034 MATCHSTATE:1:999:ccr12926r20000c:|3s8h|\n",
          "TO 3 at 1341715420.130070 MATCHSTATE:2:999:ccr12926r20000c:||Qd3c\n",
          "FROM 2 at 1341715420.130093 MATCHSTATE:1:999:ccr12926r20000c:|3s8h|:c\n",
          "TO 1 at 1341715420.130156 MATCHSTATE:0:999:ccr12926r20000cc///:QsAs|3s8h|Qd3c/4d6d2d/5d/2c\n",
          "TO 2 at 1341715420.130191 MATCHSTATE:1:999:ccr12926r20000cc///:QsAs|3s8h|Qd3c/4d6d2d/5d/2c\n",
          "TO 3 at 1341715420.130225 MATCHSTATE:2:999:ccr12926r20000cc///:QsAs|3s8h|Qd3c/4d6d2d/5d/2c\n",
          "FINISHED at 1341715420.130034\n",
          "SCORE:684452|552584.5|-1237036.5:p1|p2|p3"
        ],
        result_message: [
          "# name/game/hands/seed 3p.nolimit.h1000.r0 holdem.nolimit.3p.game 1000 0\n",
          "STATE:999:ccc/ccc/r4881cr14955cr20000cc/:Kd2d|6c2s|8hTh/2c4h9s/Ad/As:40000|-20000|-20000:p1|p2|p3\n",
        ],
        chip_distribution: [40000, -20000, -20000],
        player_names:  ['p1', 'p2', 'p3'],
        turn_data: [
          AcpcPokerTypes::DealerData::HandData::Turn.new(
            [
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:999:ccr12926r20000c:QsAs||'),
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999:ccr12926r20000c:|3s8h|'),
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:2:999:ccr12926r20000c:||Qd3c')
            ],
            AcpcPokerTypes::DealerData::ActionMessages::FromMessage.new(
              1,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999:ccr12926r20000c:|3s8h|'),
              AcpcPokerTypes::PokerAction.new('c')
            )
          ),
          AcpcPokerTypes::DealerData::HandData::Turn.new(
            [
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:999:ccr12926r20000cc///:QsAs|3s8h|Qd3c/4d6d2d/5d/2c'),
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999:ccr12926r20000cc///:QsAs|3s8h|Qd3c/4d6d2d/5d/2c'),
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:2:999:ccr12926r20000cc///:QsAs|3s8h|Qd3c/4d6d2d/5d/2c')
            ],
            nil
          )
        ]
      }
    }
  end
end
