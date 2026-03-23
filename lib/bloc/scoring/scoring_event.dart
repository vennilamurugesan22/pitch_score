import 'package:equatable/equatable.dart';
import '../../models/ball_model.dart';

// Abstract class = base class for ALL scoring events
// Think of events as "actions the user does"
// Every button tap on the scoring screen = one event
abstract class ScoringEvent extends Equatable {
  const ScoringEvent();

  @override
  List<Object?> get props => [];
}

// Fired when scorer taps any button — 0, 1, 2, 3, 4, 6, W, Wd, NB, LB
// The Ball object carries all the info about what happened
class AddBallEvent extends ScoringEvent {
  final Ball ball;
  const AddBallEvent(this.ball);

  // props tells Equatable which fields to use for comparison
  // Important for BLoC to detect if same event fired twice
  @override
  List<Object?> get props => [ball];
}

// Fired when scorer taps the Undo button
// No extra data needed — just remove the last ball
class UndoBallEvent extends ScoringEvent {
  const UndoBallEvent();
}

// Fired when a wicket falls and scorer picks the new batsman
// batsmanId = the id of the new batsman coming in
class SelectBatsmanEvent extends ScoringEvent {
  final String batsmanId;
  const SelectBatsmanEvent(this.batsmanId);

  @override
  List<Object?> get props => [batsmanId];
}

// Fired when an over is complete and scorer picks next bowler
class SelectBowlerEvent extends ScoringEvent {
  final String bowlerId;
  const SelectBowlerEvent(this.bowlerId);

  @override
  List<Object?> get props => [bowlerId];
}

// Fired when innings ends — either all overs done or all wickets fallen
// or scorer manually taps "End Innings"
class EndInningsEvent extends ScoringEvent {
  const EndInningsEvent();
}




// Fired after scorer taps W and fills the wicket popup
// dismissalType = "caught" / "bowled" / "runout" / "lbw" / "stumped" / "hitwicket"
// newBatsmanId = player selected from the list to come in next
class WicketDetailEvent extends ScoringEvent {
  final String dismissalType;
  final String newBatsmanId;

  const WicketDetailEvent({
    required this.dismissalType,
    required this.newBatsmanId,
  });

  @override
  List<Object?> get props => [dismissalType, newBatsmanId];
}

// In scoring_event.dart
class NewBowlerSelectedEvent extends ScoringEvent {
  final String bowlerId;
  const NewBowlerSelectedEvent(this.bowlerId);

  @override
  List<Object?> get props => [bowlerId];
}