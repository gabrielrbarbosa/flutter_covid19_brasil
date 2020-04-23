import 'package:date_format/date_format.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:loading_overlay/loading_overlay.dart';
import 'package:intl/intl.dart';
import '../model/line_chart.dart';

class ChartsPage extends StatefulWidget {
  @override
  _ChartsPageState createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  String chartIndex = 'Casos Confirmados';
  bool showChart = false, _loading = true, showBarChart = false;

  List<TimeSeriesCovid> lineTotalCases = [], lineNewCases = [], lineTotalDeaths = [], lineNewDeaths = [];
  List<charts.Series<dynamic, DateTime>> lineChart = [];

  String _selectedType = 'País', _selectedRegion = 'TOTAL', _lastSelectedLocation, _pointSelected, errorMsg;
  List<String> _locations = ['País', 'Estados', 'Cidades'], _locationsStates = [], _locationsRegions = [], _locationsCities = [], _locationsCitiesLoad = [];
  List fileDataCities, fileDataStates;
  DateTime _timeSelected;

  void initState() {  
    super.initState();
    downloadFiles();
  }

  void downloadFiles() async{
    fetchCsvFile('https://raw.githubusercontent.com/wcota/covid19br/master/cases-brazil-states.csv', 'cases-brazil-states.csv');
    fetchCsvFile('https://raw.githubusercontent.com/wcota/covid19br/master/cases-brazil-cities-time_changesOnly.csv', 'cases-brazil-cities-time.csv');
  }

  fetchCsvFile(link, filename) async {      
    final response = await http.get(link);
    
    if (response.statusCode == 200) {
      var txt = response.body;
      _createChart(txt, filename);
    } else {
      setState(() {
        errorMsg = 'Erro (' + response.statusCode.toString() + '): ' + response.body;
      });
      throw Exception('Erro ao carregar informações.');
    }
  }

  void _createChart(txt, filename){
    
    if(filename == "cases-brazil-cities-time.csv"){
      fileDataCities = txt.split("\n");
      List columnTitles = fileDataCities[0].split(",");
      int count = 1;

      fileDataCities.forEach((strRow){
        if(strRow == "") return false;

        // Get all locations and store in dropdown list
        if(count > 1){
          var info = strRow.split(",");

          if(!info[columnTitles.indexOf("city")].contains("SEM LOCALIZAÇÃO DEFINIDA")){
            if(!_locationsCitiesLoad.contains(info[columnTitles.indexOf("city")])){
              _locationsCitiesLoad.add(info[columnTitles.indexOf("city")]);
            } else if(_locationsCitiesLoad.contains(info[columnTitles.indexOf("city")]) && !_locationsCities.contains(info[columnTitles.indexOf("city")])){
              _locationsCities.add(info[columnTitles.indexOf("city")]);
            }
          }
        }
        count++;
        _locationsCities.sort((a, b) => a.toString().compareTo(b.toString()));
        return true;
      });

      setState(() {
        _locationsCities = _locationsCities;
      });
      updateChartInfo();
    } 
    else if(filename == "cases-brazil-states.csv"){
      fileDataStates = txt.split("\n");
      List columnTitles = fileDataStates[0].split(",");
      int count = 1;

      fileDataStates.forEach((strRow){
        if(strRow == "") return false;

        if(count > 1){
          var info = strRow.split(",");
          if(!_locationsStates.contains(info[columnTitles.indexOf("state")]) && info[columnTitles.indexOf("state")] != "TOTAL"){
            _locationsStates.add(info[columnTitles.indexOf("state")]);
          }
        }
        count++;
        _locationsStates.sort((a, b) => a.toString().compareTo(b.toString()));
        return true;
      });

      setState(() {
        _locationsStates = _locationsStates;
      });
      updateChartInfo();
    }
  }

  void updateChartInfo(){
    int count = 1, index;
    List<TimeSeriesCovid> totalCases = [], newCases = [], totalDeaths = [], newDeaths = [];
    List fileData, columnTitles;

    switch(_selectedType){
      case 'País':
        if(fileDataStates.length > 0){
          fileData = fileDataStates;
          columnTitles = fileData[0].split(",");
          index = columnTitles.indexOf("state");
        }
        setState(() {
          if(_locationsRegions != _locationsStates){
            _locationsRegions = _locationsStates;
            chartIndex = 'Casos Confirmados';
          }
          if(_lastSelectedLocation != _selectedType){
            _selectedRegion = 'TOTAL';
            _lastSelectedLocation = _selectedType;
          }
        });
      break;
      case 'Estados':
        if(fileDataStates.length > 0){
          fileData = fileDataStates;
          columnTitles = fileData[0].split(",");
          index = columnTitles.indexOf("state");
        }
        setState(() {
          if(_locationsRegions != _locationsStates){
            _locationsRegions = _locationsStates;
            chartIndex = 'Casos Confirmados';
          }
          if(_lastSelectedLocation != _selectedType){
            _selectedRegion = 'PR';
            _lastSelectedLocation = _selectedType;
          }
        });
      break;
      case 'Cidades':
        if(fileDataStates.length > 0){
          fileData = fileDataCities;
          columnTitles = fileData[0].split(",");
          index = columnTitles.indexOf("city");
        }
        setState(() {
          if(_locationsRegions != _locationsCities){
            _locationsRegions = _locationsCities;
            chartIndex = 'Casos Confirmados';
          }
          if(_lastSelectedLocation != _selectedType){
            _selectedRegion = "Londrina/PR";
            _lastSelectedLocation = _selectedType;
          }
        });
      break;
    }
    
    fileData.forEach((strRow){
      if(strRow == ""){
        return false;
      }

      var info = strRow.split(",");
      if(count > 1){
        if(info[index] == _selectedRegion){
          String date = info[columnTitles.indexOf('date')];
          if(columnTitles.indexOf('totalCases') != -1) totalCases.add(new TimeSeriesCovid(DateTime.parse(date), int.parse(info[columnTitles.indexOf('totalCases')])));
          if(columnTitles.indexOf('newCases') != -1) newCases.add(new TimeSeriesCovid(DateTime.parse(date), int.parse(info[columnTitles.indexOf('newCases')])));
          if(columnTitles.indexOf('deaths') != -1) totalDeaths.add(new TimeSeriesCovid(DateTime.parse(date), int.parse(info[columnTitles.indexOf('deaths')])));
          if(columnTitles.indexOf('newDeaths') != -1) newDeaths.add(new TimeSeriesCovid(DateTime.parse(date), int.parse(info[columnTitles.indexOf('newDeaths')])));
          return true;
        }
      }
      count++;
      return false;
    });
    setState(() {
      lineTotalCases = totalCases;
      lineNewCases = newCases;
      lineTotalDeaths = totalDeaths;
      lineNewDeaths = newDeaths;
      showChart = true;
      _loading = false;
    });
  }

  getSuggestions(pattern) async{
    if(pattern.length > 0){
      return _locationsRegions.where((i) => i.toLowerCase().contains(pattern.toLowerCase())).toList();
    } else{
      return [];
    }
  }

  _onSelectionChanged(charts.SelectionModel model) {
    final selectedDatum = model.selectedDatum;

    DateTime time;
    String selected;

    // We get the model that updated with a list of [SeriesDatum] which is
    // simply a pair of series & datum.
    //
    // Walk the selection updating the measures map, storing off the sales and
    // series name for each selection point.
    if (selectedDatum.isNotEmpty) {
      time = selectedDatum.first.datum.time;
      selectedDatum.forEach((charts.SeriesDatum datumPair) {
        selected = datumPair.datum.cases.toString();
      });
    }

    // Request a build.
    setState(() {
      _timeSelected = time;
      _pointSelected = selected;
    });
  }

  String formatted(String str){
    int val = int.parse(str);
    return new NumberFormat.decimalPattern('pt').format(val).toString();
  }

  @override
  Widget build(BuildContext context) {

    switch(chartIndex){
      case 'Casos Confirmados':
        lineChart = [charts.Series<TimeSeriesCovid, DateTime>(
            id: chartIndex,
            colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
            domainFn: (TimeSeriesCovid register, _) => register.time,
            measureFn: (TimeSeriesCovid register, _) => register.cases,
            data: lineTotalCases,
          )
        ];
        setState(() {
          showBarChart = false;
        });
      break;
      case 'Novos Casos':
        lineChart = [charts.Series<TimeSeriesCovid, DateTime>(
            id: chartIndex,
            colorFn: (_, __) => charts.MaterialPalette.cyan.shadeDefault,
            domainFn: (TimeSeriesCovid register, _) => register.time,
            measureFn: (TimeSeriesCovid register, _) => register.cases,
            data: lineNewCases,
          ),
        ];
        setState(() {
          showBarChart = true;
        });
      break;
      case 'Óbitos Confirmados':
        lineChart = [charts.Series<TimeSeriesCovid, DateTime>(
            id: chartIndex,
            colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
            domainFn: (TimeSeriesCovid register, _) => register.time,
            measureFn: (TimeSeriesCovid register, _) => register.cases,
            data: lineTotalDeaths,
          ),
        ];
        setState(() {
          showBarChart = false;
        });
      break;
      case 'Novos Óbitos':
        lineChart = [charts.Series<TimeSeriesCovid, DateTime>(
            id: chartIndex,
            colorFn: (_, __) => charts.MaterialPalette.cyan.shadeDefault,
            domainFn: (TimeSeriesCovid register, _) => register.time,
            measureFn: (TimeSeriesCovid register, _) => register.cases,
            data: lineNewDeaths,
          ),
        ];
        setState(() {
          showBarChart = true;
        });
      break;
    }

    return Scaffold(
      body: LoadingOverlay(
        child:
        SafeArea(
          child:
          Container(
          child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: 
                    <Widget>[ 
                      DropdownButton(
                        value: _selectedType,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedType = newValue;
                            _timeSelected = null;
                          });
                          updateChartInfo();
                        },
                        items: _locations.map((location) {
                          return DropdownMenuItem(
                            child: new Text(location),
                            value: location,
                          );
                        }).toList(),
                      ),
                      if(_selectedType != 'País') 
                      (DropdownButton(
                        value: _selectedRegion,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedRegion = newValue;
                            _timeSelected = null;
                          });
                          updateChartInfo();
                        },
                        items: _locationsRegions.map((location) {
                          return DropdownMenuItem(
                            child: new Text(location),
                            value: location,
                          );
                        }).toList(),
                      )
                    )
                  ])
                ),
                    
              if(_selectedType != 'País')
              (Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                child:
                Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[ 
                  Expanded( // wrap your Column in Expanded
                    child: Column(
                    children: <Widget>[
                      TypeAheadFormField(
                      textFieldConfiguration: TextFieldConfiguration(
                        autofocus: false,
                        style: DefaultTextStyle.of(context).style.copyWith(
                          fontStyle: FontStyle.normal
                        ),
                        decoration: InputDecoration(
                          labelText: 'Pesquisar:'
                        )
                      ),
                      suggestionsCallback: (pattern) async {
                        return await getSuggestions(pattern);
                      },
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          leading: Icon(Icons.location_on),
                          title: Text(suggestion)
                        );
                      },
                      onSuggestionSelected: (suggestion) {
                        setState(() {
                          _selectedRegion = suggestion;
                        });
                        updateChartInfo();
                      },
                      hideOnError: true,
                      hideSuggestionsOnKeyboardHide: true,
                  )],
                ))])
              )),
                
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: 
                  <Widget>[ 
                    if(lineTotalCases != null) FlatButton(
                      shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.black45),
                          borderRadius: BorderRadius.all(Radius.circular(3))),
                      child: Text(
                        'Casos Confirmados',
                        style: TextStyle(
                            color:
                            chartIndex == 'Casos Confirmados' ? Colors.black : Colors.black12),
                      ),
                      onPressed: () {
                        setState(() {
                          chartIndex = 'Casos Confirmados';
                          _timeSelected = null;
                        });
                      },
                    ),
                    if(lineNewCases != null) FlatButton(
                      shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.black45),
                          borderRadius: BorderRadius.all(Radius.circular(3))),
                      child: Text('Novos Casos',
                          style: TextStyle(
                              color: chartIndex == 'Novos Casos'
                                  ? Colors.black
                                  : Colors.black12)),
                      onPressed: () {
                        setState(() {
                          chartIndex = 'Novos Casos';
                          _timeSelected = null;
                        });
                      },
                    ),
                  ]),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: 
                  <Widget>[ 
                    if(lineTotalDeaths != null) FlatButton(
                      shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.black45),
                          borderRadius: BorderRadius.all(Radius.circular(3))),
                      child: Text(
                        'Óbitos Confirmados',
                        style: TextStyle(
                            color:
                            chartIndex == 'Óbitos Confirmados' ? Colors.black : Colors.black12),
                      ),
                      onPressed: () {
                        setState(() {
                          chartIndex = 'Óbitos Confirmados';
                          _timeSelected = null;
                        });
                      },
                    ),
                    if(lineNewDeaths != null) FlatButton(
                      shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.black45),
                          borderRadius: BorderRadius.all(Radius.circular(3))),
                      child: Text(
                        'Novos Óbitos',
                        style: TextStyle(
                            color:
                            chartIndex == 'Novos Óbitos' ? Colors.black : Colors.black12),
                      ),
                      onPressed: () {
                        setState(() {
                          chartIndex = 'Novos Óbitos';
                          _timeSelected = null;
                        });
                      },
                    ),
                  ]),
              ),
              if(errorMsg != null)
              (AlertDialog(
                title: Text('Aviso'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      Text(errorMsg),
                      Text('Verifique sua conexão com a Internet ou tente novamente mais tarde.'),
                    ],
                  ),
                ),
                actions: <Widget>[
                  FlatButton(
                    child: Text('OK'),
                    onPressed: () {
                      setState(() {
                        errorMsg = null;
                      });
                    },
                  ),
                ],
              )),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: showChart ? 
                  (new charts.TimeSeriesChart(
                    lineChart,
                    animate: false,
                    defaultRenderer: (showBarChart ? new charts.BarRendererConfig<DateTime>() : new charts.LineRendererConfig(includePoints: true, includeLine: true)),
                    dateTimeFactory: SimpleDateTimeFactory(),
                    selectionModels: [
                      new charts.SelectionModelConfig(
                        type: charts.SelectionModelType.info,
                        changedListener: _onSelectionChanged,
                      )
                    ],
                  )) :
                  (Center(
                      child: Text(
                        "Carregando os dados...",
                        textAlign: TextAlign.center,
                      ),
                    )
                  ), 
                )),
                Center(
                  child:
                    Padding(
                    padding: new EdgeInsets.all(16.0),
                    child: Text(
                      _timeSelected != null ? 
                      formatted(_pointSelected) + " " + chartIndex + " em " + formatDate(_timeSelected, [dd, '/', mm, '/', yyyy]) :
                      "Toque nos pontos para + info",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                )
            ]),
        ),
      ), isLoading: _loading, opacity: 0, color: Colors.white,)
    );
  }
}
