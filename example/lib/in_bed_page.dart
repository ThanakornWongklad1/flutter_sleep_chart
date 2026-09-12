import 'package:flutter/material.dart';
import 'package:flutter_sleep_chart/flutter_sleep_chart.dart';

import 'shared.dart';

/// Page 3: `inBed` on its own — no awake/rem/light/deep segments at all,
/// just the overall in-bed span (with a short gap for getting up briefly).
/// No stageStyles override at all — `inBed` is backfilled automatically.
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
          sectionTitle(context, 'In bed only (no stage detail at all)'),
          HypnogramChart(
            segments: inBedSegments,
            stageStyles: const {},
            // Matches the other pages' 4-row (40px each) height, so a
            // single-row chart doesn't look like a thin sliver in
            // comparison — the row is centered within it.
            minHeight: 160,
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
