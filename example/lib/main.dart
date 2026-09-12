// Everything lives in this one file, even though it's three logical
// "pages" — pub.dev's Example tab only renders example/lib/main.dart
// itself, not files it imports, so splitting this across multiple files
// would hide most of the usage from anyone browsing the package there.
import 'package:flutter/material.dart';
import 'package:flutter_sleep_chart/flutter_sleep_chart.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _titles = ['Normal', 'Asleep', 'In Bed'];
  static const _pages = [NormalPage(), AsleepPage(), InBedPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('flutter_sleep_chart — ${_titles[_index]}')),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bedtime_outlined),
            label: 'Normal',
          ),
          NavigationDestination(
            icon: Icon(Icons.nightlight_outlined),
            label: 'Asleep',
          ),
          NavigationDestination(
            icon: Icon(Icons.hotel_outlined),
            label: 'In Bed',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Shared helpers, reused by all three pages below.
// ---------------------------------------------------------------------

final _tooltipConfig = HypnogramTooltipConfig(
  backgroundColor: const Color(0xFF1A1A2E),
  durationText: (s) => '${s.duration.inMinutes} min',
);

void Function(SleepStageSegment) _onTapSnack(
  BuildContext ctx,
  Map<SleepStageType, StageStyle> styles,
) {
  return (segment) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          '${styles[segment.type]?.label} · ${segment.duration.inMinutes}m',
        ),
        duration: const Duration(milliseconds: 800),
      ),
    );
  };
}

Widget _sectionTitle(BuildContext ctx, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(text, style: Theme.of(ctx).textTheme.titleMedium),
);

// ---------------------------------------------------------------------
// Page 1: the detailed Awake/REM/Light/Deep breakdown — a normal
// continuous night, and a night with two separate sleep sessions
// (20:00–24:00, then 02:00–08:00) with a real gap in between.
// ---------------------------------------------------------------------

class NormalPage extends StatelessWidget {
  const NormalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final start = DateTime(2026, 1, 1, 23);
    DateTime at(double minutes) =>
        start.add(Duration(seconds: (minutes * 60).round()));

    final segments = [
      SleepStageSegment(type: SleepStageType.awake, start: at(0), end: at(5)),
      SleepStageSegment(type: SleepStageType.light, start: at(5), end: at(20)),
      // A brief fragmented cluster: rapid awake/rem flips inside a light
      // stretch, demonstrating the minimum-bar-width clamp.
      SleepStageSegment(
        type: SleepStageType.awake,
        start: at(20),
        end: at(21.25),
      ),
      SleepStageSegment(
        type: SleepStageType.rem,
        start: at(21.25),
        end: at(22.5),
      ),
      SleepStageSegment(
        type: SleepStageType.awake,
        start: at(22.5),
        end: at(23.75),
      ),
      SleepStageSegment(
        type: SleepStageType.rem,
        start: at(23.75),
        end: at(25),
      ),
      SleepStageSegment(type: SleepStageType.light, start: at(25), end: at(45)),
      SleepStageSegment(type: SleepStageType.deep, start: at(45), end: at(90)),
      SleepStageSegment(
        type: SleepStageType.light,
        start: at(90),
        end: at(120),
      ),
      SleepStageSegment(type: SleepStageType.rem, start: at(120), end: at(150)),
      SleepStageSegment(
        type: SleepStageType.light,
        start: at(150),
        end: at(185),
      ),
      SleepStageSegment(
        type: SleepStageType.deep,
        start: at(185),
        end: at(220),
      ),
      SleepStageSegment(
        type: SleepStageType.light,
        start: at(220),
        end: at(250),
      ),
      SleepStageSegment(
        type: SleepStageType.awake,
        start: at(250),
        end: at(255),
      ),
    ];

    const stageStyles = {
      SleepStageType.awake: StageStyle(
        color: Color(0xFFE0729C),
        label: 'Awake',
      ),
      SleepStageType.rem: StageStyle(color: Color(0xFF8E6BD9), label: 'REM'),
      SleepStageType.light: StageStyle(
        color: Color(0xFF4F8FE8),
        label: 'Light',
      ),
      SleepStageType.deep: StageStyle(
        color: Color(0xFF1F2B6B),
        label: 'Deep',
        rowHeight: 52,
      ),
    };

    // Two sleep sessions with a real gap (24:00-02:00) between them —
    // nothing covers that stretch at all, unlike an `awake` segment.
    final gapStart = DateTime(2026, 1, 1, 20);
    DateTime gapAt(double minutes) =>
        gapStart.add(Duration(minutes: minutes.round()));
    final twoSessionSegments = [
      // Session 1: 20:00 - 24:00.
      SleepStageSegment(
        type: SleepStageType.light,
        start: gapAt(0),
        end: gapAt(20),
      ),
      SleepStageSegment(
        type: SleepStageType.deep,
        start: gapAt(20),
        end: gapAt(60),
      ),
      SleepStageSegment(
        type: SleepStageType.light,
        start: gapAt(60),
        end: gapAt(100),
      ),
      SleepStageSegment(
        type: SleepStageType.rem,
        start: gapAt(100),
        end: gapAt(120),
      ),
      SleepStageSegment(
        type: SleepStageType.light,
        start: gapAt(120),
        end: gapAt(180),
      ),
      SleepStageSegment(
        type: SleepStageType.awake,
        start: gapAt(180),
        end: gapAt(190),
      ),
      SleepStageSegment(
        type: SleepStageType.light,
        start: gapAt(190),
        end: gapAt(240),
      ),
      // Gap: 24:00 - 02:00 (120min), no segment at all.
      // Session 2: 02:00 - 08:00.
      SleepStageSegment(
        type: SleepStageType.light,
        start: gapAt(360),
        end: gapAt(390),
      ),
      SleepStageSegment(
        type: SleepStageType.deep,
        start: gapAt(390),
        end: gapAt(450),
      ),
      SleepStageSegment(
        type: SleepStageType.light,
        start: gapAt(450),
        end: gapAt(510),
      ),
      SleepStageSegment(
        type: SleepStageType.rem,
        start: gapAt(510),
        end: gapAt(540),
      ),
      SleepStageSegment(
        type: SleepStageType.light,
        start: gapAt(540),
        end: gapAt(630),
      ),
      SleepStageSegment(
        type: SleepStageType.deep,
        start: gapAt(630),
        end: gapAt(680),
      ),
      SleepStageSegment(
        type: SleepStageType.light,
        start: gapAt(680),
        end: gapAt(720),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Continuous night'),
          HypnogramChart(
            segments: segments,
            stageStyles: stageStyles,
            showTimeAxis: true,
            onSegmentTap: _onTapSnack(context, stageStyles),
            tooltip: _tooltipConfig,
          ),
          const SizedBox(height: 8),
          const HypnogramLegend(stageStyles: stageStyles),

          const SizedBox(height: 32),
          _sectionTitle(
            context,
            'Two sleep sessions (20:00–24:00, then 02:00–08:00)',
          ),
          HypnogramChart(
            segments: twoSessionSegments,
            stageStyles: stageStyles,
            showTimeAxis: true,
            onSegmentTap: _onTapSnack(context, stageStyles),
            tooltip: _tooltipConfig,
          ),
          const SizedBox(height: 8),
          const HypnogramLegend(stageStyles: stageStyles),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Page 2: coarse asleep/awake fallback — used in place of the detailed
// rem/light/deep breakdown, not alongside it. "Asleep" works out of the
// box (no row of its own, spans the combined REM/Light/Deep row space)
// without needing a StageStyle entry for it at all.
// ---------------------------------------------------------------------

class AsleepPage extends StatelessWidget {
  const AsleepPage({super.key});

  @override
  Widget build(BuildContext context) {
    final start = DateTime(2026, 1, 1, 23);
    DateTime at(double minutes) =>
        start.add(Duration(seconds: (minutes * 60).round()));

    final asleepSegments = [
      SleepStageSegment(type: SleepStageType.awake, start: at(0), end: at(5)),
      SleepStageSegment(
        type: SleepStageType.asleep,
        start: at(5),
        end: at(130),
      ),
      SleepStageSegment(
        type: SleepStageType.awake,
        start: at(130),
        end: at(135),
      ),
      SleepStageSegment(
        type: SleepStageType.asleep,
        start: at(135),
        end: at(250),
      ),
      SleepStageSegment(
        type: SleepStageType.awake,
        start: at(250),
        end: at(255),
      ),
    ];

    const asleepStageStyles = {
      SleepStageType.awake: StageStyle(
        color: Color(0xFFE0729C),
        label: 'Awake',
      ),
      SleepStageType.rem: StageStyle(color: Color(0xFF8E6BD9), label: 'REM'),
      SleepStageType.light: StageStyle(
        color: Color(0xFF4F8FE8),
        label: 'Light',
      ),
      SleepStageType.deep: StageStyle(color: Color(0xFF1F2B6B), label: 'Deep'),
      // No entry for `asleep` — HypnogramChart backfills it automatically
      // from kFallbackHypnogramStageStyles since it's used in the segments
      // below but not defined here.
    };
    // resolveStageStyles mirrors that same backfill, for the legend/tap
    // handler below (which don't see `segments` the way the chart does).
    final effectiveStyles = resolveStageStyles(
      asleepStageStyles,
      asleepSegments,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Coarse asleep (no stage detail)'),
          HypnogramChart(
            segments: asleepSegments,
            stageStyles: asleepStageStyles,
            showTimeAxis: true,
            onSegmentTap: _onTapSnack(context, effectiveStyles),
            tooltip: _tooltipConfig,
          ),
          const SizedBox(height: 8),
          HypnogramLegend(stageStyles: effectiveStyles),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Page 3: `inBed` on its own — no awake/rem/light/deep segments at all,
// just the overall in-bed span (with a short gap for getting up briefly).
// No stageStyles override at all — `inBed` is backfilled automatically.
// ---------------------------------------------------------------------

class InBedPage extends StatelessWidget {
  const InBedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final start = DateTime(2026, 1, 1, 22);
    DateTime at(double minutes) =>
        start.add(Duration(minutes: minutes.round()));

    final inBedSegments = [
      SleepStageSegment(type: SleepStageType.inBed, start: at(0), end: at(240)),
      // Gap: briefly out of bed (240-255min), no segment at all.
      SleepStageSegment(
        type: SleepStageType.inBed,
        start: at(255),
        end: at(540),
      ),
    ];

    final effectiveStyles = resolveStageStyles(const {}, inBedSegments);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'In bed only (no stage detail at all)'),
          HypnogramChart(
            segments: inBedSegments,
            stageStyles: const {},
            // Matches the other pages' 4-row (40px each) height, so a
            // single-row chart doesn't look like a thin sliver in
            // comparison — the row is centered within it.
            minHeight: 160,
            showTimeAxis: true,
            onSegmentTap: _onTapSnack(context, effectiveStyles),
            tooltip: _tooltipConfig,
          ),
          const SizedBox(height: 8),
          HypnogramLegend(stageStyles: effectiveStyles),
        ],
      ),
    );
  }
}
