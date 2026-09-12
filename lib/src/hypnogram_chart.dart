import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'hypnogram_style.dart';
import 'sleep_stage.dart';

export 'hypnogram_style.dart';

List<SleepStageSegment> _mergeAdjacent(List<SleepStageSegment> segments) {
  final out = <SleepStageSegment>[];
  for (final seg in segments) {
    final last = out.isEmpty ? null : out.last;
    if (last != null && last.type == seg.type && last.end == seg.start) {
      out[out.length - 1] = SleepStageSegment(
        type: seg.type,
        start: last.start,
        end: seg.end,
      );
    } else {
      out.add(seg);
    }
  }
  return out;
}

String _formatClock(DateTime t) {
  var h = t.hour % 12;
  if (h == 0) h = 12;
  final suffix = t.hour >= 12 ? 'PM' : 'AM';
  final m = t.minute;
  return m == 0 ? '$h $suffix' : '$h:${m.toString().padLeft(2, '0')} $suffix';
}

String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return (h > 0 ? '${h}h ' : '') + '${m}m';
}

/// Hour-aligned tick times within `[start, end]`, for the time axis and
/// vertical grid lines.
List<DateTime> _hourTicks(DateTime start, DateTime end) {
  var t = DateTime(start.year, start.month, start.day, start.hour);
  if (t.isBefore(start)) t = t.add(const Duration(hours: 1));
  final ticks = <DateTime>[];
  while (!t.isAfter(end)) {
    ticks.add(t);
    t = t.add(const Duration(hours: 1));
  }
  return ticks;
}

/// Per-row vertical layout, derived from `stageStyles` order and each
/// stage's height override (or the chart's default `rowHeight`).
typedef _RowLayout = ({
  List<SleepStageType> order,
  Map<SleepStageType, double> top,
  Map<SleepStageType, double> height,
  double totalHeight,
});

_RowLayout _layoutRows(
  Map<SleepStageType, StageStyle> stageStyles,
  double defaultRowHeight,
) {
  final order = stageStyles.keys.toList();
  final top = <SleepStageType, double>{};
  final height = <SleepStageType, double>{};
  var y = 0.0;
  for (final type in order) {
    final h = stageStyles[type]?.rowHeight ?? defaultRowHeight;
    top[type] = y;
    height[type] = h;
    y += h;
  }
  return (order: order, top: top, height: height, totalHeight: y);
}

/// An Apple Health-style hypnogram: one glassy-halo bar row per stage, with
/// gradient connectors between transitions and a scrub tooltip on
/// hover/tap/drag.
class HypnogramChart extends StatefulWidget {
  final List<SleepStageSegment> segments;

  /// Color, label, and optional row-height override per stage. Row order
  /// (top to bottom) follows this map's iteration order.
  final Map<SleepStageType, StageStyle> stageStyles;

  /// Default row height for stages that don't set their own in
  /// [StageStyle.rowHeight].
  final double rowHeight;
  final double barHeight;
  final double haloPad;
  final double minBarWidth;

  /// Width of the left-hand stage-label column.
  final double labelColumnWidth;
  final bool enableTooltip;

  /// Content and styling for the scrub tooltip.
  final HypnogramTooltipConfig tooltip;

  /// How the chart reacts to pointer input.
  final HypnogramInteractionMode interactionMode;

  /// Called with the segment under the pointer on every pointer-down
  /// (tap, or the start of a drag).
  final void Function(SleepStageSegment segment)? onSegmentTap;

  /// Shows hour-aligned clock labels below the chart.
  final bool showTimeAxis;

  /// Height reserved for [showTimeAxis]'s labels.
  final double timeAxisHeight;

  /// Draws a horizontal divider line above each stage row.
  final bool showRowGridLines;

  /// Draws a vertical line at each hour-aligned tick.
  final bool showTimeGridLines;

  /// Color for [showRowGridLines]/[showTimeGridLines]. Defaults to a faint
  /// tint of the ambient text color.
  final Color? gridLineColor;

  /// Widget shown in place of the chart when [segments] is empty. Defaults
  /// to a blank box sized to the chart's normal height.
  final WidgetBuilder? emptyBuilder;

  /// Whether bars animate in on first render and whenever [segments]
  /// changes.
  final bool enableAnimation;
  final Duration animationDuration;
  final Curve animationCurve;

  /// Base color the halo is blended toward (32% stage color, 68% this).
  /// Defaults to the ambient [ColorScheme.surface].
  final Color? haloBackground;

  const HypnogramChart({
    super.key,
    required this.segments,
    this.stageStyles = kDefaultHypnogramStageStyles,
    this.rowHeight = 40,
    this.barHeight = 20,
    this.haloPad = 2,
    this.minBarWidth = 1,
    this.labelColumnWidth = 64,
    this.enableTooltip = true,
    this.tooltip = const HypnogramTooltipConfig(),
    this.interactionMode = HypnogramInteractionMode.scrub,
    this.onSegmentTap,
    this.showTimeAxis = false,
    this.timeAxisHeight = 20,
    this.showRowGridLines = false,
    this.showTimeGridLines = false,
    this.gridLineColor,
    this.emptyBuilder,
    this.enableAnimation = true,
    this.animationDuration = const Duration(milliseconds: 450),
    this.animationCurve = Curves.easeOutCubic,
    this.haloBackground,
  });

  @override
  State<HypnogramChart> createState() => _HypnogramChartState();
}

class _HypnogramChartState extends State<HypnogramChart>
    with SingleTickerProviderStateMixin {
  late List<SleepStageSegment> _merged;
  late final AnimationController _revealController;
  Offset? _hoverLocal;
  SleepStageSegment? _hoverSeg;

  @override
  void initState() {
    super.initState();
    _merged = _mergeAdjacent(widget.segments);
    _revealController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _revealController.value = widget.enableAnimation ? 0 : 1;
    if (widget.enableAnimation) _revealController.forward();
  }

  @override
  void didUpdateWidget(covariant HypnogramChart old) {
    super.didUpdateWidget(old);
    if (old.segments != widget.segments) {
      _merged = _mergeAdjacent(widget.segments);
      _hoverLocal = null;
      _hoverSeg = null;
      _revealController.duration = widget.animationDuration;
      if (widget.enableAnimation) {
        _revealController.forward(from: 0);
      } else {
        _revealController.value = 1;
      }
    } else if (!widget.enableAnimation && old.enableAnimation) {
      _revealController.value = 1;
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  void _updateHover(Offset local, double width, {bool isDown = false}) {
    if (_merged.isEmpty) return;
    final trackWidth = width - widget.labelColumnWidth;
    if (trackWidth <= 0) {
      _clearHover();
      return;
    }
    final frac = (local.dx - widget.labelColumnWidth) / trackWidth;
    if (frac < 0 || frac > 1) {
      _clearHover();
      return;
    }
    final rangeStart = _merged.first.start;
    final rangeEnd = _merged.last.end;
    final totalMicros = rangeEnd.difference(rangeStart).inMicroseconds;
    final t = rangeStart.add(
      Duration(microseconds: (frac * totalMicros).round()),
    );
    SleepStageSegment? found;
    for (final s in _merged) {
      if (!t.isBefore(s.start) && t.isBefore(s.end)) {
        found = s;
        break;
      }
    }
    setState(() {
      _hoverLocal = local;
      _hoverSeg = found;
    });
    if (isDown && found != null) {
      widget.onSegmentTap?.call(found);
    }
  }

  void _clearHover() {
    if (_hoverLocal == null && _hoverSeg == null) return;
    setState(() {
      _hoverLocal = null;
      _hoverSeg = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rowLayout = _layoutRows(widget.stageStyles, widget.rowHeight);
    final chartHeight = rowLayout.totalHeight;
    final totalHeight =
        chartHeight + (widget.showTimeAxis ? widget.timeAxisHeight : 0);
    final haloBackground =
        widget.haloBackground ?? Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurfaceVariant;

    if (widget.segments.isEmpty) {
      return SizedBox(
        height: totalHeight,
        width: double.infinity,
        child: widget.emptyBuilder?.call(context),
      );
    }

    final scrubbing = widget.interactionMode == HypnogramInteractionMode.scrub;

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return MouseRegion(
            onExit: (_) => _clearHover(),
            child: Listener(
              onPointerHover: scrubbing
                  ? (e) => _updateHover(e.localPosition, width)
                  : null,
              onPointerDown: (e) =>
                  _updateHover(e.localPosition, width, isDown: true),
              onPointerMove: scrubbing
                  ? (e) => _updateHover(e.localPosition, width)
                  : null,
              onPointerUp: (_) => _clearHover(),
              onPointerCancel: (_) => _clearHover(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedBuilder(
                    animation: _revealController,
                    builder: (context, _) {
                      final revealProgress = widget.animationCurve.transform(
                        _revealController.value,
                      );
                      return CustomPaint(
                        size: Size(width, totalHeight),
                        painter: _HypnogramPainter(
                          segments: _merged,
                          stageStyles: widget.stageStyles,
                          rowLayout: rowLayout,
                          barHeight: widget.barHeight,
                          haloPad: widget.haloPad,
                          minBarWidth: widget.minBarWidth,
                          labelColumnWidth: widget.labelColumnWidth,
                          haloBackground: haloBackground,
                          textColor: textColor,
                          hoverDx: _hoverLocal?.dx,
                          showTimeAxis: widget.showTimeAxis,
                          showRowGridLines: widget.showRowGridLines,
                          showTimeGridLines: widget.showTimeGridLines,
                          gridLineColor: widget.gridLineColor,
                          revealProgress: revealProgress,
                        ),
                      );
                    },
                  ),
                  if (widget.enableTooltip &&
                      _hoverSeg != null &&
                      _hoverLocal != null)
                    Positioned.fill(
                      child: CustomSingleChildLayout(
                        delegate: _TooltipLayoutDelegate(
                          _hoverLocal!.dx,
                          (rowLayout.top[_hoverSeg!.type] ?? 0) +
                              (rowLayout.height[_hoverSeg!.type] ??
                                      widget.rowHeight) /
                                  2,
                        ),
                        child: widget.tooltip.builder != null
                            ? widget.tooltip.builder!(context, _hoverSeg!)
                            : _TooltipBubble(
                                color:
                                    widget
                                        .stageStyles[_hoverSeg!.type]
                                        ?.color ??
                                    haloBackground,
                                label:
                                    widget.tooltip.labelText?.call(
                                      _hoverSeg!,
                                    ) ??
                                    widget
                                        .stageStyles[_hoverSeg!.type]
                                        ?.label ??
                                    '',
                                timeRange:
                                    widget.tooltip.timeRangeText?.call(
                                      _hoverSeg!,
                                    ) ??
                                    '${_formatClock(_hoverSeg!.start)} – ${_formatClock(_hoverSeg!.end)}',
                                duration:
                                    widget.tooltip.durationText?.call(
                                      _hoverSeg!,
                                    ) ??
                                    _formatDuration(_hoverSeg!.duration),
                                config: widget.tooltip,
                              ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HypnogramPainter extends CustomPainter {
  final List<SleepStageSegment> segments;
  final Map<SleepStageType, StageStyle> stageStyles;
  final _RowLayout rowLayout;
  final double barHeight;
  final double haloPad;
  final double minBarWidth;
  final double labelColumnWidth;
  final Color haloBackground;
  final Color textColor;
  final double? hoverDx;
  final bool showTimeAxis;
  final bool showRowGridLines;
  final bool showTimeGridLines;
  final Color? gridLineColor;
  final double revealProgress;

  _HypnogramPainter({
    required this.segments,
    required this.stageStyles,
    required this.rowLayout,
    required this.barHeight,
    required this.haloPad,
    required this.minBarWidth,
    required this.labelColumnWidth,
    required this.haloBackground,
    required this.textColor,
    required this.hoverDx,
    required this.showTimeAxis,
    required this.showRowGridLines,
    required this.showTimeGridLines,
    required this.gridLineColor,
    required this.revealProgress,
  });

  double _rowCenterY(SleepStageType type) {
    final top = rowLayout.top[type];
    final height = rowLayout.height[type];
    if (top == null || height == null) return 0;
    return top + height / 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final rangeStart = segments.first.start;
    final rangeEnd = segments.last.end;
    final totalMicros = rangeEnd.difference(rangeStart).inMicroseconds;
    if (totalMicros <= 0) return;

    final chartHeight = rowLayout.totalHeight;
    final trackWidth = size.width - labelColumnWidth;

    double xOf(DateTime t) =>
        labelColumnWidth +
        t.difference(rangeStart).inMicroseconds / totalMicros * trackWidth;

    final gridColor = gridLineColor ?? textColor.withValues(alpha: 0.08);

    if (showRowGridLines) {
      final gridPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 1;
      for (final type in rowLayout.order) {
        final top = rowLayout.top[type]!;
        canvas.drawLine(
          Offset(labelColumnWidth, top),
          Offset(size.width, top),
          gridPaint,
        );
      }
      canvas.drawLine(
        Offset(labelColumnWidth, chartHeight),
        Offset(size.width, chartHeight),
        gridPaint,
      );
    }

    final ticks = (showTimeGridLines || showTimeAxis)
        ? _hourTicks(rangeStart, rangeEnd)
        : const <DateTime>[];

    if (showTimeGridLines) {
      final gridPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 1;
      for (final t in ticks) {
        final x = xOf(t);
        canvas.drawLine(Offset(x, 0), Offset(x, chartHeight), gridPaint);
      }
    }

    // Row labels.
    for (final type in rowLayout.order) {
      final tp = TextPainter(
        text: TextSpan(
          text: stageStyles[type]?.label ?? '',
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      )..layout(maxWidth: labelColumnWidth - 12);
      final y = _rowCenterY(type) - tp.height / 2;
      tp.paint(canvas, Offset(labelColumnWidth - 12 - tp.width, y));
    }

    // Halos + bars.
    for (final seg in segments) {
      final naturalLeft = xOf(seg.start);
      final naturalWidth = xOf(seg.end) - naturalLeft;
      double left, width;
      if (naturalWidth < minBarWidth) {
        final mid = naturalLeft + naturalWidth / 2;
        left = mid - minBarWidth / 2;
        width = minBarWidth;
      } else {
        left = naturalLeft;
        width = naturalWidth;
      }
      width *= revealProgress;

      final centerY = _rowCenterY(seg.type);
      final barRect = Rect.fromLTWH(
        left,
        centerY - barHeight / 2,
        width,
        barHeight,
      );
      final haloRect = barRect.inflate(haloPad);
      final stageColor = stageStyles[seg.type]?.color ?? haloBackground;

      final haloPaint = Paint()
        ..color = Color.lerp(
          stageColor,
          haloBackground,
          0.68,
        )!.withValues(alpha: revealProgress);
      canvas.drawRRect(
        RRect.fromRectAndRadius(haloRect, const Radius.circular(6)),
        haloPaint,
      );

      final barPaint = Paint()
        ..color = stageColor.withValues(alpha: revealProgress);
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(5)),
        barPaint,
      );
    }

    // Stage-transition connectors: straight line, opacity fades 0→0.25→0.
    for (var i = 0; i < segments.length - 1; i++) {
      final from = segments[i];
      final to = segments[i + 1];
      final x1 = xOf(from.end);
      final x2 = xOf(to.start);
      final y1 = _rowCenterY(from.type);
      final y2 = _rowCenterY(to.type);
      final fromColor = stageStyles[from.type]?.color ?? haloBackground;
      final toColor = stageStyles[to.type]?.color ?? haloBackground;

      final shader = ui.Gradient.linear(
        Offset(x1, y1),
        Offset(x2, y2),
        [
          fromColor.withValues(alpha: 0),
          fromColor.withValues(alpha: 0.25 * revealProgress),
          toColor.withValues(alpha: 0.25 * revealProgress),
          toColor.withValues(alpha: 0),
        ],
        [0, 0.2, 0.8, 1.0],
      );
      final paint = Paint()
        ..shader = shader
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }

    // Time axis labels.
    if (showTimeAxis) {
      for (final t in ticks) {
        final tp = TextPainter(
          text: TextSpan(
            text: _formatClock(t),
            style: TextStyle(color: textColor, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        var tx = xOf(t) - tp.width / 2;
        tx = tx.clamp(labelColumnWidth, size.width - tp.width);
        tp.paint(canvas, Offset(tx, chartHeight + 4));
      }
    }

    // Scrub guide line + dot.
    final dx = hoverDx;
    if (dx != null && dx >= labelColumnWidth && dx <= size.width) {
      final guidePaint = Paint()
        ..color = textColor.withValues(alpha: 0.5)
        ..strokeWidth = 1;
      _drawDashedLine(
        canvas,
        Offset(dx, 0),
        Offset(dx, chartHeight),
        guidePaint,
      );

      final t = rangeStart.add(
        Duration(
          microseconds: ((dx - labelColumnWidth) / trackWidth * totalMicros)
              .round(),
        ),
      );
      SleepStageSegment? active;
      for (final s in segments) {
        if (!t.isBefore(s.start) && t.isBefore(s.end)) {
          active = s;
          break;
        }
      }
      if (active != null) {
        final dotPaint = Paint()
          ..color = stageStyles[active.type]?.color ?? textColor;
        final ringPaint = Paint()..color = haloBackground;
        final center = Offset(dx, _rowCenterY(active.type));
        canvas.drawCircle(center, 5, ringPaint);
        canvas.drawCircle(center, 3, dotPaint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashLength = 4.0;
    const gapLength = 3.0;
    final total = (b - a).distance;
    final direction = (b - a) / total;
    var traveled = 0.0;
    while (traveled < total) {
      final segEnd = (traveled + dashLength).clamp(0.0, total);
      canvas.drawLine(a + direction * traveled, a + direction * segEnd, paint);
      traveled += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _HypnogramPainter oldDelegate) {
    return segments != oldDelegate.segments ||
        stageStyles != oldDelegate.stageStyles ||
        rowLayout != oldDelegate.rowLayout ||
        haloBackground != oldDelegate.haloBackground ||
        hoverDx != oldDelegate.hoverDx ||
        showTimeAxis != oldDelegate.showTimeAxis ||
        showRowGridLines != oldDelegate.showRowGridLines ||
        showTimeGridLines != oldDelegate.showTimeGridLines ||
        gridLineColor != oldDelegate.gridLineColor ||
        revealProgress != oldDelegate.revealProgress;
  }
}

class _TooltipLayoutDelegate extends SingleChildLayoutDelegate {
  final double anchorDx;
  final double anchorDy;

  _TooltipLayoutDelegate(this.anchorDx, this.anchorDy);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const margin = 4.0;
    var dx = anchorDx - childSize.width / 2;
    final maxDx = size.width - childSize.width - margin;
    dx = dx.clamp(margin, maxDx < margin ? margin : maxDx);

    // Prefer above the anchor row; fall back below if there's no room,
    // then clamp inside the chart's own bounds so it never floats off-screen.
    var dy = anchorDy - childSize.height - 10;
    if (dy < margin) dy = anchorDy + 10;
    final maxDy = size.height - childSize.height - margin;
    dy = dy.clamp(margin, maxDy < margin ? margin : maxDy);
    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(covariant _TooltipLayoutDelegate old) =>
      old.anchorDx != anchorDx || old.anchorDy != anchorDy;
}

class _TooltipBubble extends StatelessWidget {
  final Color color;
  final String label;
  final String timeRange;
  final String duration;
  final HypnogramTooltipConfig config;

  const _TooltipBubble({
    required this.color,
    required this.label,
    required this.timeRange,
    required this.duration,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final ink =
        config.backgroundColor ?? Theme.of(context).colorScheme.inverseSurface;
    final onInk = Theme.of(context).colorScheme.onInverseSurface;
    final labelStyle =
        config.labelStyle ??
        TextStyle(color: onInk, fontWeight: FontWeight.w700, fontSize: 12);
    final detailStyle =
        config.detailStyle ??
        TextStyle(color: onInk.withValues(alpha: 0.85), fontSize: 11);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ink,
        borderRadius: config.borderRadius,
        boxShadow: config.shadow,
      ),
      child: Padding(
        padding: config.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (config.showColorDot)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(label, style: labelStyle),
              ],
            ),
            const SizedBox(height: 2),
            Text(timeRange, style: detailStyle),
            Text(duration, style: detailStyle),
          ],
        ),
      ),
    );
  }
}
