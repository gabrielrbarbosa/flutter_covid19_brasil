import 'dart:async';
import 'dart:convert';
import 'package:covid_19_brasil/model/pin_information.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../states.dart';
import '../model/info_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>{
  final Completer<GoogleMapController> _mapController = Completer();

  /// Set of displayed markers on the map
  List<Marker> markers = <Marker>[];
  double _currentZoom = 4;
  String _mapStyle;
  PinInformation currentlySelectedPin = PinInformation(pinPath: '', icon: null, report: {'cases': 0, 'deaths': 0}, locationName: '', labelColor: Colors.grey);
  double pinPillPosition = -100;

  /// Map loading flag
  bool _areMarkersLoading = true;
  BitmapDescriptor bitmapIconCity, bitmapIconState, bitmapIconCountry;
  String errorMsg;

  Map<String, dynamic> _countryInfo = {'cases': 0, 'active': 0, 'recovered': 0, 'deaths': 0, 'fatality': 0, 'tests': 0,
                                      'casesPerOneMillion' : 0, 'deathsPerOneMillion' : 0, 'testsPerOneMillion' : 0};
  Map<String, dynamic> _globalInfo = {'cases': 0, 'active': 0, 'recovered': 0, 'deaths': 0, 'fatality': 0, 'tests': 0,
                                      'casesPerOneMillion' : 0, 'deathsPerOneMillion' : 0, 'testsPerOneMillion' : 0};
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
    BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(64, 64)),
        'assets/images/pin-country.png')
    .then((d) {
      bitmapIconCountry = d;
    });
    rootBundle.loadString('assets/map-style.txt').then((string) {
      _mapStyle = string;
    });
  }

   /// Called when the Google Map widget is created. Updates the map loading state and inits the markers.
  void _onMapCreated(GoogleMapController controller) async {
    _mapController.complete(controller);
    controller.setMapStyle(_mapStyle);

    fetchCountry('brazil');
    fetchCsvFile('https://raw.githubusercontent.com/wcota/covid19br/master/cases-gps.csv', 'cases-gps.csv');
    fetchCsvFile('https://raw.githubusercontent.com/wcota/covid19br/master/cases-brazil-total.csv', 'cases-brazil-total.csv');
    fetchGlobal();
    fetchAllStates();
    fetchAllCountries();
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

        PinInformation pinInfo = new PinInformation(
          locationName: country['country'].toString(),
          icon: new Icon(Icons.info, color: Colors.blue[800], size: 20,),
          pinPath: "assets/images/pin-country.png",
          report: {'cases': formatted(country['cases'].toString()), 'deaths': formatted(country['deaths'].toString())},
          labelColor: Colors.blue[800]
        );
        markers.add(
          Marker(
            markerId: new MarkerId(country['country'].toString()),
            position: location,
            //infoWindow: new InfoWindow(title: country['country'], snippet: 'Total: ' + formatted(country['cases'].toString()) + ' / ' + 'Fatais: ' + formatted(country['deaths'].toString())),
            icon: bitmapIconCountry,
            onTap: () {
              setState(() {
                currentlySelectedPin = pinInfo;
                pinPillPosition = 0;
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

          PinInformation pinInfo = new PinInformation(
            locationName: country['province'].toString(),
            icon: new Icon(Icons.info, color: Colors.green, size: 20,),
            pinPath: "assets/images/pin-state.png",
            report: {'cases': formatted(country['stats']['confirmed'].toString()), 'deaths': formatted(country['stats']['deaths'].toString())},
          );
          markers.add(
            Marker(
              markerId: new MarkerId(country['province'].toString()),
              position: location,
              //infoWindow: new InfoWindow(title: country['province'], snippet: 'Total: ' + formatted(country['stats']['confirmed'].toString()) + ' / ' + 'Fatais: ' + formatted(country['stats']['deaths'].toString())),
              icon: bitmapIconState,
              onTap: () {
                setState(() {
                  currentlySelectedPin = pinInfo;
                  pinPillPosition = 0;
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
          if(nextType == 'D0' || nextType == 'D1'){
            deaths = rows[count].split(',')[columnTitles.indexOf("total")];
            //info = new InfoWindow(title: city[columnTitles.indexOf("name")], snippet: 'Total: ' + formatted(city[columnTitles.indexOf("total")]) + ' / Fatais: ' + formatted(deaths));
          } else {
            //info = new InfoWindow(title: city[columnTitles.indexOf("name")], snippet: 'Total: ' + formatted(city[columnTitles.indexOf("total")]));
          }
          MarkerId markerId = MarkerId((count).toString());
          
          PinInformation pinInfo = new PinInformation(
            locationName: city[columnTitles.indexOf("name")],
            icon: new Icon(Icons.info, color: Colors.red, size: 20,),
            pinPath: "assets/images/pin-city.png",
            report: {'cases': formatted(city[columnTitles.indexOf("total")]), 'deaths': formatted(deaths)},
            labelColor: Colors.red
          );
          markers.add(
            Marker(
              markerId: markerId,
              position: markerLocation,
              icon: bitmapIconCity,
              onTap: () {
                setState(() {
                  currentlySelectedPin = pinInfo;
                  pinPillPosition = 0;
                });
              },
            ),
          );
          
          setState(() {
            markers =  markers;
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
          //InfoWindow info = new InfoWindow(title: states[st[columnTitles.indexOf("state")]].name, snippet: 'Total: ' + formatted(st[columnTitles.indexOf("totalCases")]) + ' / Fatais: ' + formatted(st[columnTitles.indexOf("deaths")]));
          MarkerId markerId = MarkerId(st[columnTitles.indexOf("state")]);
          
          PinInformation pinInfo = new PinInformation(
            locationName: states[st[columnTitles.indexOf("state")]].name,
            icon: new Icon(Icons.info, color: Colors.green, size: 20,),
            pinPath: "assets/images/pin-state.png",
            report: {'cases': formatted(st[columnTitles.indexOf("totalCases")]), 'deaths': formatted(st[columnTitles.indexOf("deaths")])},
            labelColor: Colors.green
          );
          markers.add(
            Marker(
              markerId: markerId,
              position: markerLocation,
              icon: bitmapIconState,
              onTap: () {
                setState(() {
                  currentlySelectedPin = pinInfo;
                  pinPillPosition = 0;
                });
              },
            ),
          );
          
          setState(() {
            markers =  markers;
            _areMarkersLoading = false;
          });
        }
        count++;
        return true;
      });
    }
  }

  String formatted(String str){
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
          ),
          
          SlidingUpPanel(
            backdropOpacity: 0.1,
            color: Colors.grey[100],
            backdropTapClosesPanel: true,
            backdropEnabled: true,
            header: Container(width: MediaQuery.of(context).size.width,height: 10, padding: new EdgeInsets.all(4.0),child: Align(alignment: Alignment.topCenter, child: Icon(Icons.arrow_upward, size: 18, color: Colors.blue))),
            minHeight: 90,
            maxHeight: 540,
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