import 'dart:math';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:charts_common/common.dart';
import 'package:charts_flutter/src/text_element.dart' as txt;
import 'package:charts_flutter/src/text_style.dart' as style;

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

class CustomCircleSymbolRenderer extends charts.CircleSymbolRenderer {
  @override
  void paint(charts.ChartCanvas canvas, Rectangle bounds, {List dashPattern, Color fillColor, FillPatternType fillPattern, Color strokeColor, double strokeWidthPx}) {
    super.paint(canvas, bounds, dashPattern: dashPattern, fillColor: fillColor, strokeColor: strokeColor, strokeWidthPx: strokeWidthPx);
    
    var textStyle = style.TextStyle();
    textStyle.color = Color.black;
    textStyle.fontSize = 15;

    canvas.drawText(
      txt.TextElement(ToolTipMgr.title, style: textStyle),
      (bounds.left - 16).round(),
      (bounds.top - 25).round()
    );
  }
}

String _title, _subtitle;

class ToolTipMgr {

  static String get title => _title;
  static String get subtitle => _subtitle;

  static setTitle(Map<String, dynamic> data) {
    if (data['title'] != null && data['title'].length > 0) {
      _title = data['title'];
    }
    if (data['subTitle'] != null && data['subTitle'].length > 0) {
      _subtitle = data['subTitle'];
    }
  }

}