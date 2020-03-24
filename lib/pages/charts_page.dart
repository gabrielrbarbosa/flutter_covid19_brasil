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

class _ChartsPageState extends State<ChartsPage> with AutomaticKeepAliveClientMixin {
  // Load page only once
  @override
  bool get wantKeepAlive => true;

  LineChart lineChart;
  int chartIndex = 0;
  Map<DateTime, double> lineTotalCases = {};
  Map<DateTime, double> lineNewCases = {};
  bool showChart = false;
  List<String> _locations = ['Brasil'];
  String _selectedLocation = 'Brasil';
  List fileData;

  void initState() {  
    super.initState();
    _requestDownload('https://raw.githubusercontent.com/wcota/covid19br/master/cases-brazil-cities-time.csv');
  }

  void _requestDownload(link) async{
    var dir = await getExternalStorageDirectory();
    await FlutterDownloader.enqueue(
      url: link,
      savedDir: dir.path,
      showNotification: false,
      openFileFromNotification: false
    ).then((result){
       sleep(Duration(seconds: 1)); // File was not found without timeout
      _fileToString('cases-brazil-cities-time.csv');
    });
  }

  void _fileToString(filename) async{
    var dir = await getExternalStorageDirectory();
    var fullPath = dir.path + "/" + filename;
    File file = new File(fullPath);
    String text = await file.readAsString();
    _createChart(text);
  }

  void _createChart(txt){
    fileData = txt.split("\n");

    int count = 1;
    fileData.forEach((strRow){
      if(strRow == "") return false;

      // Get all locations and store in dropdown list
      if(count > 1){
        var info = strRow.split(",");
        if(!_locations.contains(info[3]) && info[3] != "TOTAL"){
          _locations.add(info[3]);
        }
      }
      count++;
      _locations.sort((a, b) => a.toString().compareTo(b.toString()));
      return true;
    });

    setState(() {
      _locations = _locations;
    });

    updateChartInfo();
  }

  void updateChartInfo(){
    int count = 1;
    Map<DateTime, double> totalCases = {};
    Map<DateTime, double> newCases = {};

    fileData.forEach((strRow){
      if(strRow == "") return false;

      // Get data only from selected region
      if(count > 1){
        var info = strRow.split(",");
        if(info[3] == _selectedLocation || (info[3] == "TOTAL" && _selectedLocation == "Brasil")){

          String date = info[0].toString();
          totalCases[DateTime.parse(date)] = double.parse(info[5]);
          newCases[DateTime.parse(date)] = double.parse(info[4]);
          return true;
        } else{
          return false;
        }
      }
      count++;
    });

    setState(() {
      lineTotalCases = totalCases;
      lineNewCases = newCases;
      showChart = true;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (chartIndex == 0) {
      lineChart = AreaLineChart.fromDateTimeMaps([lineTotalCases], [Colors.red.shade900], ['CONFIRMADOS'],  gradients: [Pair(Colors.orange, Colors.red.shade700)]);
      //lineChart = LineChart.fromDateTimeMaps([lineTotalCases], [Colors.red], ['CASOS CONFIRMADOS']);
    } else if (chartIndex == 1) {
      lineChart = LineChart.fromDateTimeMaps([lineNewCases], [Colors.blue], ['NOVOS CASOS']);
    } 

    return Scaffold(
      body: Container(
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
                      value: _selectedLocation,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedLocation = newValue;
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
                  ]),
              ),
                Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: showChart ? AnimatedLineChart(
                    lineChart,
                    key: UniqueKey(), //Unique key to force animations
                  ) : (Text('Carregando...')), 
                ),
              ),
            ]),
      ),
    );
  }
}
