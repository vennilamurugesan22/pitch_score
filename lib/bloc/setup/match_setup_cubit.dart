// match_setup_cubit.dart

import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
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

  // Called after picking several people from contacts
  void addPlayers(List<Player> players) =>
      emit(state.copyWith(players: [...state.players, ...players]));

  // Called when user taps a player's team badge — move to the other team
  void togglePlayerTeam(String playerId) => emit(state.copyWith(
        players: state.players
            .map((p) => p.id == playerId
                ? Player(
                    id: p.id,
                    name: p.name,
                    teamId: p.teamId == 'team1' ? 'team2' : 'team1',
                  )
                : p)
            .toList(),
      ));

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

  // New code if the first one is already taken on Firebase
  void regenerateMatchCode() =>
      emit(state.copyWith(matchCode: _generateMatchCode()));

  // Random 6-digit code e.g. "482913" — digits only so spectators
  // can type it on the number keyboard
  String _generateMatchCode() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

}