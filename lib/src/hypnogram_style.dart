import 'package:flutter/material.dart';

import 'sleep_stage.dart';

/// Per-stage appearance: color, row label, and optional row height override.
///
/// Row order in [HypnogramChart] is the iteration order of the
/// `stageStyles` map, top to bottom.
class StageStyle {
  final Color color;
  final String label;

  /// Height of this stage's row. Falls back to the chart's `rowHeight` when
  /// null.
  final double? rowHeight;

  const StageStyle({required this.color, required this.label, this.rowHeight});
}

/// Default stage styles, top to bottom: awake, rem, light, deep.
const kDefaultHypnogramStageStyles = <SleepStageType, StageStyle>{
  SleepStageType.awake: StageStyle(color: Color(0xFFF2994A), label: 'Awake'),
  SleepStageType.rem: StageStyle(color: Color(0xFF9B6BD9), label: 'REM'),
  SleepStageType.light: StageStyle(color: Color(0xFF4F8FE8), label: 'Light'),
  SleepStageType.deep: StageStyle(color: Color(0xFF2C3E8C), label: 'Deep'),
};

/// Configures the scrub tooltip's content and appearance.
///
/// Set [builder] to replace the whole bubble with a custom widget. Otherwise
/// [labelText]/[timeRangeText]/[durationText] override individual lines
/// (defaulting to the stage label, formatted clock range, and formatted
/// duration), and the remaining fields style the default bubble.
class HypnogramTooltipConfig {
  final Widget Function(BuildContext context, SleepStageSegment segment)?
  builder;
  final String Function(SleepStageSegment segment)? labelText;
  final String Function(SleepStageSegment segment)? timeRangeText;
  final String Function(SleepStageSegment segment)? durationText;

  final Color? backgroundColor;
  final TextStyle? labelStyle;
  final TextStyle? detailStyle;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final List<BoxShadow>? shadow;
  final bool showColorDot;

  const HypnogramTooltipConfig({
    this.builder,
    this.labelText,
    this.timeRangeText,
    this.durationText,
    this.backgroundColor,
    this.labelStyle,
    this.detailStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.shadow = const [
      BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6)),
    ],
    this.showColorDot = true,
  });
}

/// How [HypnogramChart] reacts to pointer input.
enum HypnogramInteractionMode {
  /// Hover, tap, and drag all continuously update the scrub tooltip/guide
  /// line as the pointer moves. The default.
  scrub,

  /// Only a pointer-down sets the scrub tooltip/guide line; moving the
  /// pointer afterward does not. Useful when the chart sits inside a
  /// scrollable or draggable parent and continuous move-tracking would
  /// fight it.
  tap,
}

/// A standalone legend for a [HypnogramChart]'s [StageStyle] map — a
/// color dot + label per stage, for composing outside the chart itself.
class HypnogramLegend extends StatelessWidget {
  final Map<SleepStageType, StageStyle> stageStyles;
  final Axis direction;
  final double spacing;
  final double dotSize;
  final TextStyle? labelStyle;

  const HypnogramLegend({
    super.key,
    this.stageStyles = kDefaultHypnogramStageStyles,
    this.direction = Axis.horizontal,
    this.spacing = 12,
    this.dotSize = 10,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final style =
        labelStyle ??
        TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Wrap(
      direction: direction,
      spacing: spacing,
      runSpacing: spacing / 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final entry in stageStyles.entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: entry.value.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(entry.value.label, style: style),
            ],
          ),
      ],
    );
  }
}
