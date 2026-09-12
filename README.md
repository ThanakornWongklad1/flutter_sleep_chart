# hypnogram_chart

A lightweight, dependency-free Flutter widget that renders an Apple
Health-style sleep stage chart from a list of sleep stage segments.

![hypnogram_chart example](https://raw.githubusercontent.com/ThanakornWongklad1/hypnogram_chart/main/screenshots/example.png)

## Features

- One row per stage (Awake / REM / Light / Deep, or any custom set), each a
  solid pill nested in its own glassy halo (a tint of the stage color
  blended with the surface — no transparency stacking artifacts)
- Gradient connector lines between stage transitions
- Adjacent same-stage segments merge into one continuous bar, no seam
- Minimum bar width clamp so brief real-world stage flips stay visible
  instead of shrinking to nothing
- Hover, tap, or press-and-drag anywhere over the chart — above, below, or
  on a row — for a scrub tooltip (stage, time range, duration), a
  stage-colored dot, and a dashed vertical guide line
- Fully configurable per-stage colors, labels, and row heights
- Fully configurable tooltip content and style, or swap in your own widget
- No dependencies beyond Flutter itself

## Getting started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  hypnogram_chart: ^<latest_version>
```

Import the package:

```dart
import 'package:hypnogram_chart/hypnogram_chart.dart';
```

## Usage

### Basic Implementation

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

### Advanced Usage with Custom Styling

```dart
HypnogramChart(
  segments: segments,
  stageStyles: const {
    SleepStageType.awake: StageStyle(color: Colors.orange, label: 'Awake'),
    SleepStageType.rem: StageStyle(color: Colors.purple, label: 'REM'),
    SleepStageType.light: StageStyle(color: Colors.blue, label: 'Light'),
    SleepStageType.deep: StageStyle(
      color: Colors.indigo,
      label: 'Deep',
      rowHeight: 52, // overrides the chart's default rowHeight for this row
    ),
  },
  rowHeight: 40, // default row height for stages without their own override
  barHeight: 20,
  haloPad: 2,
  minBarWidth: 1,
  labelColumnWidth: 64,
  tooltip: HypnogramTooltipConfig(
    // Override individual lines; omitted ones fall back to the defaults
    // (stage label, formatted clock range, formatted duration).
    durationText: (s) => '${s.duration.inMinutes} min',
    backgroundColor: Colors.black87,
    padding: const EdgeInsets.all(12),
    borderRadius: BorderRadius.circular(12),
    showColorDot: false,
    // Or replace the whole bubble:
    // builder: (context, segment) => MyCustomTooltip(segment),
  ),
)
```

Set `enableTooltip: false` to disable the scrub tooltip entirely.

## Parameters

### `HypnogramChart`

| Parameter | Description | Default | Required |
| :--- | :--- | :--- | :--- |
| `segments` | The sleep data to render | - | Yes |
| `stageStyles` | Color, label, and optional row height per stage. Map iteration order sets row order, top to bottom | `kDefaultHypnogramStageStyles` | No |
| `rowHeight` | Default row height for any stage whose `StageStyle.rowHeight` is `null` | `40` | No |
| `barHeight` | Height of the solid stage bar within its row | `20` | No |
| `haloPad` | Extra padding around each bar's tinted halo, in px | `2` | No |
| `minBarWidth` | Minimum rendered width for a segment, so brief stages stay visible | `1` | No |
| `labelColumnWidth` | Width reserved on the left for row labels | `64` | No |
| `enableTooltip` | Whether hover/tap/drag shows the scrub tooltip, guide line, and dot | `true` | No |
| `tooltip` | Content and style for the scrub tooltip — see `HypnogramTooltipConfig` below | `HypnogramTooltipConfig()` | No |
| `haloBackground` | Base color each stage's halo is blended toward (32% stage color / 68% this) | `null` (→ `ColorScheme.surface`) | No |

### `StageStyle`

| Parameter | Description | Default | Required |
| :--- | :--- | :--- | :--- |
| `color` | Bar and halo tint for this stage | - | Yes |
| `label` | Row label text, and the default tooltip stage line | - | Yes |
| `rowHeight` | Per-stage row height override — e.g. render Deep taller than the rest | `null` (→ chart's `rowHeight`) | No |

### `HypnogramTooltipConfig`

| Parameter | Description | Default | Required |
| :--- | :--- | :--- | :--- |
| `builder` | Full replacement for the tooltip bubble. When set, every other field below is ignored | `null` | No |
| `labelText` | Override the stage-name line | `null` (→ `StageStyle.label`) | No |
| `timeRangeText` | Override the time-range line | `null` (→ e.g. `11:00 PM – 11:40 PM`) | No |
| `durationText` | Override the duration line | `null` (→ e.g. `1h 20m`) | No |
| `backgroundColor` | Bubble fill color | `null` (→ `ColorScheme.inverseSurface`) | No |
| `labelStyle` | Text style for the stage-name line | bold, 12px, `onInverseSurface` | No |
| `detailStyle` | Text style for the time-range and duration lines | 11px, `onInverseSurface` at 85% opacity | No |
| `padding` | Inner padding of the bubble | `EdgeInsets.symmetric(horizontal: 10, vertical: 8)` | No |
| `borderRadius` | Corner radius of the bubble | `BorderRadius.circular(8)` | No |
| `shadow` | Drop shadow under the bubble. Pass `null` or `[]` to remove it | one soft shadow (16px blur, `(0, 6)` offset) | No |
| `showColorDot` | Whether the small stage-colored dot shows next to the stage-name line | `true` | No |

## Data Structure

### `SleepStageSegment`

```dart
class SleepStageSegment {
  final SleepStageType type; // Sleep stage for this block
  final DateTime start;      // Block start time
  final DateTime end;        // Block end time

  Duration get duration;     // end.difference(start)
}
```

### `SleepStageType`

```dart
enum SleepStageType { awake, rem, light, deep }
```

Not limited to these four rows — any subset (or an app-specific enum-like
set) works as long as `stageStyles` has an entry for every type your
`segments` use.

### Generate Sample Data

```dart
List<SleepStageSegment> generateSleepData() {
  final start = DateTime.now().subtract(const Duration(hours: 8));
  DateTime at(int minutes) => start.add(Duration(minutes: minutes));

  return [
    SleepStageSegment(type: SleepStageType.light, start: at(0), end: at(30)),
    SleepStageSegment(type: SleepStageType.deep, start: at(30), end: at(90)),
    // Add more stages...
  ];
}
```

## Important Notes

1. **Row order**: Determined entirely by `stageStyles`' map iteration order —
   there's no separate ordering param.
2. **Stage coverage**: `stageStyles` needs an entry for every `SleepStageType`
   present in `segments`, or that stage falls back to the halo background
   color and an empty label.
3. **Adjacent segments**: Same-stage segments that touch (`a.end == b.start`)
   are merged into one continuous bar before rendering — no visible seam,
   and the tooltip reports their combined duration.
4. **Tooltip positioning**: The bubble clamps inside the chart's own bounds
   and flips below the anchor row when there's no room above, so it never
   renders off-screen.
5. **`tooltip.builder`**: When set, it fully replaces the bubble —
   `labelText`/`timeRangeText`/`durationText`/style fields are ignored.
6. **Interaction**: Works via hover (desktop/web), tap, or press-and-drag
   (touch) — no separate touch-vs-mouse configuration needed.

## Example App

```dart
import 'package:flutter/material.dart';
import 'package:hypnogram_chart/hypnogram_chart.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('hypnogram_chart example')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: HypnogramChart(
            segments: generateSleepData(),
            stageStyles: const {
              SleepStageType.awake: StageStyle(color: Color(0xFFE0729C), label: 'Awake'),
              SleepStageType.rem: StageStyle(color: Color(0xFF8E6BD9), label: 'REM'),
              SleepStageType.light: StageStyle(color: Color(0xFF4F8FE8), label: 'Light'),
              SleepStageType.deep: StageStyle(color: Color(0xFF1F2B6B), label: 'Deep', rowHeight: 52),
            },
            tooltip: HypnogramTooltipConfig(
              backgroundColor: const Color(0xFF1A1A2E),
              durationText: (s) => '${s.duration.inMinutes} min',
            ),
          ),
        ),
      ),
    );
  }
}
```

See `example/lib/main.dart` for the actual runnable version, including a
fragmented micro-arousal cluster that exercises the minimum-bar-width clamp.

## Customization Tips

- **Color schemes**: Use complementary colors for different sleep stages so
  the halos read distinctly at a glance.
- **Row heights**: Give one stage (typically Deep) a taller `rowHeight` to
  draw the eye without changing the others.
- **Tooltip style**: Match `tooltip.backgroundColor`/`labelStyle` to your
  app's theme rather than relying on the `ColorScheme` defaults for a fully
  branded look.
- **Custom tooltip layout**: Reach for `tooltip.builder` when you need more
  than stage/time/duration — e.g. adding an icon or a secondary metric.
- **Accessibility**: Ensure sufficient color contrast between stages, and
  between `labelStyle`/`detailStyle` and your chosen `backgroundColor`.

## Requirements

- Flutter >=1.17.0
- Dart SDK ^3.12.2

## License

MIT License
