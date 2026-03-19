// match_setup_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../models/player_model.dart';
import 'match_setup_state.dart';

// Cubit is a simpler version of BLoC
// Use Cubit when you don't need complex events — just simple function calls
// MatchSetup is simple: user fills a form, we update state field by field
class MatchSetupCubit extends Cubit<MatchSetupState> {
  MatchSetupCubit() : super(const MatchSetupState());

  // Called every time user types in Team 1 name field
  void updateTeamOneName(String name) =>
      emit(state.copyWith(teamOneName: name));

  // Called every time user types in Team 2 name field
  void updateTeamTwoName(String name) =>
      emit(state.copyWith(teamTwoName: name));

  // Called when user taps an overs chip (5, 6, 8, 10, 20)
  void updateOvers(int overs) =>
      emit(state.copyWith(totalOvers: overs));

  void updateMaxWickets(int wickets) =>
      emit(state.copyWith(maxWickets: wickets));

  // Called when user adds a player from contacts or manually
  // Spread operator [...] creates new list — never mutate existing list in BLoC
  void addPlayer(Player player) =>
      emit(state.copyWith(players: [...state.players, player]));

  // Called when user removes a player
  void removePlayer(String playerId) =>
      emit(state.copyWith(
        players: state.players.where((p) => p.id != playerId).toList(),
      ));

  // Called when user toggles Live Mode switch
  // If turning ON → generate a match code
  // If turning OFF → clear the match code
  void toggleLiveMode(bool value) {
    final code = value ? _generateMatchCode() : '';
    emit(state.copyWith(isLiveMode: value, matchCode: code));
  }

  // Generate a random 6-character uppercase code
  // uuid().v4() gives something like "a1b2c3d4-e5f6-..."
  // We take first 6 chars and uppercase: "A1B2C3"
  String _generateMatchCode() {
    const uuid = Uuid();
    return uuid.v4().substring(0, 6).toUpperCase();
  }

  // Validation — both team names must be filled before starting match
  bool get isValid =>
      state.teamOneName.isNotEmpty && state.teamTwoName.isNotEmpty;
}