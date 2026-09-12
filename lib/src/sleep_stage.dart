/// Sleep stage categories used to render a hypnogram.
enum SleepStageType { awake, rem, light, deep }

/// A single contiguous block of sleep at one [type], from [start] to [end].
class SleepStageSegment {
  final SleepStageType type;
  final DateTime start;
  final DateTime end;

  const SleepStageSegment({
    required this.type,
    required this.start,
    required this.end,
  });

  Duration get duration => end.difference(start);
}
