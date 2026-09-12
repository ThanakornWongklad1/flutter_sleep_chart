import 'package:flutter/material.dart';
import 'package:hypnogram_chart/hypnogram_chart.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

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
      SleepStageSegment(type: SleepStageType.awake, start: at(20), end: at(21.25)),
      SleepStageSegment(type: SleepStageType.rem, start: at(21.25), end: at(22.5)),
      SleepStageSegment(type: SleepStageType.awake, start: at(22.5), end: at(23.75)),
      SleepStageSegment(type: SleepStageType.rem, start: at(23.75), end: at(25)),
      SleepStageSegment(type: SleepStageType.light, start: at(25), end: at(45)),
      SleepStageSegment(type: SleepStageType.deep, start: at(45), end: at(90)),
      SleepStageSegment(type: SleepStageType.light, start: at(90), end: at(120)),
      SleepStageSegment(type: SleepStageType.rem, start: at(120), end: at(150)),
      SleepStageSegment(type: SleepStageType.light, start: at(150), end: at(185)),
      SleepStageSegment(type: SleepStageType.deep, start: at(185), end: at(220)),
      SleepStageSegment(type: SleepStageType.light, start: at(220), end: at(250)),
      SleepStageSegment(type: SleepStageType.awake, start: at(250), end: at(255)),
    ];

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('hypnogram_chart example')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: HypnogramChart(segments: segments),
        ),
      ),
    );
  }
}
