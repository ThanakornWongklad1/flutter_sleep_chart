import 'package:flutter/material.dart';
import 'package:flutter_sleep_chart/flutter_sleep_chart.dart';

import 'shared.dart';

/// Page 2: coarse asleep/awake fallback — used in place of the detailed
/// rem/light/deep breakdown, not alongside it. "Asleep" works out of the
/// box (no row of its own, spans the combined REM/Light/Deep row space)
/// without needing a StageStyle entry for it at all.
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
          sectionTitle(context, 'Coarse asleep (no stage detail)'),
          HypnogramChart(
            segments: asleepSegments,
            stageStyles: asleepStageStyles,
            showTimeAxis: true,
            onSegmentTap: onTapSnack(context, effectiveStyles),
            tooltip: tooltipConfig,
          ),
          const SizedBox(height: 8),
          HypnogramLegend(stageStyles: effectiveStyles),
        ],
      ),
    );
  }
}
