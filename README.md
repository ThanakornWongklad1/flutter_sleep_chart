# flutter_sleep_chart

A lightweight, dependency-free Flutter widget that renders an Apple
Health-style sleep stage chart from a list of sleep stage segments.

The bundled `example/` app has three pages (switch via the bottom nav):

<p>
  <img alt="Normal (detailed) example" width="280" src="https://raw.githubusercontent.com/ThanakornWongklad1/flutter_sleep_chart/main/screenshots/example_normal.png">
  <img alt="Coarse asleep example" width="280" src="https://raw.githubusercontent.com/ThanakornWongklad1/flutter_sleep_chart/main/screenshots/example_asleep.png">
  <img alt="In-bed-only example" width="280" src="https://raw.githubusercontent.com/ThanakornWongklad1/flutter_sleep_chart/main/screenshots/example_inbed.png">
</p>

## Features

- One row per stage (Awake / REM / Light / Deep, or any custom set), each a
  solid pill nested in its own glassy halo — a translucent tint of the
  stage color that reads correctly against any background automatically,
  light, dark, or custom
- Gradient connector lines between stage transitions
- Adjacent same-stage segments merge into one continuous bar, no seam
- Minimum bar width clamp so brief real-world stage flips stay visible
  instead of shrinking to nothing
- Hover, tap, or press-and-drag anywhere over the chart — above, below, or
  on a row — for a scrub tooltip (stage, time range, duration), a
  stage-colored dot, and a dashed vertical guide line
- Fully configurable per-stage colors, labels, and row heights
- Fully configurable tooltip content and style, or swap in your own widget
- `onSegmentTap` callback, an optional hour-aligned time axis, row dividers
  and dashed hourly gridlines (on by default, toggleable), and a
  `.tap`-only interaction mode for use inside scrollable/draggable parents
- `minHeight` keeps a short chart (e.g. a single-row `inBed`-only dataset)
  from looking like a thin sliver next to charts with more rows
- Bars animate in on first render and whenever `segments` changes
- A standalone `HypnogramLegend` widget for the same `stageStyles` map
- A coarse `SleepStageType.asleep` fallback for data sources without
  REM/Light/Deep detail, rendered as a gradient spanning those rows via
  `StageStyle.spanRows` — no extra row added
- `SleepStageType.inBed` for the overall in-bed span, as its own ordinary
  row independent of `asleep` and the finer stages
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

Row dividers (`showRowGridLines`) and dashed hourly gridlines
(`showTimeGridLines`) are on by default — set either to `false` to turn
them off:

```dart
HypnogramChart(
  segments: segments,
  onSegmentTap: (segment) => print('Tapped ${segment.type}'),
  showTimeAxis: true,
  showRowGridLines: false, // turn off the row dividers
  showTimeGridLines: false, // turn off the dashed hourly gridlines
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

### Coarse Asleep Stage & In-Bed Span

If your data source only distinguishes asleep/awake without REM/Light/Deep
detail, use `SleepStageType.asleep` in place of `rem`/`light`/`deep` (not
alongside them). For the overall in-bed span (e.g. bedtime to out-of-bed
time), use `SleepStageType.inBed` — an ordinary stage type with its own
row, independent of `asleep` and the finer stages.

Both work with **zero extra config** — just use the segment type, no
`stageStyles` entry required:

```dart
HypnogramChart(
  segments: [
    SleepStageSegment(type: SleepStageType.awake, start: t0, end: t1),
    SleepStageSegment(type: SleepStageType.asleep, start: t1, end: t2),
  ],
  // stageStyles omitted entirely — `asleep` gets a built-in color, label,
  // and gradient spanning REM/Light/Deep automatically.
)
```

If you *do* customize `stageStyles` (e.g. your own colors for the base
four), `asleep`/`inBed` still work without needing an entry there either —
`HypnogramChart` backfills whichever of the two your `segments` actually
use but your map doesn't define, from `kFallbackHypnogramStageStyles`. You
only need to add your own `StageStyle` for `asleep`/`inBed` when you want
to override that default look, e.g. to customize the gradient's rows or
extent:

```dart
stageStyles: const {
  SleepStageType.awake: StageStyle(color: Colors.orange, label: 'Awake'),
  SleepStageType.rem: StageStyle(color: Colors.purple, label: 'REM'),
  SleepStageType.light: StageStyle(color: Colors.blue, label: 'Light'),
  SleepStageType.deep: StageStyle(color: Colors.indigo, label: 'Deep'),
  SleepStageType.asleep: StageStyle(
    color: Colors.blue, // used for the legend dot & tooltip indicator
    label: 'Asleep',
    spanRows: [SleepStageType.rem, SleepStageType.light, SleepStageType.deep],
    gradientRows: [SleepStageType.rem, SleepStageType.light], // narrower gradient
  ),
},
```

Building a standalone `HypnogramLegend` alongside a chart that relies on
the defaults? Pass it through `resolveStageStyles` first, so it picks up
the same backfilled entries the chart used internally:

```dart
HypnogramLegend(stageStyles: resolveStageStyles(stageStyles, segments))
```

## Parameters

### `HypnogramChart`

| Parameter | Description | Default | Required |
| :--- | :--- | :--- | :--- |
| `segments` | The sleep data to render | - | Yes |
| `stageStyles` | Color, label, and optional row height per stage. Map iteration order sets row order, top to bottom. `asleep`/`inBed` are backfilled automatically from `kFallbackHypnogramStageStyles` when used in `segments` but missing here — see below | `kDefaultHypnogramStageStyles` | No |
| `rowHeight` | Default row height for any stage whose `StageStyle.rowHeight` is `null` | `40` | No |
| `minHeight` | Minimum height for the rows area. When the natural row stack is shorter (e.g. a single `inBed`-only row), the rows are centered within it instead | `0` (→ no minimum) | No |
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
| `showRowGridLines` | Draws a solid horizontal divider line above each stage row | `true` | No |
| `showTimeGridLines` | Draws a dashed vertical line at each hour-aligned tick | `true` | No |
| `gridLineColor` | Color for the grid lines above | `null` (→ faint tint of the text color) | No |
| `emptyBuilder` | Widget shown in place of the chart when `segments` is empty | `null` (→ blank box) | No |
| `enableAnimation` | Whether bars animate in on first render and on `segments` change | `true` | No |
| `animationDuration` | Duration of the reveal animation | `Duration(milliseconds: 450)` | No |
| `animationCurve` | Easing curve of the reveal animation | `Curves.easeOutCubic` | No |
| `haloOpacity` | Opacity of each stage's tinted halo (a translucent overlay of the stage color — reads correctly against any background automatically) | `0.35` | No |

### `StageStyle`

| Parameter | Description | Default | Required |
| :--- | :--- | :--- | :--- |
| `color` | Bar and halo tint for this stage. Also used for the legend dot, tooltip indicator, and scrub dot when `spanRows` is set | - | Yes |
| `label` | Row label text, and the default tooltip stage line | - | Yes |
| `rowHeight` | Per-stage row height override — e.g. render Deep taller than the rest. Ignored when `spanRows` is set | `null` (→ chart's `rowHeight`) | No |
| `spanRows` | When set, this stage skips its own row and instead renders as a translucent halo+bar gradient spanning the combined height of these other row types | `null` | No |
| `gradientRows` | Row types whose colors (first → last) define the `spanRows` gradient, when that should differ from `spanRows` itself — e.g. spanning REM/Light/Deep's full height while gradienting only REM → Light | `null` (→ `spanRows`) | No |

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
enum SleepStageType { awake, rem, light, deep, asleep, inBed }
```

Not limited to these rows — any subset works as long as `stageStyles` has
an entry for every type your `segments` use. `asleep` is a coarse fallback
for data sources without REM/Light/Deep detail — use it in place of
`rem`/`light`/`deep`, not alongside them, and give it a `spanRows` style
(see `StageStyle` above) so it spans those rows instead of adding its own.
`inBed` is the overall in-bed span — an ordinary stage type with its own
row, independent of `asleep` and the finer stages; no special handling
needed beyond giving it a `StageStyle` like any other type.

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
   present in `segments`, or that stage falls back to the ambient text color
   and an empty label.
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
   ticks, a multi-day one may show many. Ticks thin out automatically
   (every 2nd, 3rd, ... hour) when the chart isn't wide enough to fit an
   hourly label at each one without overlapping.
8. **`onSegmentTap`**: Fires on every pointer-down, independent of
   `enableTooltip` and `interactionMode` — it fires even with the tooltip
   disabled or in `.tap` mode.
9. **`spanRows`**: The row types a spanning stage names (e.g. `asleep`'s
   `[rem, light, deep]`) still need their own `stageStyles` entries, even
   if no segment ever uses those exact types — that's what defines the row
   space it spans and the colors its gradient samples.
10. **Transition connectors**: Only drawn between two segments that are
    exactly back-to-back in time (`a.end == b.start`). A row like `inBed`
    that overlaps the whole night — rather than sitting in the same
    contiguous sequence as the other segments — simply gets no connector,
    instead of a spurious line to whatever segment happens to sit next to
    it in the list.
11. **`asleep`/`inBed` defaults**: Automatic — the fallback only fires per
    type when it's present in `segments` *and* absent from your
    `stageStyles`; give either your own `StageStyle` entry to override the
    default look, and it's used as-is. `HypnogramLegend` doesn't see
    `segments`, so it can't apply this backfill itself — pass it through
    `resolveStageStyles(stageStyles, segments)` if you want the legend to
    match a chart relying on the defaults.

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

The runnable example app (`example/lib/`) is split across three pages,
switchable via a bottom nav bar:

- `normal_page.dart` — the detailed Awake/REM/Light/Deep breakdown, including
  a fragmented micro-arousal cluster that exercises the minimum-bar-width
  clamp, plus a second chart with two separate sleep sessions (a real gap
  in `segments` between them, not an `awake` segment).
- `asleep_page.dart` — the coarse `asleep` fallback, with no `stageStyles`
  entry for it at all (relies on the built-in default).
- `in_bed_page.dart` — `inBed` on its own, with no other stage types and no
  `stageStyles` override at all.

`shared.dart` holds the tooltip config and small helpers reused across all
three pages.

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
