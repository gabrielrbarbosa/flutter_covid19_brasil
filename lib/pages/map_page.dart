import 'dart:async';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:covid_19_brasil/states.dart';
import 'package:covid_19_brasil/model/info_widget.dart';
import 'package:covid_19_brasil/model/pin_information.dart';
import 'package:vibration/vibration.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>{
  final Completer<GoogleMapController> _mapController = Completer();

  /// Set of displayed markers on the map
  List<Marker> markers = <Marker>[];
  double _currentZoom = 4, pinPillPosition = -100, pinInfoHeight = 80;
  bool isFavorite = false;
  PinInformation currentlySelectedPin = PinInformation(pinPath: 'assets/images/pin-country.png', report: {'cases': 0, 'deaths': 0}, locationName: '', labelColor: Colors.grey);

  bool _areMarkersLoading = true;
  BitmapDescriptor bitmapIconCity, bitmapIconState, bitmapIconCountry;
  String errorMsg, _mapStyle;
  SharedPreferences _db;

  Map<String, dynamic> _countryInfo = {'cases': 0, 'active': 0, 'recovered': 0, 'deaths': 0, 'fatality': 0, 'tests': 0,
                                      'casesPerOneMillion' : 0, 'deathsPerOneMillion' : 0, 'testsPerOneMillion' : 0};
  Map<String, dynamic> _globalInfo = {'cases': 0, 'active': 0, 'recovered': 0, 'deaths': 0, 'fatality': 0, 'tests': 0,
                                      'casesPerOneMillion' : 0, 'deathsPerOneMillion' : 0, 'testsPerOneMillion' : 0};
  void initState(){
    super.initState();
    loadPrefs();

    fetchCountry('brazil');
    fetchGlobal();
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
    BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(64, 64)),
        'assets/images/pin-country.png')
    .then((d) {
      bitmapIconCountry = d;
    });
    rootBundle.loadString('assets/map-style.txt').then((string) {
      _mapStyle = string;
    });
    _db = await SharedPreferences.getInstance();
  }

   /// Called when the Google Map widget is created. Updates the map loading state and inits the markers.
  void _onMapCreated(GoogleMapController controller) async {
    _mapController.complete(controller);
    controller.setMapStyle(_mapStyle);
    
    fetchCsvFile('https://raw.githubusercontent.com/wcota/covid19br/master/cases-gps.csv', 'cases-gps.csv');
    fetchCsvFile('https://raw.githubusercontent.com/wcota/covid19br/master/cases-brazil-total.csv', 'cases-brazil-total.csv');
    
    fetchAllStates();
    fetchAllCountries();

    
    if(_db.getString('favorite_name') != ''){
      controller.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(_db.getDouble('favorite_latitude'), _db.getDouble('favorite_longitude')), zoom: 9))
      );
    }
  }

  fetchGlobal() async{
    final response = await http.get('https://corona.lmao.ninja/v2/all');

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      _globalInfo = jsonResponse;
      _globalInfo['fatality'] = ((_globalInfo['deaths'] / _globalInfo['cases']) * 100).toStringAsFixed(2);
    } else {
      setState(() {
        errorMsg = 'Erro (' + response.statusCode.toString() + '): ' + response.body;
      });
      throw Exception('Erro ao carregar informações.');
    }
  }

  fetchCountry(country) async {      
    final response = await http.get('https://corona.lmao.ninja/v2/countries/' + country);
    
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      _countryInfo = jsonResponse;
      _countryInfo['fatality'] = ((_countryInfo['deaths'] / _countryInfo['cases']) * 100).toStringAsFixed(2);
    } else {
      setState(() {
        errorMsg = 'Erro (' + response.statusCode.toString() + '): ' + response.body;
      });
      throw Exception('Erro ao carregar informações.');
    }
  }

  fetchAllCountries() async {      
    final response = await http.get('https://corona.lmao.ninja/v2/countries/');
    
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      for(var country in jsonResponse){
        LatLng location = new LatLng(double.parse(country['countryInfo']['lat'].toString()), double.parse(country['countryInfo']['long'].toString()));
        String fatality = ((country['deaths'] / country['cases']) * 100).toStringAsFixed(2);
        String infoDeaths = formatted(country['deaths'].toString()) + ' (' + fatality + '%)';
        if(fatality == '0.00') infoDeaths = formatted(country['deaths'].toString());

        PinInformation pinInfo = new PinInformation(
          locationName: country['country'].toString(),
          lat: double.parse(country['countryInfo']['lat'].toString()),
          long: double.parse(country['countryInfo']['long'].toString()),
          pinPath: "assets/images/pin-country.png",
          report: {'cases': formatted(country['cases'].toString()), 'deaths': infoDeaths, 'recovered': formatted(country['recovered'].toString())},
          labelColor: Colors.blue[800]
        );

        if(_db.getString('favorite_name') == country['country'].toString()){
          setState(() {
            currentlySelectedPin = pinInfo;
            pinPillPosition = 0;
            pinInfoHeight = 80;
            isFavorite = true;
          });
        }

        markers.add(
          Marker(
            markerId: new MarkerId(country['country'].toString()),
            position: location,
            icon: bitmapIconCountry,
            onTap: () {
              Vibration.vibrate(duration: 10, amplitude: 255);
              setState(() {
                currentlySelectedPin = pinInfo;
                pinPillPosition = 0;
                pinInfoHeight = 80;
                isFavorite = _db.getString('favorite_name') == country['country'].toString();
              });
            },
          )
        );
      }
      setState(() {
        markers =  markers;
        _areMarkersLoading = false;
      });
    } else {
      setState(() {
        errorMsg = 'Erro (' + response.statusCode.toString() + '): ' + response.body;
      });
      throw Exception('Erro ao carregar informações.');
    }
  }

  fetchAllStates() async {      
    final response = await http.get('https://corona.lmao.ninja/v2/jhucsse/');
    
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      for(var country in jsonResponse){
        if(country['province'] != 'null' && country['coordinates']['latitude'] != ''){
          LatLng location = LatLng(double.parse(country['coordinates']['latitude']), double.parse(country['coordinates']['longitude']));
          String fatality = ((country['stats']['deaths'] / country['stats']['confirmed']) * 100).toStringAsFixed(2);
          String infoDeaths = formatted(country['stats']['deaths'].toString()) + ' (' + fatality + '%)';
          if(fatality == '0.00') infoDeaths = formatted(country['stats']['deaths'].toString());

          PinInformation pinInfo = new PinInformation(
            locationName: country['province'].toString(),
            lat: double.parse(country['coordinates']['latitude']),
            long: double.parse(country['coordinates']['longitude']),
            pinPath: "assets/images/pin-state.png",
            report: {'cases': formatted(country['stats']['confirmed'].toString()), 'deaths': infoDeaths, 'recovered': formatted(country['stats']['recovered'].toString())},
            labelColor: Colors.green
          );

          if(_db.getString('favorite_name') == country['province'].toString()){
            setState(() {
              currentlySelectedPin = pinInfo;
              pinPillPosition = 0;
              pinInfoHeight = 80;
              isFavorite = true;
            });
          }
          markers.add(
            Marker(
              markerId: new MarkerId(country['province'].toString()),
              position: location,
              icon: bitmapIconState,
              onTap: () {
                Vibration.vibrate(duration: 10, amplitude: 10);
                setState(() {
                  currentlySelectedPin = pinInfo;
                  pinPillPosition = 0;
                  pinInfoHeight = 80;
                  isFavorite = _db.getString('favorite_name') == country['province'].toString();
                });
              },
            )
          );
        }
      }
      setState(() {
        markers =  markers;
        _areMarkersLoading = false;
      });
    } else {
      setState(() {
        errorMsg = 'Erro (' + response.statusCode.toString() + '): ' + response.body;
      });
      throw Exception('Erro ao carregar informações.');
    }
  }

  fetchCsvFile(link, filename) async {      
    final response = await http.get(link);
    
    if (response.statusCode == 200) {
      var txt = response.body;
      _createMarkers(txt, filename);
    } else {
      setState(() {
        errorMsg = 'Erro (' + response.statusCode.toString() + '): ' + response.body;
      });
      throw Exception('Erro ao carregar informações.');
    }
  }

  void _createMarkers(txt, filename) async{
    //InfoWindow info;
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
          var deaths = '0';
          if(nextType == 'D0' || nextType == 'D1') deaths = rows[count].split(',')[columnTitles.indexOf("total")];
          
          MarkerId markerId = MarkerId((count).toString());
          String fatality = ((int.parse(deaths) / int.parse(city[columnTitles.indexOf("total")])) * 100).toStringAsFixed(2);
          String infoDeaths = formatted(deaths) + ' (' + fatality + '%)';
          if(fatality == '0.00') infoDeaths = formatted(deaths);

          PinInformation pinInfo = new PinInformation(
            locationName: city[columnTitles.indexOf("name")],
            lat: double.parse(city[columnTitles.indexOf("lat")].toString()),
            long: double.parse(city[columnTitles.indexOf("lon")].toString()),
            pinPath: "assets/images/pin-city.png",
            report: {'cases': formatted(city[columnTitles.indexOf("total")]), 'deaths': infoDeaths, 
              'total_per100k': city[columnTitles.indexOf("total_per_100k_inhabitants")].toString()
            },
            labelColor: Colors.red
          );

          if(_db.getString('favorite_name') == city[columnTitles.indexOf("name")]){
            setState(() {
              currentlySelectedPin = pinInfo;
              pinPillPosition = 0;
              pinInfoHeight = 80;
              isFavorite = true;
            });
          }

          markers.add(
            Marker(
              markerId: markerId,
              position: markerLocation,
              icon: bitmapIconCity,
              onTap: () {
                Vibration.vibrate(duration: 10, amplitude: 10);
                setState(() {
                  currentlySelectedPin = pinInfo;
                  pinPillPosition = 0;
                  pinInfoHeight = 80;
                  isFavorite = _db.getString('favorite_name') == city[columnTitles.indexOf("name")];
                });
              },
            ),
          );
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

          MarkerId markerId = MarkerId(st[columnTitles.indexOf("state")]);
          String fatality = ((int.parse(st[columnTitles.indexOf("deaths")]) / int.parse(st[columnTitles.indexOf("totalCases")])) * 100).toStringAsFixed(2);
          String infoDeaths = formatted(st[columnTitles.indexOf("deaths")]) + ' (' + fatality + '%)';
          if(fatality == '0.00') infoDeaths = formatted(st[columnTitles.indexOf("deaths")]);

          PinInformation pinInfo = new PinInformation(
            locationName: states[st[columnTitles.indexOf("state")]].name,
            lat: states[st[columnTitles.indexOf("state")]].latitute, 
            long: states[st[columnTitles.indexOf("state")]].longitude,
            pinPath: "assets/images/pin-state.png",
            report: {'cases': formatted(st[columnTitles.indexOf("totalCases")]), 'deaths': infoDeaths, 'recovered': formatted(st[columnTitles.indexOf("recovered")]),
              'total_per100k': st[columnTitles.indexOf("totalCases_per_100k_inhabitants")].toString(),
              'deaths_per100k': st[columnTitles.indexOf("deaths_per_100k_inhabitants")].toString()
            },
            labelColor: Colors.green
          );

          if(_db.getString('favorite_name') == states[st[columnTitles.indexOf("state")]].name){
            setState(() {
              currentlySelectedPin = pinInfo;
              pinPillPosition = 0;
              pinInfoHeight = 110;
              isFavorite = true;
            });
          }

          markers.add(
            Marker(
              markerId: markerId,
              position: markerLocation,
              icon: bitmapIconState,
              onTap: () {
                Vibration.vibrate(duration: 10, amplitude: 10);
                setState(() {
                  currentlySelectedPin = pinInfo;
                  pinPillPosition = 0;
                  pinInfoHeight = 110;
                  isFavorite = _db.getString('favorite_name') == states[st[columnTitles.indexOf("state")]].name;
                });
              },
            ),
          );
        }
        count++;
        return true;
      });
    }
    setState(() {
      markers =  markers;
      _areMarkersLoading = false;
    });
  }

  String formatted(String str){
    if(str == '') return "";
    int val = int.parse(str);
    return new NumberFormat.decimalPattern('pt').format(val).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Google Map widget
          Opacity(
            opacity: _areMarkersLoading ? 0 : 1,
            child: GoogleMap(
              mapToolbarEnabled: false,
              minMaxZoomPreference: new MinMaxZoomPreference(1.0, 12.0),
              initialCameraPosition: CameraPosition(
                target: LatLng(-18.2679862, -50.6720566),
                zoom: _currentZoom,
              ),
              markers: Set<Marker>.of(markers),
              onMapCreated: (controller) => _onMapCreated(controller)
            ),
          ),

          MapPinPillComponent(
            pinPillPosition: pinPillPosition,
            currentlySelectedPin: currentlySelectedPin,
            height: pinInfoHeight,
            isFavorite: isFavorite,
          ),
          
          SlidingUpPanel(
            backdropOpacity: 0.1,
            color: Colors.grey[100],
            backdropTapClosesPanel: true,
            backdropEnabled: true,
            header: Container(width: MediaQuery.of(context).size.width,height: 10, padding: new EdgeInsets.all(4.0),child: Align(alignment: Alignment.topCenter, child: Icon(Icons.arrow_upward, size: 18, color: Colors.blue))),
            minHeight: 95,
            maxHeight: 550,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0)),
            panel: Center(
              child: Details(report: _globalInfo, reportBR: _countryInfo),
            ),
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

          // Map markers loading indicator
          if (_areMarkersLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Card(
                  elevation: 2,
                  color: Colors.grey,
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