# hypnogram_chart

A lightweight, dependency-free Flutter widget that renders an Apple
Health-style sleep stage chart from a list of sleep stage segments.

## Features

- One row per stage (Awake / REM / Light / Deep), each a solid pill nested
  in its own glassy halo (a tint of the stage color blended with the
  surface — no transparency stacking artifacts)
- Gradient connector lines between stage transitions
- Adjacent same-stage segments merge into one continuous bar, no seam
- Minimum bar width clamp so brief real-world stage flips stay visible
  instead of shrinking to nothing
- Hover, tap, or press-and-drag anywhere over the chart — above, below, or
  on a row — for a scrub tooltip (stage, time range, duration), a
  stage-colored dot, and a dashed vertical guide line
- No dependencies beyond Flutter itself

## Usage

```dart
final segments = [
  SleepStageSegment(
    type: SleepStageType.light,
    start: DateTime(2026, 1, 1, 23),
    end: DateTime(2026, 1, 1, 23, 40),
  ),
  SleepStageSegment(
    type: SleepStageType.deep,
    start: DateTime(2026, 1, 1, 23, 40),
    end: DateTime(2026, 1, 2, 0, 30),
  ),
];

HypnogramChart(segments: segments)
```

See `example/` for a full runnable app, including a fragmented
micro-arousal cluster that exercises the minimum-bar-width clamp.

## Additional information

Contributions and issues welcome.
