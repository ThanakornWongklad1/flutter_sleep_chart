## 0.3.1

* Fixed a `prefer_interpolation_to_compose_strings` lint in
  `_formatDuration` flagged by pub.dev's static analysis.
* Consolidated the example app's Normal/Asleep/In Bed pages and shared
  helpers into a single `main.dart` — pub.dev's Example tab only renders
  that file, not files it imports, so the split across multiple files was
  hiding most of the usage from anyone browsing the package there.

## 0.3.0

* **Breaking:** replaced `haloBackground` with `haloOpacity`. The halo is
  now a true translucent overlay of the stage color (alpha compositing)
  instead of an opaque blend toward an assumed background color, so it
  reads correctly against any background automatically — no more washed-out
  halos when the chart sits on a custom (e.g. dark) background that doesn't
  match `ColorScheme.surface`.
* The scrub dot no longer erases the guide line with an assumed background
  color — the dashed line now leaves a gap around the dot instead, for the
  same background-agnostic reason.
* Added `SleepStageType.asleep` — a coarse fallback for data sources that
  only distinguish asleep/awake without REM/Light/Deep detail. Use it in
  place of `rem`/`light`/`deep`, not alongside them.
* Added `StageStyle.spanRows` — lets a stage type (e.g. `asleep`) skip
  getting its own row and instead render as a translucent halo+bar gradient
  spanning the combined vertical extent of other row types.
* Added `StageStyle.gradientRows` — lets the `spanRows` gradient's colors
  (first → last) differ from the rows it visually spans, e.g. spanning
  REM/Light/Deep's full height while gradienting only REM → Light.
* Added `SleepStageType.inBed` — the overall in-bed span, an ordinary stage
  type with its own row, independent of `asleep` and the finer stages.
* Fixed stage-transition connector lines drawing between segments that
  merely sit next to each other in the list but aren't actually
  back-to-back in time (e.g. a spanning `inBed` row overlapping the whole
  night) — connectors now only draw between segments where one ends
  exactly where the next begins.
* `asleep`/`inBed` now work with zero extra config: if `segments` uses
  either type and `stageStyles` doesn't define it, `HypnogramChart`
  automatically backfills it from `kFallbackHypnogramStageStyles` (sensible
  built-in color/label/`spanRows`/`gradientRows`). Exposed the merge logic
  as `resolveStageStyles(stageStyles, segments)` for building a matching
  `HypnogramLegend` alongside a chart that relies on the defaults.
* Fixed `showTimeAxis`/`showTimeGridLines` labels overlapping/garbling on
  wide time ranges (e.g. a 12-hour span) — hourly ticks now thin out
  automatically to whatever actually fits without overlapping.
* Added `minHeight` — when the natural row stack (e.g. a single `inBed`-only
  row) is shorter than this, the rows are centered within it instead of the
  chart just being that short. No effect once rows already exceed it.
* **Breaking:** `showRowGridLines`/`showTimeGridLines` now default to
  `true` (previously `false`), and `showTimeGridLines` now draws dashed
  lines (previously solid) to read distinctly from the solid row dividers.

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
