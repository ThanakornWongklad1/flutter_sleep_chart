import 'package:flutter/material.dart';

import 'sleep_stage.dart';

/// Per-stage appearance: color, row label, and optional row height override.
///
/// Row order in [HypnogramChart] is the iteration order of the
/// `stageStyles` map, top to bottom.
class StageStyle {
  /// Bar color, and the color used for the legend dot, tooltip indicator,
  /// and scrub dot. When [spanRows] is set, the bar itself uses a gradient
  /// across the spanned rows' colors instead — [color] is still used for
  /// those single-color UI bits.
  final Color color;
  final String label;

  /// Height of this stage's row. Falls back to the chart's `rowHeight` when
  /// null. Ignored when [spanRows] is set (no row is reserved).
  final double? rowHeight;

  /// When set, this stage type doesn't get its own row — its bar instead
  /// spans the combined vertical extent of these other row types. Useful
  /// for a coarse fallback stage (e.g. "asleep") that covers a range of
  /// finer stages (e.g. REM/Light/Deep) without distinguishing between
  /// them.
  final List<SleepStageType>? spanRows;

  /// Row types whose colors define the [spanRows] gradient (first → last),
  /// when that should differ from [spanRows] itself — e.g. spanning
  /// REM/Light/Deep's full height while gradienting only REM → Light.
  /// Defaults to [spanRows] when null.
  final List<SleepStageType>? gradientRows;

  const StageStyle({
    required this.color,
    required this.label,
    this.rowHeight,
    this.spanRows,
    this.gradientRows,
  });
}

/// Default stage styles, top to bottom: awake, rem, light, deep.
const kDefaultHypnogramStageStyles = <SleepStageType, StageStyle>{
  SleepStageType.awake: StageStyle(color: Color(0xFFF2994A), label: 'Awake'),
  SleepStageType.rem: StageStyle(color: Color(0xFF9B6BD9), label: 'REM'),
  SleepStageType.light: StageStyle(color: Color(0xFF4F8FE8), label: 'Light'),
  SleepStageType.deep: StageStyle(color: Color(0xFF2C3E8C), label: 'Deep'),
};

/// Built-in styles for [SleepStageType.inBed] and [SleepStageType.asleep] —
/// used automatically by [HypnogramChart] (via [resolveStageStyles]) for
/// whichever of these appear in `segments` but aren't in `stageStyles`, so
/// they work out of the box without having to define them yourself.
const kFallbackHypnogramStageStyles = <SleepStageType, StageStyle>{
  SleepStageType.inBed: StageStyle(color: Color(0xFF82DCFF), label: 'In Bed'),
  SleepStageType.asleep: StageStyle(
    color: Color(0xFF4F8FE8),
    label: 'Asleep',
    spanRows: [SleepStageType.rem, SleepStageType.light, SleepStageType.deep],
    gradientRows: [SleepStageType.rem, SleepStageType.light],
  ),
};

/// Backfills [stageStyles] with [kFallbackHypnogramStageStyles] entries for
/// any type present in [segments] but missing from [stageStyles] — the same
/// resolution [HypnogramChart] applies internally. Use this to build a
/// [HypnogramLegend] that matches a chart relying on those defaults.
Map<SleepStageType, StageStyle> resolveStageStyles(
  Map<SleepStageType, StageStyle> stageStyles,
  List<SleepStageSegment> segments,
) {
  final usedTypes = segments.map((s) => s.type).toSet();
  final backfill = <SleepStageType, StageStyle>{
    for (final type in kFallbackHypnogramStageStyles.keys)
      if (usedTypes.contains(type) && !stageStyles.containsKey(type))
        type: kFallbackHypnogramStageStyles[type]!,
  };
  if (backfill.isEmpty) return stageStyles;
  return {...backfill, ...stageStyles};
}

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
