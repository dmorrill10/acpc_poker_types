# Spec helper (must include first to track code coverage with SimpleCov)
require_relative '../support/spec_helper'

require 'mocha/setup'

require 'acpc_dealer'
require 'acpc_poker_types/match_state'
require 'acpc_poker_types/poker_action'

require 'acpc_poker_types/acpc_dealer_data/action_messages'
require 'acpc_poker_types/acpc_dealer_data/match_definition'
require 'acpc_poker_types/acpc_dealer_data/log_file'

describe AcpcPokerTypes::AcpcDealerData::ActionMessages do
  before do
    @data = nil
    @final_score = nil
    @patient = nil
    @match_def = nil
    @player_names = nil
    @no_final_score = false
  end

  describe '::parse_to_message' do
    it 'properly parses a ACPC log "TO . . ." line' do
      [
        "TO 1 at 1341695999.222281 MATCHSTATE:0:0::5d5c|\n" =>
          AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
            0,
            AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:0::5d5c|')
          ),
        "TO 2 at 1341695920.914907 MATCHSTATE:1:0:r19686:|9hQd\n" =>
          AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
            1,
            AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:0:r19686:|9hQd')
          ),
        "TO 3 at 1341696044.566738 MATCHSTATE:2:0:rf:||8dAs\n" =>
          AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
            2,
            AcpcPokerTypes::MatchState.parse('MATCHSTATE:2:0:rf:||8dAs')
          ),
        "TO 1 at 1341715418.808925 MATCHSTATE:0:0:fcr17162:5d5c||\n" =>
          AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
            0,
            AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:0:fcr17162:5d5c||')
          )
      ].each do |to_message_to_data|
        to_message_to_data.each do |to_message, expected_values|
          AcpcPokerTypes::AcpcDealerData::ActionMessages.parse_to_message(to_message).must_equal expected_values
        end
      end
    end
    it 'returns nil if asked to parse an improperly formatted string' do
      AcpcPokerTypes::AcpcDealerData::ActionMessages.parse_to_message("improperly formatted string").must_be_nil
    end
  end

  describe '::parse_from_message' do
    it 'properly parses a ACPC log "FROM . . ." line' do
      [
        "FROM 2 at 1341695999.222410 MATCHSTATE:1:0::|9hQd:c\n" =>
          AcpcPokerTypes::AcpcDealerData::ActionMessages::FromMessage.new(
            1,
            AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:0::|9hQd'),
            AcpcPokerTypes::PokerAction.new('c')
          ),
        "FROM 1 at 1341695920.914935 MATCHSTATE:0:0:r19686:5d5c|:r20000\n" =>
          AcpcPokerTypes::AcpcDealerData::ActionMessages::FromMessage.new(
            0,
            AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:0:r19686:5d5c|'),
            AcpcPokerTypes::PokerAction.new('r20000')
          ),
        "FROM 3 at 1341696044.566938 MATCHSTATE:2:0:rfr:||8dAs:r\n" =>
          AcpcPokerTypes::AcpcDealerData::ActionMessages::FromMessage.new(
            2,
            AcpcPokerTypes::MatchState.parse('MATCHSTATE:2:0:rfr:||8dAs'),
            AcpcPokerTypes::PokerAction.new('r')
          ),
        "FROM 2 at 1341715418.808896 MATCHSTATE:1:0:fc:|9hQd|:r17162\n" =>
          AcpcPokerTypes::AcpcDealerData::ActionMessages::FromMessage.new(
            1,
            AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:0:fc:|9hQd|'),
            AcpcPokerTypes::PokerAction.new('r17162')
          )
      ].each do |from_message_to_data|
        from_message_to_data.each do |from_message, expected_values|
          AcpcPokerTypes::AcpcDealerData::ActionMessages.parse_from_message(from_message).must_equal expected_values
        end
      end
    end
    it 'returns nil if asked to parse an improperly formatted string' do
      AcpcPokerTypes::AcpcDealerData::ActionMessages.parse_from_message("improperly formatted string").must_be_nil
    end
  end

  describe '::parse_score' do
    it 'properly parses a ACPC log "SCORE. . ." line' do
      [
        "SCORE:100|-100:p1|p2\n" => {p1: 100, p2: -100},
        'SCORE:19835|621.5|-20455.5:p1|p2|p3' => {p1: 19835, p2: 621.5, p3: -20455.5}
      ].each do |score_to_player_results|
        score_to_player_results.each do |score_string, expected_values|
          AcpcPokerTypes::AcpcDealerData::ActionMessages.parse_score(score_string).must_equal expected_values
        end
      end
    end
    it 'returns nil if asked to parse an improperly formatted string' do
      AcpcPokerTypes::AcpcDealerData::ActionMessages.parse_score("improperly formatted string").must_be_nil
    end
  end

  describe 'properly parses ACPC log statements' do
    describe 'from file' do
      it 'when every hand is desired' do
        init_data do |action_messages|
          file_name = 'file_name'
          AcpcPokerTypes::AcpcDealerData::LogFile.expects(:open).with(file_name, 'r').yields(
            action_messages
          ).returns(
            AcpcPokerTypes::AcpcDealerData::ActionMessages.parse(
              action_messages,
              @player_names,
              AcpcDealer::DEALER_DIRECTORY
            )
          )

          @patient = AcpcPokerTypes::AcpcDealerData::ActionMessages.parse_file(
            file_name,
            @player_names,
            AcpcDealer::DEALER_DIRECTORY
          )

          check_patient
        end
      end
      it 'when a particular number of hands is desired' do
        @no_final_score = true
        num_hands = 1
        init_data do |action_messages|
          file_name = 'file_name'
          AcpcPokerTypes::AcpcDealerData::LogFile.expects(:open).with(file_name, 'r').yields(
            action_messages
          ).returns(
            AcpcPokerTypes::AcpcDealerData::ActionMessages.parse(
              action_messages,
              @player_names,
              AcpcDealer::DEALER_DIRECTORY,
              num_hands
            )
          )

          @patient = AcpcPokerTypes::AcpcDealerData::ActionMessages.parse_file(
            file_name,
            @player_names,
            AcpcDealer::DEALER_DIRECTORY,
            num_hands
          )

          # Fix data to check patient against
          @final_score = nil
          @data = @data[0..num_hands-1]

          check_patient
        end
      end
    end
    describe 'from array' do
      it 'when all hands are desired' do
        init_data do |action_messages|
          @patient = AcpcPokerTypes::AcpcDealerData::ActionMessages.parse(
            action_messages,
            @player_names,
            AcpcDealer::DEALER_DIRECTORY
          )

          check_patient
        end
      end
      it 'when a particular number of hands is desired' do
        @no_final_score = true
        num_hands = 1
        init_data do |log_statements|
          @patient = AcpcPokerTypes::AcpcDealerData::ActionMessages.parse(
            log_statements,
            @player_names,
            AcpcDealer::DEALER_DIRECTORY,
            num_hands
          )

          # Fix data to check patient against
          @final_score = nil
          @data = @data[0..num_hands-1]

          check_patient
        end
      end
    end
  end

  def check_patient
    @patient.data.must_equal @data
    @patient.final_score.must_equal @final_score unless @no_final_score
    @patient.match_def.must_equal @match_def
  end

  def init_data
    all_data.each do |game, data_hash|
      @final_score = data_hash[:final_score]
      @data = data_hash[:data]
      @player_names = data_hash[:player_names]
      @match_def = AcpcPokerTypes::AcpcDealerData::MatchDefinition.parse(
        data_hash[:action_messages].first,
        @player_names,
        AcpcDealer::DEALER_DIRECTORY
      )

      yield data_hash[:action_messages]
    end
  end

  def all_data
    {
      two_player_limit: {
        action_messages: [
          "# name/game/hands/seed 2p.limit.h1000.r0 holdem.limit.2p.reverse_blinds.game 1000 0\n",
          "TO 1 at 1341696000.058613 MATCHSTATE:1:998:crc/cc/cc/:|TdQd/As6d6h/7h/4s\n",
          "TO 2 at 1341696000.058634 MATCHSTATE:0:998:crc/cc/cc/:Jc8d|/As6d6h/7h/4s\n",
          "FROM 2 at 1341696000.058641 MATCHSTATE:0:998:crc/cc/cc/:Jc8d|/As6d6h/7h/4s:r\n",
          "TO 1 at 1341696000.058664 MATCHSTATE:1:999:crc/cc/cc/r:|TdQd/As6d6h/7h/4s\n",
          "TO 2 at 1341696000.058681 MATCHSTATE:0:999:crc/cc/cc/r:Jc8d|/As6d6h/7h/4s\n",
          "FROM 1 at 1341696000.058688 MATCHSTATE:1:999:crc/cc/cc/r:|TdQd/As6d6h/7h/4s:c\n",
          "TO 1 at 1341696000.058712 MATCHSTATE:1:999:crc/cc/cc/rc:Jc8d|TdQd/As6d6h/7h/4s\n",
          "TO 2 at 1341696000.058732 MATCHSTATE:0:999:crc/cc/cc/rc:Jc8d|TdQd/As6d6h/7h/4s\n",
          "FINISHED at 1341696000.058664\n",
          'SCORE:455|-455:p1|p2'
        ],
        data: [
          [
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              0,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:998:crc/cc/cc/:|TdQd/As6d6h/7h/4s')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              1,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:998:crc/cc/cc/:Jc8d|/As6d6h/7h/4s')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::FromMessage.new(
              1,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:998:crc/cc/cc/:Jc8d|/As6d6h/7h/4s'),
              AcpcPokerTypes::PokerAction.new('r')
            )
          ],
          [
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              0,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999:crc/cc/cc/r:|TdQd/As6d6h/7h/4s')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              1,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:999:crc/cc/cc/r:Jc8d|/As6d6h/7h/4s')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::FromMessage.new(
              0,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999:crc/cc/cc/r:|TdQd/As6d6h/7h/4s'),
              AcpcPokerTypes::PokerAction.new('c')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              0,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999:crc/cc/cc/rc:Jc8d|TdQd/As6d6h/7h/4s')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              1,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:999:crc/cc/cc/rc:Jc8d|TdQd/As6d6h/7h/4s')
            )
          ]
        ],
        final_score: {p1: 455, p2: -455},
        player_names: ['p1', 'p2']
      },
      two_player_nolimit: {
        action_messages: [
          "# name/game/hands/seed 2p.nolimit.h1000.r0 holdem.nolimit.2p.reverse_blinds.game 1000 0\n",
          "TO 1 at 1341695921.617099 MATCHSTATE:0:998:cc/r5841r19996r20000:Kc6h|/QhAh8d\n",
          "TO 2 at 1341695921.617126 MATCHSTATE:1:998:cc/r5841r19996r20000:|Qc3s/QhAh8d\n",
          "FROM 2 at 1341695921.617133 MATCHSTATE:1:998:cc/r5841r19996r20000:|Qc3s/QhAh8d:c\n",
          "TO 1 at 1341695921.617182 MATCHSTATE:0:998:cc/r5841r19996r20000c//:Kc6h|Qc3s/QhAh8d/Th/9d\n",
          "TO 2 at 1341695921.617224 MATCHSTATE:1:998:cc/r5841r19996r20000c//:Kc6h|Qc3s/QhAh8d/Th/9d\n",
          "TO 1 at 1341695921.617268 MATCHSTATE:1:999::|TdQd\n",
          "TO 2 at 1341695921.617309 MATCHSTATE:0:999::Jc8d|\n",
          "FROM 1 at 1341695921.617324 MATCHSTATE:1:999::|TdQd:f\n",
          "TO 1 at 1341695921.617377 MATCHSTATE:1:999:f:|TdQd\n",
          "TO 2 at 1341695921.617415 MATCHSTATE:0:999:f:Jc8d|\n",
          "FINISHED at 1341695921.617268\n",
          "SCORE:-64658|64658:p1|p2"
        ],
        data: [
          [
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              0,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:998:cc/r5841r19996r20000:Kc6h|/QhAh8d')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              1,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:998:cc/r5841r19996r20000:|Qc3s/QhAh8d')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::FromMessage.new(
              1,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:998:cc/r5841r19996r20000:|Qc3s/QhAh8d:c'),
              AcpcPokerTypes::PokerAction.new('c')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              0,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:998:cc/r5841r19996r20000c//:Kc6h|Qc3s/QhAh8d/Th/9d')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              1,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:998:cc/r5841r19996r20000c//:Kc6h|Qc3s/QhAh8d/Th/9d')
            )
          ],
          [
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              0,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999::|TdQd')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              1,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:999::Jc8d|')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::FromMessage.new(
              0,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999::|TdQd'),
              AcpcPokerTypes::PokerAction.new('f')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              0,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999:f:|TdQd')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              1,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:999:f:Jc8d|')
            )
          ]
        ],
        final_score: {p1: -64658, p2: 64658},
        player_names: ['p1', 'p2']
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
        data: [
          [
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              0,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:999:ccc/ccc/rrcc/rrrfr:QsAs||/4d6d2d/5d/2c')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              1,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999:ccc/ccc/rrcc/rrrfr:|3s8h|/4d6d2d/5d/2c')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              2,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:2:999:ccc/ccc/rrcc/rrrfr:||Qd3c/4d6d2d/5d/2c')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::FromMessage.new(
              2,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:2:999:ccc/ccc/rrcc/rrrfr:||Qd3c/4d6d2d/5d/2c'),
              AcpcPokerTypes::PokerAction.new('c')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              0,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:999:ccc/ccc/rrcc/rrrfrc:QsAs|3s8h|Qd3c/4d6d2d/5d/2c')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              1,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999:ccc/ccc/rrcc/rrrfrc:|3s8h|Qd3c/4d6d2d/5d/2c')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              2,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:2:999:ccc/ccc/rrcc/rrrfrc:|3s8h|Qd3c/4d6d2d/5d/2c')
            )
          ]
        ],
        final_score: {p1: -4330, p2: 625, p3: 3705},
        player_names: ['p1', 'p2', 'p3']
      },
      three_player_nolimit: {
        action_messages: [
          "# name/game/hands/seed 3p.nolimit.h1000.r0 holdem.nolimit.3p.game 1000 0\n",
          "TO 1 at 1341715420.129997 MATCHSTATE:0:998:ccr12926r20000c:QsAs||\n",
          "TO 2 at 1341715420.130034 MATCHSTATE:1:998:ccr12926r20000c:|3s8h|\n",
          "TO 3 at 1341715420.130070 MATCHSTATE:2:998:ccr12926r20000c:||Qd3c\n",
          "FROM 2 at 1341715420.130093 MATCHSTATE:1:998:ccr12926r20000c:|3s8h|:c\n",
          "TO 1 at 1341715420.130156 MATCHSTATE:0:999:ccr12926r20000cc///:QsAs|3s8h|Qd3c/4d6d2d/5d/2c\n",
          "TO 2 at 1341715420.130191 MATCHSTATE:1:999:ccr12926r20000cc///:QsAs|3s8h|Qd3c/4d6d2d/5d/2c\n",
          "TO 3 at 1341715420.130225 MATCHSTATE:2:999:ccr12926r20000cc///:QsAs|3s8h|Qd3c/4d6d2d/5d/2c\n",
          "FINISHED at 1341715420.130034\n",
          "SCORE:684452|552584.5|-1237036.5:p1|p2|p3"
        ],
        data: [
          [
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              0,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:998:ccr12926r20000c:QsAs||')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              1,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:998:ccr12926r20000c:|3s8h|')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              2,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:2:998:ccr12926r20000c:||Qd3c')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::FromMessage.new(
              1,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:998:ccr12926r20000c:|3s8h|'),
              AcpcPokerTypes::PokerAction.new('c')
            )
          ],
          [
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              0,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:0:999:ccr12926r20000cc///:QsAs|3s8h|Qd3c/4d6d2d/5d/2c')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              1,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:1:999:ccr12926r20000cc///:QsAs|3s8h|Qd3c/4d6d2d/5d/2c')
            ),
            AcpcPokerTypes::AcpcDealerData::ActionMessages::ToMessage.new(
              2,
              AcpcPokerTypes::MatchState.parse('MATCHSTATE:2:999:ccr12926r20000cc///:QsAs|3s8h|Qd3c/4d6d2d/5d/2c')
            )
          ]
        ],
        final_score: {p1: 684452, p2: 552584.5, p3: -1237036.5},
        player_names: ['p1', 'p2', 'p3']
      }
    }
  end
end
