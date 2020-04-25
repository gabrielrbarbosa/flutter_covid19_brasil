import 'package:charts_flutter/flutter.dart' as charts;
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:vibration/vibration.dart';
import '../model/line_chart.dart';
import 'package:covid_19_brasil/states.dart';

class ChartsPage extends StatefulWidget {
  @override
  _ChartsPageState createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  String chartIndex = 'Confirmados';
  bool showChart = false, _loading = true, showBarChart = false;

  List<TimeSeriesCovid> lineTotalCases = [], lineNewCases = [], lineTotalDeaths = [], lineNewDeaths = [];
  List<TimeSeriesCovidDouble> lineFatality = [];
  List<charts.Series<dynamic, DateTime>> lineChart = [];

  String _selectedType = 'Brasil', _selectedRegion = 'TOTAL', _selectedLabel = '', _pointSelected, errorMsg;
  List<String> _locations = ['Brasil', 'Estados', 'Cidades'], _locationsStates = [], _locationsRegions = [], _locationsCities = [], _locationsCitiesLoad = [];
  List fileDataCities, fileDataStates;
  DateTime _timeSelected;
  var lineChartWidget;

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
      changeChart(chartIndex);
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
          if(info[columnTitles.indexOf("state")] != 'TOTAL'){
            var stateFullName = states[info[columnTitles.indexOf("state")]].name + ' - ' + info[columnTitles.indexOf("state")];
            if(!_locationsStates.contains(stateFullName)){
              _locationsStates.add(stateFullName);
            }
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
    List<TimeSeriesCovidDouble> fatality = [];
    List fileData, columnTitles;
    bool isCity = false;

    switch(_selectedType){
      case 'Brasil':
        fileData = fileDataStates;
        break;
      case 'Estados':
        fileData = fileDataStates;
        _selectedLabel = states[_selectedRegion.split('-')[1].trim()].name + ' - ' + _selectedRegion.split('-')[1].trim();
        _selectedRegion = _selectedRegion.split('-')[1].trim();
      break;
      case 'Cidades':
        fileData = fileDataCities;
        _selectedLabel = _selectedRegion;
        isCity = true;
      break;
    }

    columnTitles = fileData[0].split(",");
    if(isCity){
      index = columnTitles.indexOf("city");
    } else{
      index = columnTitles.indexOf("state");
    }
    
    setState(() {
      if((isCity) && _locationsRegions != _locationsCities){
        _locationsRegions = _locationsCities;
      }
      else if((!isCity) && _locationsRegions != _locationsStates){
        _locationsRegions = _locationsStates;
      }
    });
    
    if(_selectedRegion != ''){
      fileData.forEach((strRow){
        if(strRow == ""){
          return false;
        }

        var info = strRow.split(",");
        if(count > 1){
          if(info[index] == _selectedRegion){
            double fatalRatio = 0;
            if(int.parse(info[columnTitles.indexOf('deaths')]) > 0){
              fatalRatio = (int.parse(info[columnTitles.indexOf('deaths')]) / int.parse(info[columnTitles.indexOf('totalCases')]) * 100);
              String fatalStr = fatalRatio.toStringAsFixed(2);
              fatalRatio = double.parse(fatalStr);
            }

            String date = info[columnTitles.indexOf('date')];
            if(int.parse(info[columnTitles.indexOf('totalCases')]) > 0) totalCases.add(new TimeSeriesCovid(DateTime.parse(date), int.parse(info[columnTitles.indexOf('totalCases')])));
            if(int.parse(info[columnTitles.indexOf('newCases')]) > 0) newCases.add(new TimeSeriesCovid(DateTime.parse(date), int.parse(info[columnTitles.indexOf('newCases')])));
            if(int.parse(info[columnTitles.indexOf('deaths')]) > 0) totalDeaths.add(new TimeSeriesCovid(DateTime.parse(date), int.parse(info[columnTitles.indexOf('deaths')])));
            if(int.parse(info[columnTitles.indexOf('newDeaths')]) > 0) newDeaths.add(new TimeSeriesCovid(DateTime.parse(date), int.parse(info[columnTitles.indexOf('newDeaths')])));
            if(int.parse(info[columnTitles.indexOf('deaths')]) > 0) fatality.add(new TimeSeriesCovidDouble(DateTime.parse(date), fatalRatio));
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
        lineFatality = fatality;
      });
    }
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

    if (selectedDatum.isNotEmpty) {
      time = selectedDatum.first.datum.time;
      selectedDatum.forEach((charts.SeriesDatum datumPair) {
        if(chartIndex == 'Letalidade'){
          selected = datumPair.datum.ratio.toString() + '% de';
        } else{
          selected = formatted(datumPair.datum.cases.toString());
        }
      });
      Vibration.vibrate(duration: 10, amplitude: 255);

      setState(() {
        _timeSelected = time;
        _pointSelected = selected;
      });
    }
  }

  changeChart(chartName){
    var chartColor = charts.MaterialPalette.red.shadeDefault;
    var chartData = lineTotalCases;
    var showBars = false;

    switch(chartName){
      case 'Novos Casos':
        chartData = lineNewCases;
        chartColor = charts.MaterialPalette.blue.shadeDefault;
        showBars = true;
      break;
      case 'Fatais':
        chartData = lineTotalDeaths;
        chartColor = charts.MaterialPalette.indigo.shadeDefault;
      break;
      case 'Novos Óbitos':
        chartData = lineNewDeaths;
        chartColor = charts.MaterialPalette.blue.shadeDefault;
        showBars = true;
      break;
      case 'Letalidade':
        chartColor = charts.MaterialPalette.cyan.shadeDefault;
      break;
    }
    
    if(chartName == 'Letalidade'){
      lineChart = [
        charts.Series<TimeSeriesCovidDouble, DateTime>(
        id: chartName,
        colorFn: (_, __) => chartColor,
        domainFn: (TimeSeriesCovidDouble register, _) => register.time,
        measureFn: (TimeSeriesCovidDouble register, _) => register.ratio,
        data: lineFatality,
      )];
    } else{
      lineChart = [
        charts.Series<TimeSeriesCovid, DateTime>(
        id: chartName,
        colorFn: (_, __) => chartColor,
        domainFn: (TimeSeriesCovid register, _) => register.time,
        measureFn: (TimeSeriesCovid register, _) => register.cases,
        data: chartData,
      )];
    }

    setState(() {
      _timeSelected = null;
      showBarChart = showBars;
      lineChartWidget = new charts.TimeSeriesChart(
        lineChart,
        animate: false,
        defaultRenderer: (showBarChart ? new charts.BarRendererConfig<DateTime>() : new charts.LineRendererConfig(includePoints: true, includeLine: true)),
        selectionModels: [
          new charts.SelectionModelConfig(
            type: charts.SelectionModelType.info,
            changedListener: _onSelectionChanged,
          )
        ],
      );
      chartIndex = chartName;
      showChart = true;
      _loading = false;
    });
  }

  String formatted(String str){
    int val = int.parse(str);
    return new NumberFormat.decimalPattern('pt').format(val).toString();
  }

  @override
  Widget build(BuildContext context) {

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
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: 
                    <Widget>[ 
                      DropdownButton(
                        value: _selectedType,
                        onChanged: (newValue) {
                          if(newValue == 'Brasil' && newValue != _selectedType){
                            setState(() {
                              _selectedType = newValue;
                              _selectedRegion = 'TOTAL';
                              _selectedLabel = '';
                            });
                            updateChartInfo();
                            changeChart('Confirmados');
                          } 
                          else if(newValue != _selectedType){
                            setState(() {
                              _selectedType = newValue;
                              _selectedRegion = '';
                              _selectedLabel = '';
                              lineChartWidget = Text('Pesquise uma região para mais detalhes', textAlign: TextAlign.center);
                            });
                            updateChartInfo();
                          }
                        },
                        items: _locations.map((location) {
                          return DropdownMenuItem(
                            child: new Text(location),
                            value: location,
                          );
                        }).toList(),
                      ),
                  ])
                ),
                    
              if(_selectedType != 'Brasil')
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
                          if(suggestion != _selectedRegion){
                            _selectedRegion = suggestion;
                          }
                        });
                        updateChartInfo();
                        changeChart('Confirmados');
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: 
                  <Widget>[ 
                    if(lineTotalCases != null) ChartButtonWidget(chartName: 'Confirmados', chartIndex: this.chartIndex, changeChart: this.changeChart),
                    if(lineNewCases != null) ChartButtonWidget(chartName: 'Novos Casos', chartIndex: this.chartIndex, changeChart: this.changeChart),
                  ]),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: 
                  <Widget>[ 
                    if(lineTotalDeaths != null) ChartButtonWidget(chartName: 'Fatais', chartIndex: this.chartIndex, changeChart: this.changeChart),
                    if(lineNewDeaths != null) ChartButtonWidget(chartName: 'Novos Óbitos', chartIndex: this.chartIndex, changeChart: this.changeChart),
                    if(lineFatality != null) ChartButtonWidget(chartName: 'Letalidade', chartIndex: this.chartIndex, changeChart: this.changeChart),
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

              if(_selectedRegion != 'TOTAL') (
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(_selectedLabel, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))
                )
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: showChart ? 
                  (lineChartWidget) :
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
                      _pointSelected + " " + chartIndex + " em " + formatDate(_timeSelected, [dd, '/', mm, '/', yyyy]) :
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

class ChartButtonWidget extends StatelessWidget {
  Function changeChart;
  final String chartIndex;
  final String chartName;
  
  ChartButtonWidget({ this.changeChart, this.chartIndex, this.chartName });

  Widget build(BuildContext context) {
    return FlatButton(
      shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.black45),
              borderRadius: BorderRadius.all(Radius.circular(3))),
      child: Text(chartName, style: TextStyle(color: chartName == chartIndex ? Colors.black : Colors.black12)),
      onPressed: () {
        this.changeChart(chartName);
      }
    );
  }
}
