import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:expandable/expandable.dart';
import '../states.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>{
  final Completer<GoogleMapController> _mapController = Completer();

  /// Set of displayed markers and cluster markers on the map
  List<Marker> markers = <Marker>[];
  double _currentZoom = 4;
  double _cardHeight = 100;

  /// Map loading flag
  bool _isMapLoading = true;
  bool _areMarkersLoading = true;
  BitmapDescriptor bitmapIconCity, bitmapIconState;

  Map<String, dynamic> _countryInfo = {'cases': 0, 'active': 0, 'recovered': 0, 'deaths': 0, 'fatality': 0, 'tests': 0,
                                      'casesPerOneMillion' : 0, 'deathsPerOneMillion' : 0, 'testsPerOneMillion' : 0};
  String get info => 'Total: ' + new NumberFormat.decimalPattern('pt').format(_countryInfo['cases']).toString() + 
                      '\nAtivos: ' + new NumberFormat.decimalPattern('pt').format(_countryInfo['active']).toString() +
                      '\nRecuperados: ' + new NumberFormat.decimalPattern('pt').format(_countryInfo['recovered']).toString() +
                      '\nFatais: ' + new NumberFormat.decimalPattern('pt').format(_countryInfo['deaths']).toString() +
                      '\nLetalidade: ' + _countryInfo['fatality'].toString() + '%' +
                      '\nTestes Feitos: ' + new NumberFormat.decimalPattern('pt').format(_countryInfo['tests']).toString() +
                      '\n\nCasos/Milhão: ' + new NumberFormat.decimalPattern('pt').format(_countryInfo['casesPerOneMillion']).toString()+
                      '\nMortes/Milhão: ' + new NumberFormat.decimalPattern('pt').format(_countryInfo['deathsPerOneMillion']).toString() +
                      '\nTestes/Milhão: ' +new NumberFormat.decimalPattern('pt').format(_countryInfo['testsPerOneMillion']).toString();

  void initState(){
    super.initState();
    loadPrefs();
  }

  void loadPrefs() async{
    BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(64, 64)),
        'assets/images/pin-city.png')
    .then((d) {
      bitmapIconCity = d;
    });
    BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(64, 64)),
        'assets/images/pin-state.png')
    .then((d) {
      bitmapIconState = d;
    });
  }

   /// Called when the Google Map widget is created. Updates the map loading state and inits the markers.
  void _onMapCreated(GoogleMapController controller) async {
    _mapController.complete(controller);

    fetchData('brazil');
    fetchCsvFile('https://raw.githubusercontent.com/wcota/covid19br/master/cases-gps.csv', 'cases-gps.csv');
    fetchCsvFile('https://raw.githubusercontent.com/wcota/covid19br/master/cases-brazil-total.csv', 'cases-brazil-total.csv');
  }

  fetchData(country) async {      
    final response = await http.get('https://corona.lmao.ninja/v2/countries/' + country);
    
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      _countryInfo = jsonResponse;
      _countryInfo['fatality'] = ((_countryInfo['deaths'] / _countryInfo['cases']) * 100).toStringAsFixed(2);

      setState(() {
        _countryInfo = _countryInfo;
      });
    } else {
      throw Exception('Erro ao carregar informações.');
    }
  }

  fetchCsvFile(link, filename) async {      
    final response = await http.get(link);
    
    if (response.statusCode == 200) {
      var txt = response.body;
      _createMarkers(txt, filename);
    } else {
      throw Exception('Erro ao carregar informações.');
    }
  }

  void _createMarkers(txt, filename) async{
    InfoWindow info;
    var rows = txt.split("\n");

    if(filename == 'cases-gps.csv'){
      var count = 1;
      List columnTitles = rows[0].split(",");

      rows.forEach((strRow){
        if(strRow == "") return false;
        var city = strRow.split(",");   
        var nextType = rows[count].split(',')[columnTitles.indexOf("type")];
        var type = city[columnTitles.indexOf("type")];
        
        if(count > 1 && type != 'D0' && type != 'D1'){
          LatLng markerLocation = LatLng(double.parse(city[columnTitles.indexOf("lat")].toString()), double.parse(city[columnTitles.indexOf("lon")].toString()));

          if(nextType == 'D0' || nextType == 'D1'){
            var deaths = rows[count].split(',')[columnTitles.indexOf("total")];
            info = new InfoWindow(title: city[columnTitles.indexOf("name")], snippet: 'Total: ' + city[columnTitles.indexOf("total")] + ' / Fatais: ' + deaths);
          } else {
            info = new InfoWindow(title: city[columnTitles.indexOf("name")], snippet: 'Total: ' + city[columnTitles.indexOf("total")]);
          }
          MarkerId markerId = MarkerId((count).toString());
          
          markers.add(
            Marker(
              markerId: markerId,
              position: markerLocation,
              infoWindow: info,
              icon: bitmapIconCity
            ),
          );
          
          setState(() {
            markers = markers;
            _areMarkersLoading = false;
          });
        }
        count++;
        return true;
      });
    } 
    else if(filename == 'cases-brazil-total.csv'){
      var count = 1;
      List columnTitles = rows[0].split(",");

      rows.forEach((strRow){
        if(strRow == "") return false;
        if(count > 2){
          var st = strRow.split(",");   
          LatLng markerLocation = LatLng(
            states[st[columnTitles.indexOf("state")]].latitute, 
            states[st[columnTitles.indexOf("state")]].longitude
          );
          InfoWindow info = new InfoWindow(title: states[st[columnTitles.indexOf("state")]].name, snippet: 'Total: ' + st[columnTitles.indexOf("totalCases")] + ' / Fatais: ' + st[columnTitles.indexOf("deaths")]);
          MarkerId markerId = MarkerId(st[columnTitles.indexOf("state")]);
          
          markers.add(
            Marker(
              markerId: markerId,
              position: markerLocation,
              infoWindow: info,
              icon: bitmapIconState
            ),
          );
          
          setState(() {
            markers = markers;
            _areMarkersLoading = false;
            _isMapLoading = false;
          });
        }
        count++;
        return true;
      });
    }
  }

  toggleCard(){
    // TODO: fix this function
    setState(() {
      if(_cardHeight == 100){
        _cardHeight = 250;
      } else{
        _cardHeight = 100;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Google Map widget
          Opacity(
            opacity: _isMapLoading ? 0 : 1,
            child: GoogleMap(
              mapToolbarEnabled: false,
              initialCameraPosition: CameraPosition(
                target: LatLng(-18.2679862, -50.6720566),
                zoom: _currentZoom,
              ),
              markers: Set<Marker>.of(markers),
              onMapCreated: (controller) => _onMapCreated(controller)
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(1.0),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  height: _cardHeight,
                    child: ExpandableTheme(
                      data: const ExpandableThemeData(iconColor: Colors.white, useInkWell: true),
                      child: ListView(  
                        physics: const BouncingScrollPhysics(),
                        children: <Widget>[
                          ExpandableNotifier(
                            child: Card(
                              elevation: 2,
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              color: Colors.blue[300],
                              child: Column(
                                children: <Widget>[
                                  ScrollOnExpand(
                                    scrollOnExpand: true,
                                    scrollOnCollapse: false,
                                    child: GestureDetector(
                                      onTap: (){ toggleCard(); },
                                      child: ExpandablePanel(
                                        theme: const ExpandableThemeData(
                                          headerAlignment: ExpandablePanelHeaderAlignment.center,
                                          tapBodyToExpand: true,
                                          tapBodyToCollapse: true,
                                        ),
                                        header: Padding(
                                            padding: EdgeInsets.all(10),
                                            child: Text(
                                              "Mais Informações",
                                              style: TextStyle(color: Colors.white,
                                              fontSize: 16),
                                            )),
                                        expanded: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                              Padding(
                                                  padding: EdgeInsets.only(bottom: 10),
                                                  child: Text(
                                                    info,
                                                    softWrap: true,
                                                    overflow: TextOverflow.fade,
                                                    style: TextStyle(color: Colors.white,
                                                    fontSize: 16),
                                                  )),
                                          ],
                                        ),
                                      builder: (context, collapsed, expanded) {
                                        var controller = ExpandableController.of(context);
                                        return Padding(
                                          padding: EdgeInsets.only(left: 10, right: 10),
                                          child: Expandable(
                                            collapsed: collapsed,
                                            expanded: expanded,
                                            theme: const ExpandableThemeData(crossFadePoint: 0),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                  ),
                ),
              ),
            ),
          ),

          // Map markers loading indicator
          if (_areMarkersLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Card(
                  elevation: 2,
                  color: Colors.grey.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      'Carregando...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}