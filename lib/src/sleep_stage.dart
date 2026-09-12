/// Sleep stage categories used to render a hypnogram.
///
/// [asleep] is a coarse fallback for data sources that only distinguish
/// "asleep" from "awake" without REM/Light/Deep detail — use it in place of
/// [rem]/[light]/[deep], not alongside them. Give it a `StageStyle` with
/// `spanRows: [rem, light, deep]` to render it as a gradient spanning those
/// rows' combined height instead of its own row.
///
/// [inBed] is the overall in-bed span (e.g. bedtime to out-of-bed time) —
/// an ordinary stage type with its own row, independent of [asleep] and the
/// finer stages. No special rendering; a segment of type [inBed] just
/// renders like any other.
enum SleepStageType { awake, rem, light, deep, asleep, inBed }

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
