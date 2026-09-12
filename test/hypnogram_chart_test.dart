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

  testWidgets(
    'a spanRows stage type borrows other rows instead of adding its own',
    (tester) async {
      const asleepStyles = {
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
        ),
        SleepStageType.asleep: StageStyle(
          color: Color(0xFF4F8FE8),
          label: 'Asleep',
          spanRows: [
            SleepStageType.rem,
            SleepStageType.light,
            SleepStageType.deep,
          ],
        ),
      };
      final asleepSegments = [
        SleepStageSegment(
          type: SleepStageType.awake,
          start: start,
          end: start.add(const Duration(minutes: 5)),
        ),
        SleepStageSegment(
          type: SleepStageType.asleep,
          start: start.add(const Duration(minutes: 5)),
          end: start.add(const Duration(minutes: 115)),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HypnogramChart(
              segments: asleepSegments,
              stageStyles: asleepStyles,
            ),
          ),
        ),
      );

      // Still 4 rows (awake/rem/light/deep) at the default 40px height each
      // — "asleep" borrows their combined space instead of adding a 5th row.
      expect(tester.getSize(find.byType(HypnogramChart)).height, 160);

      final chartFinder = find.byType(HypnogramChart);
      final topLeft = tester.getTopLeft(chartFinder);
      final size = tester.getSize(chartFinder);
      final dx = _dxForFraction(60 / 115, size.width);
      final gesture = await tester.startGesture(
        topLeft + Offset(dx, size.height * 0.5),
      );
      await tester.pump();
      expect(find.text('Asleep'), findsOneWidget);
      await gesture.up();
    },
  );

  testWidgets(
    'gradientRows narrows the gradient colors without affecting the span extent',
    (tester) async {
      const asleepStyles = {
        SleepStageType.rem: StageStyle(color: Color(0xFF8E6BD9), label: 'REM'),
        SleepStageType.light: StageStyle(
          color: Color(0xFF4F8FE8),
          label: 'Light',
        ),
        SleepStageType.deep: StageStyle(
          color: Color(0xFF1F2B6B),
          label: 'Deep',
        ),
        SleepStageType.asleep: StageStyle(
          color: Color(0xFF4F8FE8),
          label: 'Asleep',
          spanRows: [
            SleepStageType.rem,
            SleepStageType.light,
            SleepStageType.deep,
          ],
          gradientRows: [SleepStageType.rem, SleepStageType.light],
        ),
      };
      final asleepSegments = [
        SleepStageSegment(
          type: SleepStageType.asleep,
          start: start,
          end: start.add(const Duration(minutes: 60)),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HypnogramChart(
              segments: asleepSegments,
              stageStyles: asleepStyles,
            ),
          ),
        ),
      );

      // Still spans all 3 rows (rem/light/deep) — gradientRows only
      // narrows which colors the gradient samples, not the extent.
      expect(tester.getSize(find.byType(HypnogramChart)).height, 120);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('an overlapping in-bed row renders without throwing', (
    tester,
  ) async {
    const inBedStyles = {
      SleepStageType.inBed: StageStyle(
        color: Color(0xFF6C7A96),
        label: 'In Bed',
      ),
      SleepStageType.awake: StageStyle(
        color: Color(0xFFE0729C),
        label: 'Awake',
      ),
      SleepStageType.light: StageStyle(
        color: Color(0xFF4F8FE8),
        label: 'Light',
      ),
    };
    // "In bed" spans the whole range while awake/light are sub-ranges
    // within it — a non-contiguous, overlapping segment list.
    final inBedSegments = [
      SleepStageSegment(
        type: SleepStageType.inBed,
        start: start,
        end: start.add(const Duration(minutes: 120)),
      ),
      SleepStageSegment(
        type: SleepStageType.awake,
        start: start,
        end: start.add(const Duration(minutes: 10)),
      ),
      SleepStageSegment(
        type: SleepStageType.light,
        start: start.add(const Duration(minutes: 10)),
        end: start.add(const Duration(minutes: 120)),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HypnogramChart(
            segments: inBedSegments,
            stageStyles: inBedStyles,
          ),
        ),
      ),
    );

    expect(find.byType(HypnogramChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'asleep falls back to a built-in default with no stageStyles override',
    (tester) async {
      final segs = [
        SleepStageSegment(
          type: SleepStageType.awake,
          start: start,
          end: start.add(const Duration(minutes: 5)),
        ),
        SleepStageSegment(
          type: SleepStageType.asleep,
          start: start.add(const Duration(minutes: 5)),
          end: start.add(const Duration(minutes: 60)),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HypnogramChart(segments: segs)),
        ),
      );

      // Still 4 rows (default awake/rem/light/deep) — the "asleep" fallback
      // spans them instead of adding a 5th.
      expect(tester.getSize(find.byType(HypnogramChart)).height, 160);

      final chartFinder = find.byType(HypnogramChart);
      final topLeft = tester.getTopLeft(chartFinder);
      final size = tester.getSize(chartFinder);
      final dx = _dxForFraction(30 / 60, size.width);
      final gesture = await tester.startGesture(
        topLeft + Offset(dx, size.height * 0.5),
      );
      await tester.pump();
      expect(find.text('Asleep'), findsOneWidget);
      await gesture.up();
    },
  );

  test('resolveStageStyles backfills only missing, used fallback types', () {
    final segs = [
      SleepStageSegment(
        type: SleepStageType.asleep,
        start: start,
        end: start.add(const Duration(minutes: 10)),
      ),
    ];
    final resolved = resolveStageStyles(kDefaultHypnogramStageStyles, segs);

    expect(resolved[SleepStageType.asleep]?.label, 'Asleep');
    // inBed isn't used in segs, so it's left out entirely.
    expect(resolved.containsKey(SleepStageType.inBed), isFalse);
    // Existing entries pass through untouched.
    expect(
      resolved[SleepStageType.awake],
      kDefaultHypnogramStageStyles[SleepStageType.awake],
    );
  });

  testWidgets('minHeight pads a single-row chart up to that height', (
    tester,
  ) async {
    final soloSegments = [
      SleepStageSegment(
        type: SleepStageType.inBed,
        start: start,
        end: start.add(const Duration(minutes: 30)),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HypnogramChart(
            segments: soloSegments,
            stageStyles: const {},
            minHeight: 160,
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(HypnogramChart)).height, 160);
  });

  testWidgets('minHeight has no effect once rows already exceed it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HypnogramChart(segments: segments, minHeight: 50)),
      ),
    );

    // Default stageStyles always has 4 rows (160px), which already
    // exceeds the 50px minimum, so it's unaffected.
    expect(tester.getSize(find.byType(HypnogramChart)).height, 160);
  });
}
