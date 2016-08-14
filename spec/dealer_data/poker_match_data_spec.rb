# Spec helper (must include first to track code coverage with SimpleCov)
require_relative '../support/spec_helper'

require 'celluloid/current'
require 'celluloid/test'
require 'celluloid/essentials'

require 'mocha/setup'

require 'acpc_dealer'
require 'acpc_poker_types/match_state'
require 'acpc_poker_types/poker_action'

require 'acpc_poker_types/dealer_data/hand_data'
require 'acpc_poker_types/dealer_data/match_definition'
require 'acpc_poker_types/dealer_data/poker_match_data'

include AcpcPokerTypes
include AcpcPokerTypes::DealerData

describe PokerMatchData do
  before do
    @patient = nil
    @chip_distribution = nil
    @match_def = nil
    @match_def_line_index = nil
    @player_names = nil
    @hand_number = nil
    @hand_data_list = nil
    @final_hand = nil
    @no_chip_distribution = false

    if defined? Celluloid
      Celluloid.boot
    end
  end

  after do
    if defined? Celluloid
      Celluloid.shutdown
    end
  end

  describe 'when given action and result messages' do
    describe 'raises an exception if' do
      it 'match definitions do not match' do
        init_data! do |action_messages, result_messages|
          new_action_messages = action_messages.dup
          new_action_messages[@match_def_line_index] = '# name/game/hands/seed different_name holdem.limit.2p.reverse_blinds.game 2 0\n'

          ->() do
            PokerMatchData.parse(
              new_action_messages,
              result_messages,
              @player_names,
              AcpcDealer::DEALER_DIRECTORY
            )
          end.must_raise PokerMatchData::MatchDefinitionsDoNotMatch

          new_result_messages = result_messages.dup
          new_result_messages[@match_def_line_index] = '# name/game/hands/seed different_name holdem.limit.2p.reverse_blinds.game 2 0\n'

          ->() do
            PokerMatchData.parse(
              action_messages,
              new_result_messages,
              @player_names,
              AcpcDealer::DEALER_DIRECTORY
            )
          end.must_raise PokerMatchData::MatchDefinitionsDoNotMatch
        end
      end
      it 'the final scores from each set of messages do not match' do
        init_data! do |action_messages, result_messages|
          new_action_messages = action_messages.dup
          new_action_messages.pop
          new_action_messages.pop
          new_action_messages << 'SCORE:9001|-9001:p1|p2'

          ->() do
            PokerMatchData.parse(
              new_action_messages,
              result_messages,
              @player_names,
              AcpcDealer::DEALER_DIRECTORY
            )
          end.must_raise PokerMatchData::FinalScoresDoNotMatch

          new_result_messages = result_messages.dup
          new_result_messages.pop
          new_result_messages.pop
          new_result_messages << 'SCORE:9001|-9001:p1|p2'

          ->() do
            PokerMatchData.parse(
              action_messages,
              new_result_messages,
              @player_names,
              AcpcDealer::DEALER_DIRECTORY
            )
          end.must_raise PokerMatchData::FinalScoresDoNotMatch
        end
      end
    end
    describe 'works properly' do
      it 'for every hand' do
        init_data! do |action_messages, result_messages|

          @patient = PokerMatchData.parse(
            action_messages,
            result_messages,
            @player_names,
            AcpcDealer::DEALER_DIRECTORY
          )
          @patient.seat = 0

          @hand_number = 0
          @patient.for_every_hand! do
            @turn_number = 0

            @final_hand = @hand_number >= @hand_data_list.length - 1
            @patient.for_every_turn! do
              check_patient

              @turn_number += 1
            end

            @hand_number += 1
          end
        end
      end
      it 'for a particular number of hands' do
        num_hands = 1
        @no_chip_distribution = true
        init_data!(num_hands) do |action_messages, result_messages|
          @chip_distribution = nil

          @patient = PokerMatchData.parse(
            action_messages,
            result_messages,
            @player_names,
            AcpcDealer::DEALER_DIRECTORY,
            num_hands
          )
          @patient.seat = 0

          @hand_number = 0
          @patient.for_every_hand! do
            @turn_number = 0

            @final_hand = @hand_number >= @hand_data_list.length - 1
            @patient.for_every_turn! do
              check_patient

              @turn_number += 1
            end

            @hand_number += 1
          end
        end
      end
    end
  end
  describe '#player_acting_sequence' do
    describe "doesn't append an empty array to the list when all but one player has folded" do
      it 'in two player' do
        action_messages =
          "# name/game/hands/seed 2p.limit.h1000.r0 holdem.limit.2p.reverse_blinds.game 1 0
          #--t_response 600000
          #--t_hand 600000
          #--t_per_hand 7000
          STARTED at 1341695999.222081
          TO 1 at 1341695999.222281 MATCHSTATE:0:0::5d5c|
          TO 2 at 1341695999.222349 MATCHSTATE:1:0::|9hQd
          FROM 2 at 1341695999.222281 MATCHSTATE:0:0::5d5c|:c
          TO 1 at 1341695999.222281 MATCHSTATE:0:0:c:5d5c|
          TO 2 at 1341695999.222349 MATCHSTATE:1:0:c:|9hQd
          FROM 1 at 1341695999.222349 MATCHSTATE:1:0:cr:|9hQd:r
          TO 1 at 1341695999.222281 MATCHSTATE:0:0:cr:5d5c|
          TO 2 at 1341695999.222349 MATCHSTATE:1:0:cr:|9hQd
          FROM 2 at 1341695999.222281 MATCHSTATE:0:0:cr:5d5c:f
          TO 1 at 1341695999.222281 MATCHSTATE:0:0:crf:5d5c|
          TO 2 at 1341695999.222349 MATCHSTATE:1:0:crf:|9hQd
          SCORE:-20|20:p1|p2".split("\n").map {|line| line += "\n" }

        result_messages = [
          "# name/game/hands/seed 2p.limit.h1000.r0 holdem.limit.2p.reverse_blinds.game 1 0\n",
          "#--t_response 600000\n",
          "#--t_hand 600000\n",
          "#--t_per_hand 7000\n",
          "STATE:0:crf:5d5c|9hQd:-20|20:p1|p2\n",
          'SCORE:-20|20:p1|p2'
        ]
        player_acting_sequence = [[1, 0, 1]]
        @patient = PokerMatchData.parse(
          action_messages,
          result_messages,
          ['p1', 'p2'],
          AcpcDealer::DEALER_DIRECTORY
        )

        @patient.hand_number = 0
        @patient.current_hand.turn_number = 3
        @patient.player_acting_sequence.must_equal player_acting_sequence
      end
      it 'in three player' do
        action_messages =
          "# name/game/hands/seed 3p.limit.h1000.r0 holdem.limit.3p.game 1 0
          #--t_response 600000
          #--t_hand 600000
          #--t_per_hand 7000
          STARTED at 1341695999.222081
          TO 1 at 1341695999.222281 MATCHSTATE:0:0::5d5c||
          TO 2 at 1341695999.222349 MATCHSTATE:1:0::|9hQd|
          TO 3 at 1341695999.222349 MATCHSTATE:3:0::||9cQh
          FROM 1 at 1341695999.222281 MATCHSTATE:0:0::5d5c||:r
          TO 1 at 1341695999.222281 MATCHSTATE:0:0:r:5d5c||
          TO 2 at 1341695999.222349 MATCHSTATE:1:0:r:|9hQd|
          TO 3 at 1341695999.222349 MATCHSTATE:3:0:r:||9cQh
          FROM 2 at 1341695999.222349 MATCHSTATE:1:0:r:|9hQd|:f
          TO 1 at 1341695999.222281 MATCHSTATE:0:0:rf:5d5c||
          TO 2 at 1341695999.222349 MATCHSTATE:1:0:rf:|9hQd|
          TO 3 at 1341695999.222349 MATCHSTATE:3:0:rf:||9cQh
          FROM 3 at 1341695999.222349 MATCHSTATE:3:0:rf:||9cQh:f
          TO 1 at 1341695999.222281 MATCHSTATE:0:0:rff:5d5c||
          TO 2 at 1341695999.222349 MATCHSTATE:1:0:rff:|9hQd|
          TO 3 at 1341695999.222349 MATCHSTATE:3:0:rff:||9cQh
          SCORE:20|-20|-20:p1|p2|p3".split("\n").map {|line| line += "\n" }

        result_messages = [
          "# name/game/hands/seed 3p.limit.h1000.r0 holdem.limit.3p.game 1 0\n",
          "#--t_response 600000\n",
          "#--t_hand 600000\n",
          "#--t_per_hand 7000\n",
          "STATE:0:cff:5d5c|9hQd|9cQh:20|-20|-20:p1|p2|p3\n",
          'SCORE:20|-20|-20:p1|p2|p3'
        ]
        player_acting_sequence = [[0, 1, 2]]
        @patient = PokerMatchData.parse(
          action_messages,
          result_messages,
          ['p1', 'p2', 'p3'],
          AcpcDealer::DEALER_DIRECTORY
        )

        @patient.hand_number = 0
        @patient.current_hand.turn_number = 3
        @patient.player_acting_sequence.must_equal player_acting_sequence
      end
    end
    describe "appends an empty array to the list whenever a new round is encountered" do
      it 'in two player' do
        action_messages =
          "# name/game/hands/seed 2p.nolimit.h1000.r0 /home/dmorrill/.rvm/gems/ruby-1.9.3-p194/gems/acpc_dealer-0.0.1/vendor/project_acpc_server/holdem.nolimit.2p.reverse_blinds.game 1000 0
          #--t_response 600000
          #--t_hand 600000
          #--t_per_hand 7000
          STARTED at 1341695920.914516
          TO 1 at 1341695920.914700 MATCHSTATE:0:0::5d5c|
          TO 2 at 1341695920.914745 MATCHSTATE:1:0::|9hQd
          FROM 2 at 1341695920.914807 MATCHSTATE:1:0::|9hQd:r19686
          TO 1 at 1341695920.914864 MATCHSTATE:0:0:r19686:5d5c|
          TO 2 at 1341695920.914907 MATCHSTATE:1:0:r19686:|9hQd
          FROM 1 at 1341695920.914935 MATCHSTATE:0:0:r19686:5d5c|:r20000
          TO 1 at 1341695920.914988 MATCHSTATE:0:0:r19686r20000:5d5c|
          TO 2 at 1341695920.915032 MATCHSTATE:1:0:r19686r20000:|9hQd
          FROM 2 at 1341695920.915073 MATCHSTATE:1:0:r19686r20000:|9hQd:c
          TO 1 at 1341695920.915193 MATCHSTATE:0:0:r19686r20000c///:5d5c|9hQd/8dAs8s/4h/6d
          TO 2 at 1341695920.915232 MATCHSTATE:1:0:r19686r20000c///:5d5c|9hQd/8dAs8s/4h/6d
          SCORE:20000|-20000:p1|p2".split("\n").map {|line| line += "\n" }

        result_messages =
          "# name/game/hands/seed 2p.nolimit.h1000.r0 /home/dmorrill/.rvm/gems/ruby-1.9.3-p194/gems/acpc_dealer-0.0.1/vendor/project_acpc_server/holdem.nolimit.2p.reverse_blinds.game 1000 0
          #--t_response 600000
          #--t_hand 600000
          #--t_per_hand 7000
          STATE:0:r19686r20000c///:5d5c|9hQd/8dAs8s/4h/6d:20000|-20000:p1|p2
          SCORE:20000|-20000:p1|p2".split("\n").map {|line| line += "\n" }

        player_acting_sequence = [[1, 0, 1], [], [], []]
        @patient = PokerMatchData.parse(
          action_messages,
          result_messages,
          ['p1', 'p2'],
          AcpcDealer::DEALER_DIRECTORY
        )

        @patient.hand_number = 0
        @patient.current_hand.turn_number = @patient.current_hand.data.length - 1
        @patient.player_acting_sequence.must_equal player_acting_sequence
      end
    end
  end

  def check_patient
    @patient.match_def.must_equal @match_def
    @patient.chip_distribution.must_equal @chip_distribution unless @no_chip_distribution
    @patient.hand_number.must_equal @hand_number
    @patient.current_hand.must_equal @hand_data_list[@hand_number]
    @patient.final_hand?.must_equal @final_hand
    @patient.player_acting_sequence.must_equal @player_acting_sequences[@hand_number] if @turn_number + 1 == @hand_data_list[@hand_number].data.length
  end

  def init_data!(num_hands=nil)
    data.each do |game, data_hash|
      @chip_distribution = data_hash[:chip_distribution]
      @match_def_line_index = data_hash[:match_def_line_index]
      @player_names = data_hash[:player_names]
      @match_def = MatchDefinition.parse(
        data_hash[:result_messages][@match_def_line_index],
        @player_names,
        AcpcDealer::DEALER_DIRECTORY
      )
      init_expected!(data_hash, num_hands, @match_def)

      @player_acting_sequences = data_hash[:player_acting_sequences]

      yield data_hash[:action_messages], data_hash[:result_messages]
    end
    self
  end

  def init_expected!(data_hash, num_hands=nil, match_def=@match_def)
    action_messages = ActionMessages.parse(
      data_hash[:action_messages],
      @player_names,
      AcpcDealer::DEALER_DIRECTORY,
      num_hands
    )
    result_messages = HandResults.parse(
      data_hash[:result_messages],
      @player_names,
      AcpcDealer::DEALER_DIRECTORY,
      num_hands
    )

    @hand_data_list = []
    action_messages.data.zip(result_messages.data)
      .each do |action_messages_by_hand, hand_result|
      @hand_data_list << HandData.new(
        match_def,
        action_messages_by_hand,
        hand_result
      )
    end
    self
  end

  def data
    {
      two_player_limit: {
        action_messages:
          "# name/game/hands/seed 2p.limit.h1000.r0 holdem.limit.2p.reverse_blinds.game 2 0
          #--t_response 600000
          #--t_hand 600000
          #--t_per_hand 7000
          STARTED at 1341695999.222081
          TO 1 at 1341695999.222281 MATCHSTATE:0:0::5d5c|
          TO 2 at 1341695999.222349 MATCHSTATE:1:0::|9hQd
          FROM 2 at 1341695999.222410 MATCHSTATE:1:0::|9hQd:c
          TO 1 at 1341695999.222450 MATCHSTATE:0:0:c:5d5c|
          TO 2 at 1341695999.222496 MATCHSTATE:1:0:c:|9hQd
          FROM 1 at 1341695999.222519 MATCHSTATE:0:0:c:5d5c|:c
          TO 1 at 1341695999.222546 MATCHSTATE:0:0:cc/:5d5c|/8dAs8s
          TO 2 at 1341695999.222583 MATCHSTATE:1:0:cc/:|9hQd/8dAs8s
          FROM 1 at 1341695999.222605 MATCHSTATE:0:0:cc/:5d5c|/8dAs8s:c
          TO 1 at 1341695999.222633 MATCHSTATE:0:0:cc/c:5d5c|/8dAs8s
          TO 2 at 1341695999.222664 MATCHSTATE:1:0:cc/c:|9hQd/8dAs8s
          FROM 2 at 1341695999.222704 MATCHSTATE:1:0:cc/c:|9hQd/8dAs8s:r
          TO 1 at 1341695999.222734 MATCHSTATE:0:0:cc/cr:5d5c|/8dAs8s
          TO 2 at 1341695999.222770 MATCHSTATE:1:0:cc/cr:|9hQd/8dAs8s
          FROM 1 at 1341695999.222792 MATCHSTATE:0:0:cc/cr:5d5c|/8dAs8s:c
          TO 1 at 1341695999.222820 MATCHSTATE:0:0:cc/crc/:5d5c|/8dAs8s/4h
          TO 2 at 1341695999.222879 MATCHSTATE:1:0:cc/crc/:|9hQd/8dAs8s/4h
          FROM 1 at 1341695999.222904 MATCHSTATE:0:0:cc/crc/:5d5c|/8dAs8s/4h:c
          TO 1 at 1341695999.222932 MATCHSTATE:0:0:cc/crc/c:5d5c|/8dAs8s/4h
          TO 2 at 1341695999.222964 MATCHSTATE:1:0:cc/crc/c:|9hQd/8dAs8s/4h
          FROM 2 at 1341695999.223004 MATCHSTATE:1:0:cc/crc/c:|9hQd/8dAs8s/4h:c
          TO 1 at 1341695999.223033 MATCHSTATE:0:0:cc/crc/cc/:5d5c|/8dAs8s/4h/6d
          TO 2 at 1341695999.223069 MATCHSTATE:1:0:cc/crc/cc/:|9hQd/8dAs8s/4h/6d
          FROM 1 at 1341695999.223091 MATCHSTATE:0:0:cc/crc/cc/:5d5c|/8dAs8s/4h/6d:c
          TO 1 at 1341695999.223118 MATCHSTATE:0:0:cc/crc/cc/c:5d5c|/8dAs8s/4h/6d
          TO 2 at 1341695999.223150 MATCHSTATE:1:0:cc/crc/cc/c:|9hQd/8dAs8s/4h/6d
          FROM 2 at 1341695999.223189 MATCHSTATE:1:0:cc/crc/cc/c:|9hQd/8dAs8s/4h/6d:c
          TO 1 at 1341695999.223272 MATCHSTATE:0:0:cc/crc/cc/cc:5d5c|9hQd/8dAs8s/4h/6d
          TO 2 at 1341695999.223307 MATCHSTATE:1:0:cc/crc/cc/cc:5d5c|9hQd/8dAs8s/4h/6d
          TO 1 at 1341695999.223333 MATCHSTATE:1:1::|5dJd
          TO 2 at 1341695999.223366 MATCHSTATE:0:1::6sKs|
          FROM 1 at 1341695999.223388 MATCHSTATE:1:1::|5dJd:c
          TO 1 at 1341695999.223415 MATCHSTATE:1:1:c:|5dJd
          TO 2 at 1341695999.223446 MATCHSTATE:0:1:c:6sKs|
          FROM 2 at 1341695999.223485 MATCHSTATE:0:1:c:6sKs|:r
          TO 1 at 1341695999.223513 MATCHSTATE:1:1:cr:|5dJd
          TO 2 at 1341695999.223548 MATCHSTATE:0:1:cr:6sKs|
          FROM 1 at 1341695999.223570 MATCHSTATE:1:1:cr:|5dJd:c
          TO 1 at 1341695999.223596 MATCHSTATE:1:1:crc/:|5dJd/2sTh2h
          TO 2 at 1341695999.223627 MATCHSTATE:0:1:crc/:6sKs|/2sTh2h
          FROM 2 at 1341695999.223664 MATCHSTATE:0:1:crc/:6sKs|/2sTh2h:r
          TO 1 at 1341695999.223692 MATCHSTATE:1:1:crc/r:|5dJd/2sTh2h
          TO 2 at 1341695999.223728 MATCHSTATE:0:1:crc/r:6sKs|/2sTh2h
          FROM 1 at 1341695999.223749 MATCHSTATE:1:1:crc/r:|5dJd/2sTh2h:c
          TO 1 at 1341695999.223776 MATCHSTATE:1:1:crc/rc/:|5dJd/2sTh2h/Qh
          TO 2 at 1341695999.223807 MATCHSTATE:0:1:crc/rc/:6sKs|/2sTh2h/Qh
          FROM 2 at 1341695999.223863 MATCHSTATE:0:1:crc/rc/:6sKs|/2sTh2h/Qh:r
          TO 1 at 1341695999.223897 MATCHSTATE:1:1:crc/rc/r:|5dJd/2sTh2h/Qh
          TO 2 at 1341695999.223934 MATCHSTATE:0:1:crc/rc/r:6sKs|/2sTh2h/Qh
          FROM 1 at 1341695999.223956 MATCHSTATE:1:1:crc/rc/r:|5dJd/2sTh2h/Qh:r
          TO 1 at 1341695999.223984 MATCHSTATE:1:1:crc/rc/rr:|5dJd/2sTh2h/Qh
          TO 2 at 1341695999.224015 MATCHSTATE:0:1:crc/rc/rr:6sKs|/2sTh2h/Qh
          FROM 2 at 1341695999.224053 MATCHSTATE:0:1:crc/rc/rr:6sKs|/2sTh2h/Qh:c
          TO 1 at 1341695999.224081 MATCHSTATE:1:1:crc/rc/rrc/:|5dJd/2sTh2h/Qh/8h
          TO 2 at 1341695999.224114 MATCHSTATE:0:1:crc/rc/rrc/:6sKs|/2sTh2h/Qh/8h
          FROM 2 at 1341695999.224149 MATCHSTATE:0:1:crc/rc/rrc/:6sKs|/2sTh2h/Qh/8h:r
          TO 1 at 1341695999.224178 MATCHSTATE:1:1:crc/rc/rrc/r:|5dJd/2sTh2h/Qh/8h
          TO 2 at 1341695999.224213 MATCHSTATE:0:1:crc/rc/rrc/r:6sKs|/2sTh2h/Qh/8h
          FROM 1 at 1341695999.224235 MATCHSTATE:1:1:crc/rc/rrc/r:|5dJd/2sTh2h/Qh/8h:c
          TO 1 at 1341695999.224292 MATCHSTATE:1:1:crc/rc/rrc/rc:6sKs|5dJd/2sTh2h/Qh/8h
          TO 2 at 1341695999.224329 MATCHSTATE:0:1:crc/rc/rrc/rc:6sKs|5dJd/2sTh2h/Qh/8h
          FINISHED at 1341696000.058664
          SCORE:-70|70:p1|p2
          ".split("\n").map { |line| line += "\n" }, # Make each line an element in an array while preserving newlines
        result_messages: [
          "# name/game/hands/seed 2p.limit.h1000.r0 holdem.limit.2p.reverse_blinds.game 2 0\n",
          "#--t_response 600000\n",
          "#--t_hand 600000\n",
          "#--t_per_hand 7000\n",
          "STATE:0:cc/crc/cc/cc:5d5c|9hQd/8dAs8s/4h/6d:20|-20:p1|p2\n",
          "STATE:1:crc/rc/rrc/rc:6sKs|5dJd/2sTh2h/Qh/8h:90|-90:p2|p1\n",
          'SCORE:-70|70:p1|p2'
        ],
        hand_start_line_indices: [6, 35],
        match_def_line_index: 0,
        player_names: ['p1', 'p2'],
        chip_distribution: [-70, 70],
        player_acting_sequences: [
          [
            [1, 0], [0, 1, 0], [0, 1], [0, 1]
          ],
          [
            [0, 1, 0], [1, 0], [1, 0, 1], [1, 0]
          ]
        ]
      }
    }
  end
end
