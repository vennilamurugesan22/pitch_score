// match_history_event.dart

import 'package:equatable/equatable.dart';
import '../../models/match_model.dart';

abstract class MatchHistoryEvent extends Equatable {
  const MatchHistoryEvent();
  @override
  List<Object?> get props => [];
}

// Fired when History screen opens — load all saved matches from Hive
class LoadHistoryEvent extends MatchHistoryEvent {
  const LoadHistoryEvent();
}

// Fired when match ends and scorer taps Save — store match to Hive
class SaveMatchEvent extends MatchHistoryEvent {
  final Match match;
  const SaveMatchEvent(this.match);
  @override
  List<Object?> get props => [match];
}

// Fired when user swipes to delete a match from history
class DeleteMatchEvent extends MatchHistoryEvent {
  final String matchId;
  const DeleteMatchEvent(this.matchId);
  @override
  List<Object?> get props => [matchId];
}