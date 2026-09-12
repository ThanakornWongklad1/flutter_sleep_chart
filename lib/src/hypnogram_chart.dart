import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'sleep_stage.dart';

/// Default stage -> color mapping.
const kDefaultHypnogramColors = <SleepStageType, Color>{
  SleepStageType.awake: Color(0xFFF2994A),
  SleepStageType.rem: Color(0xFF9B6BD9),
  SleepStageType.light: Color(0xFF4F8FE8),
  SleepStageType.deep: Color(0xFF2C3E8C),
};

/// Default vertical order, top to bottom: awake, rem, light, deep.
const kDefaultHypnogramOrder = <SleepStageType, int>{
  SleepStageType.awake: 0,
  SleepStageType.rem: 1,
  SleepStageType.light: 2,
  SleepStageType.deep: 3,
};

/// Default row labels.
const kDefaultHypnogramLabels = <SleepStageType, String>{
  SleepStageType.awake: 'Awake',
  SleepStageType.rem: 'REM',
  SleepStageType.light: 'Light',
  SleepStageType.deep: 'Deep',
};

const _trackLeftPx = 64.0;

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

/// An Apple Health-style hypnogram: one glassy-halo bar row per stage, with
/// gradient connectors between transitions and a scrub tooltip on
/// hover/tap/drag.
class HypnogramChart extends StatefulWidget {
  final List<SleepStageSegment> segments;
  final Map<SleepStageType, Color> colors;
  final Map<SleepStageType, int> stageOrder;
  final Map<SleepStageType, String> labels;
  final double rowHeight;
  final double barHeight;
  final double haloPad;
  final double minBarWidth;
  final bool enableTooltip;

  /// Base color the halo is blended toward (32% stage color, 68% this).
  /// Defaults to the ambient [ColorScheme.surface].
  final Color? haloBackground;

  const HypnogramChart({
    super.key,
    required this.segments,
    this.colors = kDefaultHypnogramColors,
    this.stageOrder = kDefaultHypnogramOrder,
    this.labels = kDefaultHypnogramLabels,
    this.rowHeight = 40,
    this.barHeight = 20,
    this.haloPad = 2,
    this.minBarWidth = 1,
    this.enableTooltip = true,
    this.haloBackground,
  });

  @override
  State<HypnogramChart> createState() => _HypnogramChartState();
}

class _HypnogramChartState extends State<HypnogramChart> {
  late List<SleepStageSegment> _merged;
  Offset? _hoverLocal;
  SleepStageSegment? _hoverSeg;

  @override
  void initState() {
    super.initState();
    _merged = _mergeAdjacent(widget.segments);
  }

  @override
  void didUpdateWidget(covariant HypnogramChart old) {
    super.didUpdateWidget(old);
    if (old.segments != widget.segments) {
      _merged = _mergeAdjacent(widget.segments);
      _hoverLocal = null;
      _hoverSeg = null;
    }
  }

  int get _rowCount {
    if (widget.stageOrder.isEmpty) return 1;
    return widget.stageOrder.values.reduce((a, b) => a > b ? a : b) + 1;
  }

  void _updateHover(Offset local, double width) {
    if (_merged.isEmpty) return;
    final trackWidth = width - _trackLeftPx;
    if (trackWidth <= 0) {
      _clearHover();
      return;
    }
    final frac = (local.dx - _trackLeftPx) / trackWidth;
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
    final rowCount = _rowCount;
    final totalHeight = widget.rowHeight * rowCount;
    final haloBackground =
        widget.haloBackground ?? Theme.of(context).colorScheme.surface;

    if (widget.segments.isEmpty) {
      return SizedBox(height: totalHeight, width: double.infinity);
    }

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return MouseRegion(
            onExit: (_) => _clearHover(),
            child: Listener(
              onPointerHover: (e) => _updateHover(e.localPosition, width),
              onPointerDown: (e) => _updateHover(e.localPosition, width),
              onPointerMove: (e) => _updateHover(e.localPosition, width),
              onPointerUp: (_) => _clearHover(),
              onPointerCancel: (_) => _clearHover(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CustomPaint(
                    size: Size(width, totalHeight),
                    painter: _HypnogramPainter(
                      segments: _merged,
                      colors: widget.colors,
                      stageOrder: widget.stageOrder,
                      labels: widget.labels,
                      rowHeight: widget.rowHeight,
                      barHeight: widget.barHeight,
                      haloPad: widget.haloPad,
                      minBarWidth: widget.minBarWidth,
                      haloBackground: haloBackground,
                      textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      hoverDx: _hoverLocal?.dx,
                    ),
                  ),
                  if (widget.enableTooltip &&
                      _hoverSeg != null &&
                      _hoverLocal != null)
                    Positioned.fill(
                      child: CustomSingleChildLayout(
                        delegate: _TooltipLayoutDelegate(
                          _hoverLocal!.dx,
                          (widget.stageOrder[_hoverSeg!.type] ?? 0) *
                                  widget.rowHeight +
                              widget.rowHeight / 2,
                        ),
                        child: _TooltipBubble(
                          color: widget.colors[_hoverSeg!.type] ??
                              haloBackground,
                          label: widget.labels[_hoverSeg!.type] ?? '',
                          timeRange:
                              '${_formatClock(_hoverSeg!.start)} – ${_formatClock(_hoverSeg!.end)}',
                          duration: _formatDuration(_hoverSeg!.duration),
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
  final Map<SleepStageType, Color> colors;
  final Map<SleepStageType, int> stageOrder;
  final Map<SleepStageType, String> labels;
  final double rowHeight;
  final double barHeight;
  final double haloPad;
  final double minBarWidth;
  final Color haloBackground;
  final Color textColor;
  final double? hoverDx;

  _HypnogramPainter({
    required this.segments,
    required this.colors,
    required this.stageOrder,
    required this.labels,
    required this.rowHeight,
    required this.barHeight,
    required this.haloPad,
    required this.minBarWidth,
    required this.haloBackground,
    required this.textColor,
    required this.hoverDx,
  });

  double _rowCenterY(SleepStageType type) =>
      (stageOrder[type] ?? 0) * rowHeight + rowHeight / 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final rangeStart = segments.first.start;
    final rangeEnd = segments.last.end;
    final totalMicros = rangeEnd.difference(rangeStart).inMicroseconds;
    if (totalMicros <= 0) return;

    final trackWidth = size.width - _trackLeftPx;

    // Row labels.
    for (final entry in stageOrder.entries) {
      final tp = TextPainter(
        text: TextSpan(
          text: labels[entry.key] ?? '',
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      )..layout(maxWidth: _trackLeftPx - 12);
      final y = _rowCenterY(entry.key) - tp.height / 2;
      tp.paint(canvas, Offset(_trackLeftPx - 12 - tp.width, y));
    }

    double xOf(DateTime t) =>
        _trackLeftPx +
        t.difference(rangeStart).inMicroseconds / totalMicros * trackWidth;

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

      final centerY = _rowCenterY(seg.type);
      final barRect = Rect.fromLTWH(
        left,
        centerY - barHeight / 2,
        width,
        barHeight,
      );
      final haloRect = barRect.inflate(haloPad);
      final stageColor = colors[seg.type] ?? haloBackground;

      final haloPaint = Paint()
        ..color = Color.lerp(stageColor, haloBackground, 0.68)!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(haloRect, const Radius.circular(6)),
        haloPaint,
      );

      final barPaint = Paint()..color = stageColor;
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
      final fromColor = colors[from.type] ?? haloBackground;
      final toColor = colors[to.type] ?? haloBackground;

      final shader = ui.Gradient.linear(
        Offset(x1, y1),
        Offset(x2, y2),
        [
          fromColor.withValues(alpha: 0),
          fromColor.withValues(alpha: 0.25),
          toColor.withValues(alpha: 0.25),
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

    // Scrub guide line + dot.
    final dx = hoverDx;
    if (dx != null && dx >= _trackLeftPx && dx <= size.width) {
      final guidePaint = Paint()
        ..color = textColor.withValues(alpha: 0.5)
        ..strokeWidth = 1;
      _drawDashedLine(
        canvas,
        Offset(dx, 0),
        Offset(dx, size.height),
        guidePaint,
      );

      final t = rangeStart.add(
        Duration(
          microseconds:
              ((dx - _trackLeftPx) / trackWidth * totalMicros).round(),
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
        final dotPaint = Paint()..color = colors[active.type] ?? textColor;
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
      canvas.drawLine(
        a + direction * traveled,
        a + direction * segEnd,
        paint,
      );
      traveled += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _HypnogramPainter oldDelegate) {
    return segments != oldDelegate.segments ||
        colors != oldDelegate.colors ||
        stageOrder != oldDelegate.stageOrder ||
        haloBackground != oldDelegate.haloBackground ||
        hoverDx != oldDelegate.hoverDx;
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

  const _TooltipBubble({
    required this.color,
    required this.label,
    required this.timeRange,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.inverseSurface;
    final onInk = Theme.of(context).colorScheme.onInverseSurface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: onInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              timeRange,
              style: TextStyle(color: onInk.withValues(alpha: 0.85), fontSize: 11),
            ),
            Text(
              duration,
              style: TextStyle(color: onInk.withValues(alpha: 0.85), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
