import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

class SimpleTimeSeriesChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  SimpleTimeSeriesChart(this.seriesList, {this.animate});

  /// Creates a [TimeSeriesChart] with sample data and no transition.
  factory SimpleTimeSeriesChart.withSampleData() {
    return new SimpleTimeSeriesChart(
      _createSampleData(),
      // Disable animations for image tests.
      animate: true,
    );
  }


  @override
  Widget build(BuildContext context) {
    return new charts.TimeSeriesChart(
      seriesList,
      animate: animate,
      // Optionally pass in a [DateTimeFactory] used by the chart. The factory
      // should create the same type of [DateTime] as the data provided. If none
      // specified, the default creates local date time.
      dateTimeFactory: const charts.LocalDateTimeFactory(),
    );
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<TimeSeriesCovid, DateTime>> _createSampleData() {
    final data = [
      new TimeSeriesCovid(new DateTime(2017, 9, 19), 5),
      new TimeSeriesCovid(new DateTime(2017, 9, 26), 25),
      new TimeSeriesCovid(new DateTime(2017, 10, 3), 100),
      new TimeSeriesCovid(new DateTime(2017, 10, 10), 75),
    ];

    return [
      new charts.Series<TimeSeriesCovid, DateTime>(
        id: 'Confirmados',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TimeSeriesCovid register, _) => register.time,
        measureFn: (TimeSeriesCovid register, _) => register.cases,
        data: data,
      )
    ];
  }
}

/// Sample time series data type.
class TimeSeriesCovid {
  final DateTime time;
  final int cases;

  TimeSeriesCovid(this.time, this.cases);
}

class SimpleDateTimeFactory implements charts.DateTimeFactory {
  const SimpleDateTimeFactory();

  @override
  DateTime createDateTimeFromMilliSecondsSinceEpoch(
          int millisecondsSinceEpoch) =>
      DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);

  @override
  DateTime createDateTime(int year,
          [int month = 1,
          int day = 1,
          int hour = 0,
          int minute = 0,
          int second = 0,
          int millisecond = 0,
          int microsecond = 0]) =>
      DateTime(
          year, month, day, hour, minute, second, millisecond, microsecond);

  @override
  DateFormat createDateFormat(String pattern) => DateFormat(pattern);
}