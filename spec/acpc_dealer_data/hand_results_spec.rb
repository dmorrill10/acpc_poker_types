# Spec helper (must include first to track code coverage with SimpleCov)
require_relative '../support/spec_helper'

require 'mocha/setup'

require 'acpc_dealer'

require 'acpc_poker_types/acpc_dealer_data/hand_results'
require 'acpc_poker_types/acpc_dealer_data/match_definition'

describe AcpcPokerTypes::AcpcDealerData::HandResults do
  before do
    @patient = nil
    @data = nil
    @final_score = nil
    @player_names = nil
    @match_def = nil
    @no_final_score = false
  end

  describe '::parse_state' do
    it 'properly parses a ACPC log "STATE. . ." line' do
      [
        "STATE:0:rc/rrrrc/rc/crrrc:5d5c|9hQd/8dAs8s/4h/6d:28|-28:p1|p2\n" =>
          {p1: 28, p2: -28},
        "STATE:9:cc/cc/r165c/cc:4cKh|Kd7d/Ah9h9c/6s/Ks:0|0:p1|p2\n" =>
          {p1: 0, p2: 0},
        "STATE:18:rfrrc/cc/rrc/rrrrc:5d5c|9hQd|8dAs/8s4h6d/5s/Js:-5|-160|165:p1|p2|p3\n" =>
          {p1: -5, p2: -160, p3: 165},
        "STATE:1:cr13057cr20000cc///:Ks6h|Qs5d|Tc4d/Ah3dTd/8c/Qd:-20000|40000|-20000:p2|p3|p1\n" =>
          {p1: -20000, p2: -20000, p3: 40000}
      ].each do |state_to_player_results|
        state_to_player_results.each do |state_string, expected_values|
          AcpcPokerTypes::AcpcDealerData::HandResults.parse_state(state_string).must_equal expected_values
        end
      end
    end
    it 'returns nil if asked to parse an improperly formatted string' do
      AcpcPokerTypes::AcpcDealerData::HandResults.parse_state("improperly formatted string").must_be_nil
    end
  end
  describe '::parse_score' do
    it 'properly parses a ACPC log "SCORE. . ." line' do
      [
        "SCORE:100|-100:p1|p2\n" => {p1: 100, p2: -100},
        'SCORE:19835|621.5|-20455.5:p1|p2|p3' => {p1: 19835, p2: 621.5, p3: -20455.5}
      ].each do |score_to_player_results|
        score_to_player_results.each do |score_string, expected_values|
          AcpcPokerTypes::AcpcDealerData::HandResults.parse_score(score_string).must_equal expected_values
        end
      end
    end
    it 'returns nil if asked to parse an improperly formatted string' do
      AcpcPokerTypes::AcpcDealerData::HandResults.parse_score("improperly formatted string").must_be_nil
    end
  end

  describe 'properly parses ACPC log statements' do
    describe 'from file' do
      it 'when every hand is desired' do
        init_data do |log_statements|
          file_name = 'file_name'
          AcpcPokerTypes::AcpcDealerData::LogFile.stubs(:open).with(file_name, 'r').yields(
            log_statements
          ).returns(
            AcpcPokerTypes::AcpcDealerData::HandResults.parse(
              log_statements,
              @player_names,
              AcpcDealer::DEALER_DIRECTORY
            )
          )

          @patient = AcpcPokerTypes::AcpcDealerData::HandResults.parse_file(
            file_name,
            @player_names,
            AcpcDealer::DEALER_DIRECTORY
          )

          check_patient
        end
      end
      it 'when a particular number of hands is desired' do
        @no_final_score = true
        num_hands = 3
        init_data do |log_statements|
          file_name = 'file_name'
          AcpcPokerTypes::AcpcDealerData::LogFile.stubs(:open).with(file_name, 'r').yields(
            log_statements
          ).returns(
            AcpcPokerTypes::AcpcDealerData::HandResults.parse(
              log_statements,
              @player_names,
              AcpcDealer::DEALER_DIRECTORY,
              num_hands
            )
          )

          @patient = AcpcPokerTypes::AcpcDealerData::HandResults.parse_file(
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
      it 'when every hand is desired' do
        init_data do |log_statements|
          @patient = AcpcPokerTypes::AcpcDealerData::HandResults.parse(
            log_statements,
            @player_names,
            AcpcDealer::DEALER_DIRECTORY
          )

          check_patient
        end
      end
      it 'when a particular number of hands is desired' do
        @no_final_score = true
        num_hands = 3
        init_data do |log_statements|
          @patient = AcpcPokerTypes::AcpcDealerData::HandResults.parse(
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
        data_hash[:log_statements].first,
        @player_names,
        AcpcDealer::DEALER_DIRECTORY
      )

      yield data_hash[:log_statements]
    end
  end

  def all_data
    {
      two_player_limit: {
        log_statements: [
          "# name/game/hands/seed 2p.limit.h1000.r0 holdem.limit.2p.reverse_blinds.game 1000 0\n",
          "STATE:0:crrrc/rrc/rf:3s5d|Td2s/4d5c4s/Kd:60|-60:p1|p2\n",
          "STATE:1:rc/crrrrc/rrc/rc:7d5s|Kh9c/As3hTs/Jh/Js:-120|120:p2|p1\n",
          "STATE:2:cc/cc/rc/rc:Kh6h|As2h/Qd2c2d/7d/3d:-50|50:p1|p2\n",
          "STATE:3:cc/rrrc/rc/rc:8c7d|QcKc/Ac6hTd/9h/3d:80|-80:p2|p1\n",
          "STATE:4:rf:6s9d|4dQd:-10|10:p1|p2\n",
          "STATE:5:cc/crc/cc/cc:6c2d|9cKs/4dKc7d/Td/Ah:-20|20:p2|p1\n",
          "STATE:6:rrrc/rc/cc/rc:9h7h|3d8s/JcAc5c/Ah/Ks:70|-70:p1|p2\n",
          "STATE:7:rrrf:5s9c|8dJh:-30|30:p2|p1\n",
          "STATE:8:rrrc/cc/rc/rrc:Kc6h|Qc3s/QhAh8d/Th/9d:-100|100:p1|p2\n",
          "STATE:9:crc/cc/cc/rc:Jc8d|TdQd/As6d6h/7h/4s:-40|40:p2|p1\n",
          'SCORE:100|-100:p1|p2'
        ],
        data: [
          {p1: 60, p2: -60},
          {p1: 120, p2: -120},
          {p1: -50, p2: 50},
          {p1: -80, p2: 80},
          {p1: -10, p2: 10},
          {p1: 20, p2: -20},
          {p1: 70, p2: -70},
          {p1: 30, p2: -30},
          {p1: -100, p2: 100},
          {p1: 40, p2: -40}
        ],
        final_score: {p1: 100, p2: -100},
        player_names: ['p1', 'p2']
      },
      two_player_nolimit: {
        log_statements: [
          "# name/game/hands/seed 2p.nolimit.h1000.r0 holdem.nolimit.2p.reverse_blinds.game 1000 0\n",
          "STATE:0:r5924c/r17356c/cc/r19718c:3s5d|Td2s/4d5c4s/Kd/2c:19718|-19718:p1|p2\n",
          "STATE:1:cc/r7485r16652c/r17998r19429r20000c/:7d5s|Kh9c/As3hTs/Jh/Js:-20000|20000:p2|p1\n",
          "STATE:2:r18810c/r19264r19774c/cr19995r20000c/:Kh6h|As2h/Qd2c2d/7d/3d:-20000|20000:p1|p2\n",
          "STATE:3:cr281c/r18446r20000c//:8c7d|QcKc/Ac6hTd/9h/3d:20000|-20000:p2|p1\n",
          "STATE:4:r13583r20000f:6s9d|4dQd:13583|-13583:p1|p2\n",
          "STATE:5:cc/r15416f:6c2d|9cKs/4dKc7d:100|-100:p2|p1\n",
          "STATE:6:r15542r20000c///:9h7h|3d8s/JcAc5c/Ah/Ks:20000|-20000:p1|p2\n",
          "STATE:7:r1147c/cc/cr5404f:5s9c|8dJh/TdQc9d/Jd:-1147|1147:p2|p1\n",
          "STATE:8:cc/r5841r19996r20000c//:Kc6h|Qc3s/QhAh8d/Th/9d:-20000|20000:p1|p2\n",
          "STATE:9:f:Jc8d|TdQd:50|-50:p2|p1\n",
          'SCORE:14298|-14298:p1|p2'
        ],
        data: [
          {p1: 19718, p2: -19718},
          {p1: 20000, p2: -20000},
          {p1: -20000, p2: 20000},
          {p1: -20000, p2: 20000},
          {p1: 13583, p2: -13583},
          {p1: -100, p2: 100},
          {p1: 20000, p2: -20000},
          {p1: 1147, p2: -1147},
          {p1: -20000, p2: 20000},
          {p1: -50, p2: 50}
        ],
        final_score: {p1: 14298, p2: -14298},
        player_names: ['p1', 'p2']
      },
      three_player_limit: {
        log_statements: [
          "# name/game/hands/seed 3p.limit.h1000.r0 holdem.limit.3p.game 1000 0\n",
          "STATE:0:ccc/rrcrcrcc/rcrrcc/crcrcrcrfc:Kd2d|6c2s|8hTh/2c4h9s/Ad/As:360|-190|-170:p1|p2|p3\n",
          "STATE:1:rrcrcc/rrrcf/rrrrc/cc:Td7s|4c5s|Qc4s/5dAd7c/6c/2c:210|-60|-150:p2|p3|p1\n",
          "STATE:2:fcc/crc/crrc/rrc:Jh9d|8hAh|As6c/3dKc3c/2d/Kh:-100|100|0:p3|p1|p2\n",
          "STATE:3:rcrcrcf/rc/cc/rc:Qd2h|5c4d|6s2d/As8s6d/7d/2c:-70|100|-30:p1|p2|p3\n",
          "STATE:4:rrcc/rrrrcf/rrc/rc:8d4c|6sQd|Ts2s/2d9hTh/8c/5h:190|-130|-60:p2|p3|p1\n",
          "STATE:5:rrrcc/crrfrrc/crc/cc:7cKh|3s2h|Js4h/KcQc2s/5h/4s:-40|-100|140:p3|p1|p2\n",
          "STATE:6:rrcrcc/rrrcc/ccrrcrcrcc/crrrrfc:QhQd|3cQc|2cTh/Jc8hTs/9c/3s:95|95|-190:p1|p2|p3\n",
          "STATE:7:crrcrcc/crrfrc/cc/rrc:Qd2s|KdTs|6dQh/6h6sTc/3h/Jd:-40|-110|150:p2|p3|p1\n",
          "STATE:8:frc/cc/rc/rrc:6hKc|6cAd|6d2c/QdTd9h/7h/Jc:80|-80|0:p3|p1|p2\n",
          "STATE:9:ccc/ccc/rrcc/rrrfrc:QsAs|3s8h|Qd3c/4d6d2d/5d/2c:-70|-130|200:p1|p2|p3\n",
          'SCORE:105|375|-550:p1|p2|p3'
        ],
        data: [
          {p1: 360, p2: -190, p3: -170},
          {p1: -150, p2: 210, p3: -60},
          {p1: 100, p2: 0, p3: -100},
          {p1: -70, p2: 100, p3: -30},
          {p1: -60, p2: 190, p3: -130},
          {p1: -100, p2: 140, p3: -40},
          {p1: 95, p2: 95, p3: -190},
          {p1: 150, p2: -40, p3: -110},
          {p1: -80, p2: 0, p3: 80},
          {p1: -70, p2: -130, p3: 200}
        ],
        final_score: {p1: 105, p2: 375, p3: -550},
        player_names: ['p1', 'p2', 'p3']
      },
      three_player_nolimit: {
        log_statements: [
          "# name/game/hands/seed 3p.nolimit.h1000.r0 holdem.nolimit.3p.game 1000 0\n",
          "STATE:0:ccc/ccc/r4881cr14955cr20000cc/:Kd2d|6c2s|8hTh/2c4h9s/Ad/As:40000|-20000|-20000:p1|p2|p3\n",
          "STATE:1:ccc/cr7400r17645r20000cc//:Td7s|4c5s|Qc4s/5dAd7c/6c/2c:40000|-20000|-20000:p2|p3|p1\n",
          "STATE:2:r7187r19832cc/cr19953fc/cr20000c/:Jh9d|8hAh|As6c/3dKc3c/2d/Kh:-20000|39832|-19832:p3|p1|p2\n",
          "STATE:3:r3610cr8213r19531r20000cc///:Qd2h|5c4d|6s2d/As8s6d/7d/2c:-20000|40000|-20000:p1|p2|p3\n",
          "STATE:4:fcc/r1348c/r8244r18929r20000c/:8d4c|6sQd|Ts2s/2d9hTh/8c/5h:20000|-20000|0:p2|p3|p1\n",
          "STATE:5:r15492cc/ccr17275cc/r19597cc/r19947cf:7cKh|3s2h|Js4h/KcQc2s/5h/4s:39544|-19947|-19597:p3|p1|p2\n",
          "STATE:6:r10322fc/r10577r18645r20000c//:QhQd|3cQc|2cTh/Jc8hTs/9c/3s:-50|20050|-20000:p1|p2|p3\n",
          "STATE:7:ccr8533r17298r20000cc///:Qd2s|KdTs|6dQh/6h6sTc/3h/Jd:-20000|-20000|40000:p2|p3|p1\n",
          "STATE:8:cr18231r20000cc///:6hKc|6cAd|6d2c/QdTd9h/7h/Jc:40000|-20000|-20000:p3|p1|p2\n",
          "STATE:9:ccr12926r20000cc///:QsAs|3s8h|Qd3c/4d6d2d/5d/2c:-20000|-20000|40000:p1|p2|p3\n",
          'SCORE:19835|621|-20456:p1|p2|p3'
        ],
        data: [
          {p1: 40000, p2: -20000, p3: -20000},
          {p1: -20000, p2: 40000, p3: -20000},
          {p1: 39832, p2: -19832, p3: -20000},
          {p1: -20000, p2: 40000, p3: -20000},
          {p1: 0, p2: 20000, p3: -20000},
          {p1: -19947, p2: -19597, p3: 39544},
          {p1: -50, p2: 20050, p3: -20000},
          {p1: 40000, p2: -20000, p3: -20000},
          {p1: -20000, p2: -20000, p3: 40000},
          {p1: -20000, p2: -20000, p3: 40000}
        ],
        final_score: {p1: 19835, p2: 621, p3: -20456},
        player_names: ['p1', 'p2', 'p3']
      }
    }
  end
end
