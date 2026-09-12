# flutter_sleep_chart

A lightweight, dependency-free Flutter widget that renders an Apple
Health-style sleep stage chart from a list of sleep stage segments.

![flutter_sleep_chart example](https://raw.githubusercontent.com/ThanakornWongklad1/flutter_sleep_chart/main/screenshots/example.png)

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
- `onSegmentTap` callback, an optional hour-aligned time axis, optional row
  and time grid lines, and a `.tap`-only interaction mode for use inside
  scrollable/draggable parents
- Bars animate in on first render and whenever `segments` changes
- A standalone `HypnogramLegend` widget for the same `stageStyles` map
- No dependencies beyond Flutter itself

## Getting started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_sleep_chart: ^<latest_version>
```

Import the package:

```dart
import 'package:flutter_sleep_chart/flutter_sleep_chart.dart';
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

### Time Axis, Grid Lines, Tap Callback, and Legend

```dart
HypnogramChart(
  segments: segments,
  onSegmentTap: (segment) => print('Tapped ${segment.type}'),
  showTimeAxis: true,
  showRowGridLines: true,
  showTimeGridLines: true,
  // Ignore drag/hover-move — only pointer-down selects a segment. Use this
  // if the chart sits inside a horizontally scrollable/draggable parent.
  interactionMode: HypnogramInteractionMode.tap,
)
```

`HypnogramLegend` reads the same `stageStyles` map, for composing a legend
outside the chart:

```dart
Column(
  children: [
    HypnogramChart(segments: segments, stageStyles: myStyles),
    HypnogramLegend(stageStyles: myStyles),
  ],
)
```

### Animation

Bars animate in on first render and whenever `segments` changes:

```dart
HypnogramChart(
  segments: segments,
  enableAnimation: true, // default
  animationDuration: const Duration(milliseconds: 450),
  animationCurve: Curves.easeOutCubic,
)
```

Set `enableAnimation: false` to render instantly instead.

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
| `interactionMode` | `scrub` (hover/tap/drag all update live) or `tap` (only pointer-down does) — see `HypnogramInteractionMode` below | `HypnogramInteractionMode.scrub` | No |
| `onSegmentTap` | Called with the segment under the pointer on every pointer-down | `null` | No |
| `showTimeAxis` | Shows hour-aligned clock labels below the chart | `false` | No |
| `timeAxisHeight` | Height reserved for `showTimeAxis`'s labels | `20` | No |
| `showRowGridLines` | Draws a horizontal divider line above each stage row | `false` | No |
| `showTimeGridLines` | Draws a vertical line at each hour-aligned tick | `false` | No |
| `gridLineColor` | Color for the grid lines above | `null` (→ faint tint of the text color) | No |
| `emptyBuilder` | Widget shown in place of the chart when `segments` is empty | `null` (→ blank box) | No |
| `enableAnimation` | Whether bars animate in on first render and on `segments` change | `true` | No |
| `animationDuration` | Duration of the reveal animation | `Duration(milliseconds: 450)` | No |
| `animationCurve` | Easing curve of the reveal animation | `Curves.easeOutCubic` | No |
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

### `HypnogramInteractionMode`

| Value | Description |
| :--- | :--- |
| `scrub` | Hover, tap, and drag all continuously update the scrub tooltip/guide line. Default. |
| `tap` | Only a pointer-down sets the scrub tooltip/guide line — moving the pointer afterward does not. Use inside a scrollable/draggable parent that would otherwise fight continuous move-tracking. |

### `HypnogramLegend`

| Parameter | Description | Default | Required |
| :--- | :--- | :--- | :--- |
| `stageStyles` | Same map passed to `HypnogramChart` — one color dot + label per entry | `kDefaultHypnogramStageStyles` | No |
| `direction` | Lay the legend out as a row or column | `Axis.horizontal` | No |
| `spacing` | Space between entries | `12` | No |
| `dotSize` | Diameter of each color dot | `10` | No |
| `labelStyle` | Text style for labels | `null` (→ 12px, `ColorScheme.onSurfaceVariant`) | No |

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
7. **Time axis / grid ticks**: Always hour-aligned (e.g. 11 PM, 12 AM, 1 AM),
   not evenly spaced by count — a short-range chart may show only one or two
   ticks, a multi-day one may show many.
8. **`onSegmentTap`**: Fires on every pointer-down, independent of
   `enableTooltip` and `interactionMode` — it fires even with the tooltip
   disabled or in `.tap` mode.

## Example App

```dart
import 'package:flutter/material.dart';
import 'package:flutter_sleep_chart/flutter_sleep_chart.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_sleep_chart example')),
        body: Builder(
          builder: (context) {
            const stageStyles = {
              SleepStageType.awake: StageStyle(color: Color(0xFFE0729C), label: 'Awake'),
              SleepStageType.rem: StageStyle(color: Color(0xFF8E6BD9), label: 'REM'),
              SleepStageType.light: StageStyle(color: Color(0xFF4F8FE8), label: 'Light'),
              SleepStageType.deep: StageStyle(color: Color(0xFF1F2B6B), label: 'Deep', rowHeight: 52),
            };
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HypnogramChart(
                    segments: generateSleepData(),
                    stageStyles: stageStyles,
                    showTimeAxis: true,
                    onSegmentTap: (segment) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tapped ${segment.type}')),
                      );
                    },
                    tooltip: HypnogramTooltipConfig(
                      backgroundColor: const Color(0xFF1A1A2E),
                      durationText: (s) => '${s.duration.inMinutes} min',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const HypnogramLegend(stageStyles: stageStyles),
                ],
              ),
            );
          },
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
- **Inside a scrollable parent**: Use `interactionMode: HypnogramInteractionMode.tap`
  so scrubbing doesn't fight the parent's own drag/scroll gesture.
- **Disable animation for tests/goldens**: Set `enableAnimation: false` for
  deterministic first-frame output.

## Requirements

- Flutter >=1.17.0
- Dart SDK ^3.12.2

## License

MIT License
