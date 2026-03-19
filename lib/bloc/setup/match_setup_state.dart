// match_setup_state.dart

import 'package:equatable/equatable.dart';
import '../../models/player_model.dart';

// Holds all the data the scorer fills in before the match starts
// MatchSetupCubit reads and writes this state
class MatchSetupState extends Equatable {
  final String teamOneName;
  final String teamTwoName;

  // How many overs per innings — scorer picks this
  final int totalOvers;

  // Max wickets — usually 10, but gully cricket might use 5 or 6
  final int maxWickets;

  // All players from both teams combined in one list
  // Each Player has a teamId field ('team1' or 'team2') to know which team
  final List<Player> players;

  // true = Firebase sync enabled, false = offline only
  final bool isLiveMode;

  // 6-digit code generated when isLiveMode is true
  // e.g. "CR4829" — scorer shares this on WhatsApp
  final String matchCode;

  const MatchSetupState({
    this.teamOneName = '',
    this.teamTwoName = '',
    this.totalOvers = 6,
    this.maxWickets = 10,
    this.players = const [],
    this.isLiveMode = false,
    this.matchCode = '',
  });

  MatchSetupState copyWith({
    String? teamOneName,
    String? teamTwoName,
    int? totalOvers,
    int? maxWickets,
    List<Player>? players,
    bool? isLiveMode,
    String? matchCode,
  }) {
    return MatchSetupState(
      teamOneName: teamOneName ?? this.teamOneName,
      teamTwoName: teamTwoName ?? this.teamTwoName,
      totalOvers: totalOvers ?? this.totalOvers,
      maxWickets: maxWickets ?? this.maxWickets,
      players: players ?? this.players,
      isLiveMode: isLiveMode ?? this.isLiveMode,
      matchCode: matchCode ?? this.matchCode,
    );
  }

  @override
  List<Object?> get props => [
        teamOneName, teamTwoName, totalOvers,
        maxWickets, players, isLiveMode, matchCode,
      ];
}