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

// Fired when scorer taps any button — 0, 1, 2, 3, 4, 6, W, Wd, NB, B, LB
// The Ball object carries all the info about what happened
// newBatsmanId = who comes in if this ball is a wicket
class AddBallEvent extends ScoringEvent {
  final Ball ball;
  final String? newBatsmanId;
  const AddBallEvent(this.ball, {this.newBatsmanId});

  @override
  List<Object?> get props => [ball, newBatsmanId];
}

// Fired when the scorer taps Undo — remove the last ball
class UndoBallEvent extends ScoringEvent {
  const UndoBallEvent();
}

// Start of each innings — pick the two openers and opening bowler
class SetOpenersEvent extends ScoringEvent {
  final String strikerId;
  final String nonStrikerId;
  final String bowlerId;

  const SetOpenersEvent({
    required this.strikerId,
    required this.nonStrikerId,
    required this.bowlerId,
  });

  @override
  List<Object?> get props => [strikerId, nonStrikerId, bowlerId];
}

// Fired when an over is complete and scorer picks next bowler
class NewBowlerSelectedEvent extends ScoringEvent {
  final String bowlerId;
  const NewBowlerSelectedEvent(this.bowlerId);

  @override
  List<Object?> get props => [bowlerId];
}

// Manual fix — scorer swaps who is on strike
class SwapStrikeEvent extends ScoringEvent {
  const SwapStrikeEvent();
}

// Scorer ends the innings early (rain, declared, everyone has to go home)
class EndInningsEvent extends ScoringEvent {
  const EndInningsEvent();
}

// From innings break screen — begin the chase
class StartSecondInningsEvent extends ScoringEvent {
  const StartSecondInningsEvent();
}

// Scorer confirms the result at the end of the 2nd innings
class FinishMatchEvent extends ScoringEvent {
  const FinishMatchEvent();
}

// Scorer turns on live sharing mid-match (match was started offline)
class EnableLiveSharingEvent extends ScoringEvent {
  final String matchCode;
  const EnableLiveSharingEvent(this.matchCode);

  @override
  List<Object?> get props => [matchCode];
}
