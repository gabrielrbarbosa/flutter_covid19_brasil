import 'package:flutter_downloader/flutter_downloader.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_animated_linechart/fl_animated_linechart.dart';
import 'package:fl_animated_linechart/chart/area_line_chart.dart';
import 'package:fl_animated_linechart/common/pair.dart';

class ChartsPage extends StatefulWidget {
  @override
  _ChartsPageState createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  LineChart lineChart;
  int chartIndex = 0;
  bool showChart = false;
  Map<DateTime, double> lineTotalCases = {}, lineNewCases = {}, lineFatalCases = {};
  List<String> _locations = ['País', 'Estados', 'Cidades'];
  List<String> _locationsStates = [], _locationsRegions = [], _locationsCities = [];
  String _selectedType = 'País', _selectedRegion = 'TOTAL', _lastSelectedLocation;
  List fileDataCities, fileDataStates;

  void initState() {  
    super.initState();
    downloadFiles();
  }

  void downloadFiles() async{
    _requestDownload('https://raw.githubusercontent.com/wcota/covid19br/master/cases-brazil-cities-time.csv', 'cases-brazil-cities-time.csv');
    _requestDownload('https://raw.githubusercontent.com/wcota/covid19br/master/cases-brazil-states.csv', 'cases-brazil-states.csv');
  }

  void _requestDownload(link, filename) async{
    var dir = await getExternalStorageDirectory();
    await FlutterDownloader.enqueue(
      url: link,
      savedDir: dir.path,
      showNotification: false,
      openFileFromNotification: false
    ).then((result){
       sleep(Duration(milliseconds: 300)); // File was not found without timeout
      _fileToString(filename);
    });
  }

  void _fileToString(filename) async{
    var dir = await getExternalStorageDirectory();
    var fullPath = dir.path + "/" + filename;
    File file = new File(fullPath);
    String text = await file.readAsString();
    _createChart(text, filename);
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
          if(!_locationsCities.contains(info[columnTitles.indexOf("city")]) && info[columnTitles.indexOf("city")] != "TOTAL"){
            _locationsCities.add(info[columnTitles.indexOf("city")]);
          }
        }
        count++;
        _locationsCities.sort((a, b) => a.toString().compareTo(b.toString()));
        return true;
      });

      setState(() {
        _locationsCities = _locationsCities;
      });
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
    Map<DateTime, double> totalCases = {}, newCases = {}, fatalCases = {};
    List fileData, columnTitles;

    switch(_selectedType){
      case 'País':
        fileData = fileDataStates;
        columnTitles = fileData[0].split(",");
        index = columnTitles.indexOf("state");
        setState(() {
          if(_locationsRegions != _locationsStates){
            _locationsRegions = _locationsStates;
          }
          if(_lastSelectedLocation != _selectedType){
            _selectedRegion = 'TOTAL';
            _lastSelectedLocation = _selectedType;
          }
        });
      break;
      case 'Estados':
        fileData = fileDataStates;
        columnTitles = fileData[0].split(",");
        index = columnTitles.indexOf("state");
        setState(() {
          if(_locationsRegions != _locationsStates){
            _locationsRegions = _locationsStates;
          }
          if(_lastSelectedLocation != _selectedType){
            _selectedRegion = 'SP';
            _lastSelectedLocation = _selectedType;
          }
        });
      break;
      case 'Cidades':
        fileData = fileDataCities;
        columnTitles = fileData[0].split(",");
        index = columnTitles.indexOf("city");
        
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
      if(strRow == "") return false;

      var info = strRow.split(",");
      if(count > 1){
        if(info[index] == _selectedRegion){
          String date = info[columnTitles.indexOf('date')].toString();
          totalCases[DateTime.parse(date)] = double.parse(info[columnTitles.indexOf('totalCases')]);
          newCases[DateTime.parse(date)] = double.parse(info[columnTitles.indexOf('newCases')]);
          if(_selectedType != 'Cidades') fatalCases[DateTime.parse(date)] = double.parse(info?.elementAt(columnTitles.indexOf('deaths')));
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
    });
  }

  @override
  Widget build(BuildContext context) {

    if (chartIndex == 0) {
      lineChart = AreaLineChart.fromDateTimeMaps([lineTotalCases], [Colors.red.shade900], ['CONFIRMADOS'],  gradients: [Pair(Colors.orange, Colors.red.shade700)]);
    } else if (chartIndex == 1) {
      lineChart = LineChart.fromDateTimeMaps([lineNewCases], [Colors.blue], ['NOVOS CASOS']);
    } else if (chartIndex == 2) {
      lineChart = LineChart.fromDateTimeMaps([lineFatalCases], [Colors.black87], ['CASOS FATAIS']);
    }

    return Scaffold(
      body: 
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
                    if(_selectedType != 'País') (DropdownButton(
                      value: _selectedRegion,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedRegion = newValue;
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
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: 
                  <Widget>[ 
                    FlatButton(
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
                        });
                      },
                    ),
                    FlatButton(
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
                        });
                      },
                    ),
                    if(_selectedType != 'Cidades') FlatButton(
                      shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.black45),
                          borderRadius: BorderRadius.all(Radius.circular(3))),
                      child: Text(
                        'Casos Fatais',
                        style: TextStyle(
                            color:
                            chartIndex == 2 ? Colors.black : Colors.black12),
                      ),
                      onPressed: () {
                        setState(() {
                          chartIndex = 2;
                        });
                      },
                    ),
                  ]),
              ),
                Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: showChart ? AnimatedLineChart(
                    lineChart,
                    key: UniqueKey(), //Unique key to force animations
                  ) : 
                  (Center(
                      child: Text(
                        "Carregando os dados...",
                        textAlign: TextAlign.center,
                      ),
                    )
                  ), 
                ),
              ),
            ]),
      ),
    ),
    );
  }
}
