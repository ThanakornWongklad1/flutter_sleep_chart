import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sleep_chart/flutter_sleep_chart.dart';

// Mirrors the widget's internal row-label column width, so taps land on an
// exact point in time rather than an approximate fraction of the raw
// widget width.
const _trackLeftPx = 64.0;

double _dxForFraction(double fraction, double widgetWidth) =>
    _trackLeftPx + fraction * (widgetWidth - _trackLeftPx);

void main() {
  final start = DateTime(2026, 1, 1, 23);
  // Total range: 23:00 -> 01:00 (120 minutes).
  final segments = [
    SleepStageSegment(
      type: SleepStageType.awake,
      start: start,
      end: start.add(const Duration(minutes: 5)),
    ),
    SleepStageSegment(
      type: SleepStageType.light,
      start: start.add(const Duration(minutes: 5)),
      end: start.add(const Duration(minutes: 40)),
    ),
    SleepStageSegment(
      type: SleepStageType.deep,
      start: start.add(const Duration(minutes: 40)),
      end: start.add(const Duration(minutes: 90)),
    ),
    // Two adjacent 'light' segments — should render/hit-test as one
    // continuous 90-120 (30min) bar.
    SleepStageSegment(
      type: SleepStageType.light,
      start: start.add(const Duration(minutes: 90)),
      end: start.add(const Duration(minutes: 100)),
    ),
    SleepStageSegment(
      type: SleepStageType.light,
      start: start.add(const Duration(minutes: 100)),
      end: start.add(const Duration(minutes: 120)),
    ),
  ];

  testWidgets('renders without throwing for a normal night', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HypnogramChart(segments: segments)),
      ),
    );

    expect(find.byType(HypnogramChart), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('renders empty state without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HypnogramChart(segments: [])),
      ),
    );

    expect(find.byType(HypnogramChart), findsOneWidget);
  });

  testWidgets('shows a tooltip with stage/time/duration while held', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HypnogramChart(segments: segments)),
      ),
    );

    final chartFinder = find.byType(HypnogramChart);
    final topLeft = tester.getTopLeft(chartFinder);
    final size = tester.getSize(chartFinder);

    // Midpoint of the deep-sleep segment (40-90min) is 65/120 through the
    // range. Use a held gesture (not a quick tap) since the tooltip is
    // designed to hide again on pointer-up.
    final dx = _dxForFraction(65 / 120, size.width);
    final gesture = await tester.startGesture(
      topLeft + Offset(dx, size.height * 0.5),
    );
    await tester.pump();

    expect(find.text('Deep'), findsOneWidget);

    await gesture.up();
  });

  testWidgets('merges adjacent same-stage segments (no seam)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HypnogramChart(segments: segments)),
      ),
    );

    final chartFinder = find.byType(HypnogramChart);
    final topLeft = tester.getTopLeft(chartFinder);
    final size = tester.getSize(chartFinder);

    // Midpoint of the merged 90-120min light span is 105/120 through the
    // range — tooltip should report the combined 30m duration, not 10m/20m.
    final dx = _dxForFraction(105 / 120, size.width);
    final gesture = await tester.startGesture(
      topLeft + Offset(dx, size.height * 0.5),
    );
    await tester.pump();

    expect(find.textContaining('30m'), findsOneWidget);

    await gesture.up();
  });

  testWidgets('onSegmentTap fires with the segment under the pointer', (
    tester,
  ) async {
    SleepStageSegment? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HypnogramChart(
            segments: segments,
            onSegmentTap: (s) => tapped = s,
          ),
        ),
      ),
    );

    final chartFinder = find.byType(HypnogramChart);
    final topLeft = tester.getTopLeft(chartFinder);
    final size = tester.getSize(chartFinder);

    final dx = _dxForFraction(65 / 120, size.width);
    final gesture = await tester.startGesture(
      topLeft + Offset(dx, size.height * 0.5),
    );
    await tester.pump();

    expect(tapped?.type, SleepStageType.deep);

    await gesture.up();
  });

  testWidgets('tap interaction mode ignores drag after the initial down', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HypnogramChart(
            segments: segments,
            interactionMode: HypnogramInteractionMode.tap,
          ),
        ),
      ),
    );

    final chartFinder = find.byType(HypnogramChart);
    final topLeft = tester.getTopLeft(chartFinder);
    final size = tester.getSize(chartFinder);

    final deepDx = _dxForFraction(65 / 120, size.width);
    final lightDx = _dxForFraction(105 / 120, size.width);
    final gesture = await tester.startGesture(
      topLeft + Offset(deepDx, size.height * 0.5),
    );
    await tester.pump();
    expect(find.text('Deep'), findsOneWidget);

    await gesture.moveTo(topLeft + Offset(lightDx, size.height * 0.5));
    await tester.pump();
    // Move is ignored in tap mode — tooltip stays on the original segment.
    expect(find.text('Deep'), findsOneWidget);
    expect(find.text('Light'), findsNothing);

    await gesture.up();
  });

  testWidgets('reserves extra height for the time axis when enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HypnogramChart(segments: segments, enableAnimation: false),
        ),
      ),
    );
    final withoutAxis = tester.getSize(find.byType(HypnogramChart)).height;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HypnogramChart(
            segments: segments,
            enableAnimation: false,
            showTimeAxis: true,
            timeAxisHeight: 20,
            showRowGridLines: true,
            showTimeGridLines: true,
          ),
        ),
      ),
    );
    final withAxis = tester.getSize(find.byType(HypnogramChart)).height;

    expect(withAxis, withoutAxis + 20);
  });

  testWidgets('emptyBuilder renders a custom placeholder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HypnogramChart(
            segments: const [],
            emptyBuilder: (context) => const Text('No sleep data'),
          ),
        ),
      ),
    );

    expect(find.text('No sleep data'), findsOneWidget);
  });

  testWidgets('HypnogramLegend renders one label per stage', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HypnogramLegend())),
    );

    expect(find.text('Awake'), findsOneWidget);
    expect(find.text('REM'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Deep'), findsOneWidget);
  });
}
