import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Details extends StatelessWidget {
  final Map report;
  Details({Key key, @required this.report}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 10.0,
          ),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                createDetailItem(context: context, color: Colors.red, value: formatted(report['cases']), text: "Total Confirmados"),
                createDetailItem(context: context, color: Colors.yellow[800], value: formatted(report['deaths']), text: "Casos Fatais"),
                
              ],
            ),
          ),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                createDetailItem(context: context, color: Colors.blue, value: formatted(report['active']), text: "Casos Ativos"),
                createDetailItem(context: context, color: Colors.green[500], value: formatted(report['recovered']), text: "Casos Recuperados"),
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

          Container(
            margin: EdgeInsets.all(6.0),
            padding: EdgeInsets.all(6.0),
              child:
                Text(
                  'Casos por 1 milhão de habitantes: ' + formatted(report['casesPerOneMillion']) +
                  '\n\nMortes por 1 milhão de habitantes: ' + formatted(report['deathsPerOneMillion']) +
                  '\n\nTestes por 1 milhão de habitantes: ' + formatted(report['testsPerOneMillion']) +
                  '\n\nVeja informações por cidades ou estados em Estatísticas',
                  style: Theme.of(context).textTheme.caption,
                ),
                ),
              ],
            ),
    );
  }
}

Widget createDetailItem({BuildContext context, String value, Color color, String text}) {
  return Expanded(
      child: Container(
      margin: EdgeInsets.all(12.0),
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
                width: 15,
                height: 15,
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
            height: 10.0,
          ),
          Row(
            children: <Widget>[
              Text(
                '$value',
                style: Theme.of(context)
                    .textTheme
                    .headline,
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