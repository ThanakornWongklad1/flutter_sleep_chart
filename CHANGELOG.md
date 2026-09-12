## 0.2.0

* Added `onSegmentTap` — called with the segment under the pointer on every
  pointer-down.
* Added `showTimeAxis`/`timeAxisHeight` for hour-aligned clock labels below
  the chart.
* Added `showRowGridLines`/`showTimeGridLines`/`gridLineColor` for optional
  row-divider and hourly grid lines.
* Added `HypnogramLegend`, a standalone color-dot + label legend widget for
  a `stageStyles` map.
* Added `interactionMode` (`HypnogramInteractionMode.scrub` (default) or
  `.tap`) — `.tap` ignores pointer-move so the chart doesn't fight a
  scrollable/draggable parent.
* Added `enableAnimation`/`animationDuration`/`animationCurve` — bars now
  animate in on first render and whenever `segments` changes (on by
  default).
* Added `emptyBuilder` for a custom placeholder when `segments` is empty.

## 0.1.0

* **Breaking:** replaced the `colors`/`stageOrder`/`labels` maps with a
  single `stageStyles: Map<SleepStageType, StageStyle>` — color, label, and
  an optional per-stage `rowHeight` override, in one place. Row order now
  follows the map's iteration order.
* Added `HypnogramTooltipConfig` (`tooltip:` param) to customize the scrub
  tooltip: per-field text overrides (`labelText`/`timeRangeText`/
  `durationText`), bubble styling (background, text styles, padding, border
  radius, shadow, color-dot toggle), or a full `builder` override.
* Added `labelColumnWidth` param (previously a hardcoded constant).
* Fixed the tooltip floating above the chart's own bounds — it now clamps
  to the chart area and flips below the anchor row when there's no room
  above.

## 0.0.1

* Initial release: `HypnogramChart` widget — per-stage rows with glassy halo
  bars, gradient stage-transition connectors, minimum-width clamping for
  short segments, and a scrub tooltip (hover/tap/drag) with a guide line and
  stage-colored dot.
