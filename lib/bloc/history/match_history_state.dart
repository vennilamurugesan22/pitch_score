// match_history_state.dart

import 'package:equatable/equatable.dart';
import '../../models/match_model.dart';

abstract class MatchHistoryState extends Equatable {
  const MatchHistoryState();
  @override
  List<Object?> get props => [];
}

// Before any load has happened
class MatchHistoryInitial extends MatchHistoryState {}

// While reading from Hive — show a loading spinner
class MatchHistoryLoading extends MatchHistoryState {}

// Hive read success — matches list is ready to display
class MatchHistoryLoaded extends MatchHistoryState {
  final List<Match> matches;
  const MatchHistoryLoaded(this.matches);
  @override
  List<Object?> get props => [matches];
}

// Something went wrong reading Hive
class MatchHistoryError extends MatchHistoryState {
  final String message;
  const MatchHistoryError(this.message);
  @override
  List<Object?> get props => [message];
}