import 'package:flutter/material.dart';
import 'package:flutter_sleep_chart/flutter_sleep_chart.dart';

import 'shared.dart';

/// Page 1: the detailed Awake/REM/Light/Deep breakdown — a normal
/// continuous night, and a night with two separate sleep sessions
/// (20:00–24:00, then 02:00–08:00) with a real gap in between.
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
          sectionTitle(context, 'Continuous night'),
          HypnogramChart(
            segments: segments,
            stageStyles: stageStyles,
            showTimeAxis: true,
            onSegmentTap: onTapSnack(context, stageStyles),
            tooltip: tooltipConfig,
          ),
          const SizedBox(height: 8),
          const HypnogramLegend(stageStyles: stageStyles),

          const SizedBox(height: 32),
          sectionTitle(
            context,
            'Two sleep sessions (20:00–24:00, then 02:00–08:00)',
          ),
          HypnogramChart(
            segments: twoSessionSegments,
            stageStyles: stageStyles,
            showTimeAxis: true,
            onSegmentTap: onTapSnack(context, stageStyles),
            tooltip: tooltipConfig,
          ),
          const SizedBox(height: 8),
          const HypnogramLegend(stageStyles: stageStyles),
        ],
      ),
    );
  }
}
