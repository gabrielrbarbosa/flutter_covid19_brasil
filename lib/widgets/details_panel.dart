import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';

class Details extends StatelessWidget {
  final Function configMarkers, searchLocation, goToLocation;
  final Map report, reportBR;
  final int minCasesCity, countBRcities;

  Details({Key key, this.configMarkers, this.searchLocation, this.goToLocation, this.countBRcities, this.report, this.reportBR, this.minCasesCity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[ 
                Expanded( // wrap your Column in Expanded
                  child: Column(
                  children: <Widget>[
                    SizedBox(height: 10,),
                    TypeAheadFormField(
                    textFieldConfiguration: TextFieldConfiguration(
                      autofocus: false,
                      style: DefaultTextStyle.of(context).style.copyWith(
                        fontStyle: FontStyle.normal
                      ),
                      decoration: InputDecoration(
                        labelText: 'Pesquisar (País, Estado ou Cidade):'
                      )
                    ),
                    suggestionsCallback: (pattern) async {
                      return await this.searchLocation(pattern);
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        leading: Icon(Icons.location_on),
                        title: Text(suggestion)
                      );
                    },
                    onSuggestionSelected: (suggestion) {
                      this.goToLocation(suggestion);
                    },
                    hideOnError: true,
                    hideSuggestionsOnKeyboardHide: true,
                    noItemsFoundBuilder: (BuildContext context){
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Nenhuma localidade encontrada',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Theme.of(context).disabledColor, fontSize: 18.0),
                        ),
                      );
                    },
                  )
                ],
            ))]),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children:<Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 5.0, left: 16.0),
                child: Text(countBRcities.toString() + ' municípios brasileiros no mapa. Filtrar por: '),
              )
            ]
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Radio(
                value: 10000,
                groupValue: minCasesCity,
                onChanged: (value){
                  this.configMarkers(value);
                }
              ),
              Text(
                '10 mil Casos',
                style: Theme.of(context).textTheme.caption,
              ),
              Radio(
                value: 50000,
                groupValue: minCasesCity,
                onChanged: (value){
                  this.configMarkers(value);
                }
              ),
              Text(
                '50 mil',
                style: Theme.of(context).textTheme.caption,
              ),
              Radio(
                value: 100000,
                groupValue: minCasesCity,
                onChanged: (value){
                  this.configMarkers(value);
                }
              ),
              Text(
                '100 mil',
                style: Theme.of(context).textTheme.caption,
              ),
            ]
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children:<Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Informações - Brasil'),
              ),
            ]
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
                //createDetailItem(context: context, value: formatted(reportBR['tests']), text: "Testes Realizados"),
                //createDetailItem(context: context, value: reportBR['fatality'].toString() + "%", text: "Letalidade Atual"),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children:<Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Informações - Global'),
              ),
            ]
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
                //createDetailItem(context: context, value: formatted(report['tests']), text: "Testes Realizados"),
                //createDetailItem(context: context, value: report['fatality'].toString() + "%", text: "Letalidade Atual"),
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
                style: Theme.of(context).textTheme.headline5,
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