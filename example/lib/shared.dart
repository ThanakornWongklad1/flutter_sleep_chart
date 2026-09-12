import 'package:flutter/material.dart';
import 'package:flutter_sleep_chart/flutter_sleep_chart.dart';

final tooltipConfig = HypnogramTooltipConfig(
  backgroundColor: const Color(0xFF1A1A2E),
  durationText: (s) => '${s.duration.inMinutes} min',
);

void Function(SleepStageSegment) onTapSnack(
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

Widget sectionTitle(BuildContext ctx, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(text, style: Theme.of(ctx).textTheme.titleMedium),
);
