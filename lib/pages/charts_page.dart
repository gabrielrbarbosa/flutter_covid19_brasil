import 'package:date_format/date_format.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:loading_overlay/loading_overlay.dart';
import 'package:intl/intl.dart';
import 'line_chart.dart';

class ChartsPage extends StatefulWidget {
  @override
  _ChartsPageState createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  int chartIndex = 0;
  bool showChart = false, _loading = true;
  List<TimeSeriesCovid> lineTotalCases = [], lineNewCases = [], lineFatalCases = [];
  List<charts.Series<dynamic, DateTime>> lineChart = [];
  List<String> _locations = ['País', 'Estados', 'Cidades'];
  List<String> _locationsStates = [], _locationsRegions = [], _locationsCities = [], _locationsCitiesLoad = [];
  String _selectedType = 'País', _selectedRegion = 'TOTAL', _lastSelectedLocation;
  List fileDataCities, fileDataStates;
  DateTime _timeSelected;
  String _pointSelected;

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

          if(!info[columnTitles.indexOf("city")].contains("INDEFINIDA")){
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
    List<TimeSeriesCovid> totalCases = [], newCases = [], fatalCases = [];
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
            chartIndex = 0;
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
            chartIndex = 0;
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
            chartIndex = 0;
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
          if(columnTitles.indexOf('deaths') != -1) fatalCases.add(new TimeSeriesCovid(DateTime.parse(date), int.parse(info[columnTitles.indexOf('deaths')])));
          return true;
        }
      }
      count++;
      return false;
    });
    setState(() {
      lineTotalCases = totalCases;
      lineNewCases = newCases;
      lineFatalCases = fatalCases;
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

    if (chartIndex == 0) {
      lineChart = [charts.Series<TimeSeriesCovid, DateTime>(
          id: 'Confirmados',
          colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
          domainFn: (TimeSeriesCovid register, _) => register.time,
          measureFn: (TimeSeriesCovid register, _) => register.cases,
          data: lineTotalCases,
        )];
    } else if (chartIndex == 1) {
      lineChart = [charts.Series<TimeSeriesCovid, DateTime>(
          id: 'Novos Casos',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (TimeSeriesCovid register, _) => register.time,
          measureFn: (TimeSeriesCovid register, _) => register.cases,
          data: lineNewCases,
        )];
    } else if (chartIndex == 2) {
      lineChart = [charts.Series<TimeSeriesCovid, DateTime>(
          id: 'Casos Fatais',
          colorFn: (_, __) => charts.MaterialPalette.gray.shadeDefault,
          domainFn: (TimeSeriesCovid register, _) => register.time,
          measureFn: (TimeSeriesCovid register, _) => register.cases,
          data: lineFatalCases,
        )];
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
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
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
                padding: const EdgeInsets.all(16.0),
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
                        'Total',
                        style: TextStyle(
                            color:
                            chartIndex == 0 ? Colors.black : Colors.black12),
                      ),
                      onPressed: () {
                        setState(() {
                          chartIndex = 0;
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
                              color: chartIndex == 1
                                  ? Colors.black
                                  : Colors.black12)),
                      onPressed: () {
                        setState(() {
                          chartIndex = 1;
                          _timeSelected = null;
                        });
                      },
                    ),
                    if(lineFatalCases != null) FlatButton(
                      shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.black45),
                          borderRadius: BorderRadius.all(Radius.circular(3))),
                      child: Text(
                        'Fatais',
                        style: TextStyle(
                            color:
                            chartIndex == 2 ? Colors.black : Colors.black12),
                      ),
                      onPressed: () {
                        setState(() {
                          chartIndex = 2;
                          _timeSelected = null;
                        });
                      },
                    ),
                  ]),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: showChart ? charts.TimeSeriesChart(
                    lineChart,
                    animate: false,
                    defaultRenderer: new charts.LineRendererConfig(includePoints: true),
                    dateTimeFactory: SimpleDateTimeFactory(),
                    selectionModels: [
                      new charts.SelectionModelConfig(
                        type: charts.SelectionModelType.info,
                        changedListener: _onSelectionChanged,
                      )
                    ],
                  ) :
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
                      formatted(_pointSelected) + " casos em " + formatDate(_timeSelected, [dd, '/', mm, '/', yyyy]) :
                      "Toque nos pontos para + info",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                )
            ]),
        ),
      ), isLoading: _loading, opacity: 0, color: Colors.white,)
    );
  }
}
