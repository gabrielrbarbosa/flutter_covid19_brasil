import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Details extends StatelessWidget {
  final Map report;
  final Map reportBR;
  Details({Key key, @required this.report, @required this.reportBR}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 15.0,
          ),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                createDetailItem(context: context, color: Colors.red, value: formatted(reportBR['cases']), text: "Total Confirmados"),
                createDetailItem(context: context, color: Colors.yellow[800], value: formatted(reportBR['deaths']), text: "Casos Fatais"),
              ],
            ),
          ),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                createDetailItem(context: context, color: Colors.blue, value: formatted(reportBR['active']), text: "Casos Ativos"),
                createDetailItem(context: context, color: Colors.green[500], value: formatted(reportBR['recovered']), text: "Casos Recuperados"),
              ],
            ),
          ),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                createDetailItem(context: context, value: formatted(reportBR['tests']), text: "Testes Realizados"),
                createDetailItem(context: context, value: reportBR['fatality'].toString() + "%", text: "Letalidade Atual"),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.all(6.0),
            padding: EdgeInsets.all(6.0),
            child:
              Text(
                'Casos por 1 milhão de habitantes: ' + formatted(reportBR['casesPerOneMillion']) +
                '\nMortes por 1 milhão de habitantes: ' + formatted(reportBR['deathsPerOneMillion']) +
                '\nTestes por 1 milhão de habitantes: ' + formatted(reportBR['testsPerOneMillion']),
                style: Theme.of(context).textTheme.caption,
              ),
            ),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                createDetailItem(context: context, color: Colors.red, value: formatted(report['cases']), text: "Global Confirmados"),
                createDetailItem(context: context, color: Colors.yellow[800], value: formatted(report['deaths']), text: "Global Fatais"),
              ],
            ),
          ),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                createDetailItem(context: context, color: Colors.blue, value: formatted(report['active']), text: "Global Ativos"),
                createDetailItem(context: context, color: Colors.green[500], value: formatted(report['recovered']), text: "Global Recuperados"),
              ],
            ),
          ),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                createDetailItem(context: context, value: formatted(report['tests']), text: "Testes Realizados"),
                createDetailItem(context: context, value: report['fatality'].toString() + "%", text: "Letalidade Atual"),
              ],
            ),
          ),
        ],
      )
    );
  }
}

Widget createDetailItem({BuildContext context, String value, Color color, String text}) {
  return Expanded(
      child: Container(
      margin: EdgeInsets.only(left: 12, right: 12, bottom: 4, top: 4),
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        border: Border.all(color: Colors.grey, width: 0.5),
        borderRadius: BorderRadius.all(Radius.circular(5.0))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              color != null ? Container(
                margin: EdgeInsets.only(right: 8.0),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: color ?? Colors.transparent,
                  borderRadius: BorderRadius.circular(2.0)
                ),
              ) : SizedBox(),
              Text(
                '$text',
                style: Theme.of(context).textTheme.caption,
              ),
            ],
          ),
          SizedBox(
            height: 5.0,
          ),
          Row(
            children: <Widget>[
              Text(
                '$value',
                style: Theme.of(context)
                    .textTheme
                    .headline5,
              ),
            ],
          )
        ],
      ),
    ),
  );
}

String formatted(int val){
  return new NumberFormat.decimalPattern('pt').format(val).toString();
}