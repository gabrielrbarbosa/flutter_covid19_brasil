import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class SimpleTimeSeriesChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  SimpleTimeSeriesChart(this.seriesList, {this.animate});

  @override
  Widget build(BuildContext context) {
    return new charts.TimeSeriesChart(
      seriesList,
      animate: animate,
      dateTimeFactory: const charts.LocalDateTimeFactory(),
    );
  }
}

class TimeSeriesCovid {
  final DateTime time;
  final int cases;

  TimeSeriesCovid(this.time, this.cases);
}

class TimeSeriesCovidDouble {
  final DateTime time;
  final double ratio;

  TimeSeriesCovidDouble(this.time, this.ratio);
}