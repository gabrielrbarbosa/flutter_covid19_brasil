import 'dart:async';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:covid_19_brasil/model/states.dart';
import 'package:covid_19_brasil/widgets/details_panel.dart';
import 'package:covid_19_brasil/widgets/pin_information.dart';
import 'package:vibration/vibration.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>{
  final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController _mapControllerLoaded;

  /// Set of displayed markers on the map
  List<Marker> markers = <Marker>[];
  //List<Circle> circles = <Circle>[];
  List _locationsRegions = [];
  double _currentZoom = 4, pinPillPosition = -170;
  int _minCasesCity = 10000, _countBRcities = 0;
  
  PinInformation currentlySelectedPin = PinInformation(pinPath: 'assets/images/pin-country.png', report: {'cases': 0, 'deaths': 0}, locationName: '', labelColor: Colors.grey);

  bool _areMarkersLoading = true, isFavorite = true;
  PanelController _panelController = new PanelController();
  BitmapDescriptor bitmapIconCity, bitmapIconState, bitmapIconCountry;
  String errorMsg, _mapStyle;
  SharedPreferences _db;
  PermissionStatus _showLocation;

  Map<String, dynamic> _countryInfo = {'cases': 0, 'active': 0, 'recovered': 0, 'deaths': 0, 'fatality': 0, 'tests': 0,
                                      'casesPerOneMillion' : 0, 'deathsPerOneMillion' : 0, 'testsPerOneMillion' : 0};
  Map<String, dynamic> _globalInfo = {'cases': 0, 'active': 0, 'recovered': 0, 'deaths': 0, 'fatality': 0, 'tests': 0,
                                      'casesPerOneMillion' : 0, 'deathsPerOneMillion' : 0, 'testsPerOneMillion' : 0};
  void initState(){
    super.initState();
    loadPrefs();
    requestPermission(Permission.location);
    fetchCountry('brazil');
    fetchGlobal();
  }

  Future<void> requestPermission(Permission permission) async {
    PermissionStatus showLocation = await permission.request();
    setState(() {
      _showLocation = showLocation; 
    });
  }

  void loadPrefs() async{
    BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(64, 64)), 'assets/images/pin-city.png').then((d) {bitmapIconCity = d;});
    BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(64, 64)), 'assets/images/pin-state.png').then((d) {bitmapIconState = d;});
    BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(64, 64)), 'assets/images/pin-country.png').then((d) {bitmapIconCountry = d;});

    rootBundle.loadString('assets/map-style.txt').then((string) { _mapStyle = string; });    
    _db = await SharedPreferences.getInstance();
    _minCasesCity = (_db.getInt('minCasesCity') ?? 10000);
  }
  
  void goToFavoriteLocation(){
    /*if(_db.getString('favorite_name') != '' && _db.getDouble('favorite_latitude') != null){
      _mapControllerLoaded.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(_db.getDouble('favorite_latitude'), _db.getDouble('favorite_longitude')), zoom: 10))
      );
    }*/
  }

  void configMarkers(value){
    _db.setInt('minCasesCity', value);
    setState(() {
      _areMarkersLoading = true;
      _minCasesCity = value;
      _countBRcities = 0;
      pinPillPosition = -170;
    });

    List<Marker> newMarkers = [];
    markers.forEach((mk) { 
      if(!mk.markerId.toString().contains('/')){
        newMarkers.add(mk);
      }
    });
    setState(() {
      markers = newMarkers;
      //circles = [];
    });
    fetchCsvFile('https://raw.githubusercontent.com/wcota/covid19br/master/cases-gps.csv', 'cases-gps.csv');

    Vibration.vibrate(duration: 10, amplitude: 255);
    if(_panelController.isPanelOpen) _panelController.close();
  }

   /// Called when the Google Map widget is created. Updates the map loading state and inits the markers.
  void _onMapCreated(GoogleMapController controller) async {
    _mapController.complete(controller);
    controller.setMapStyle(_mapStyle);
    _mapControllerLoaded = controller;
    
    fetchCsvFile('https://raw.githubusercontent.com/wcota/covid19br/master/cases-gps.csv', 'cases-gps.csv');
    fetchCsvFile('https://raw.githubusercontent.com/wcota/covid19br/master/cases-brazil-total.csv', 'cases-brazil-total.csv');
    
    fetchAllStates();
    fetchAllCountries();
  }

  void fetchGlobal() async{
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

  void fetchCountry(country) async {      
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

  void fetchAllCountries() async {      
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
          report: {'cases': formatted(country['cases'].toString()), 'deaths': infoDeaths, 'recovered': formatted(country['recovered'].toString()), 
            'cases_per1M': country['casesPerOneMillion'].toString(), 'deaths_per1M': country['deathsPerOneMillion'].toString()
          },
          labelColor: Colors.blue[700]
        );
        _locationsRegions.add(pinInfo);

        if(_db.getString('favorite_name') == country['country'].toString()){
          setState(() {
            currentlySelectedPin = pinInfo;
            pinPillPosition = 0;
            isFavorite = true;
          });
          goToFavoriteLocation();
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
                isFavorite = _db.getString('favorite_name') == country['country'].toString();
              });
            },
          )
        );
      }
      if(mounted){
        setState(() {
          markers = markers;
          _areMarkersLoading = false;
        });
      }
    } else {
      setState(() {
        errorMsg = 'Erro (' + response.statusCode.toString() + '): ' + response.body;
      });
      throw Exception('Erro ao carregar informações.');
    }
  }

  void fetchAllStates() async {      
    final response = await http.get('https://corona.lmao.ninja/v2/jhucsse/');
    
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      for(var country in jsonResponse){
        if(country['province'] != null && country['country'] != 'Brazil' && country['coordinates']['latitude'] != ''){
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
            labelColor: Colors.green[400]
          );
          _locationsRegions.add(pinInfo);

          if(_db.getString('favorite_name') == country['province'].toString()){
            setState(() {
              currentlySelectedPin = pinInfo;
              pinPillPosition = 0;
              isFavorite = true;
            });
            goToFavoriteLocation();
          }
          markers.add(
            Marker(
              markerId: new MarkerId(country['province'].toString()),
              position: location,
              icon: bitmapIconState,
              onTap: () {
                Vibration.vibrate(duration: 10, amplitude: 255);
                setState(() {
                  currentlySelectedPin = pinInfo;
                  pinPillPosition = 0;
                  isFavorite = _db.getString('favorite_name') == country['province'].toString();
                });
              },
            )
          );
        }
      }
      if(mounted){
        setState(() {
          markers =  markers;
          _areMarkersLoading = false;
        });
      }
    } else {
      setState(() {
        errorMsg = 'Erro (' + response.statusCode.toString() + '): ' + response.body;
      });
      throw Exception('Erro ao carregar informações.');
    }
  }

  void fetchCsvFile(link, filename) async {      
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
          
          MarkerId markerId = MarkerId(city[columnTitles.indexOf("name")].toString());
          String fatality = ((int.parse(deaths) / int.parse(city[columnTitles.indexOf("total")])) * 100).toStringAsFixed(2);
          String infoDeaths = formatted(deaths) + ' (' + fatality + '%)';
          if(fatality == '0.00') infoDeaths = formatted(deaths);

          PinInformation pinInfo = new PinInformation(
            locationName: city[columnTitles.indexOf("name")],
            lat: double.parse(city[columnTitles.indexOf("lat")].toString()),
            long: double.parse(city[columnTitles.indexOf("lon")].toString()),
            pinPath: "assets/images/pin-city.png",
            report: {'cases': formatted(city[columnTitles.indexOf("total")]), 'deaths': infoDeaths, 
              'cases_per100k': city[columnTitles.indexOf("total_per_100k_inhabitants")].toString()
            },
            labelColor: Colors.red
          );
          _locationsRegions.add(pinInfo);

          if(int.parse(city[columnTitles.indexOf("total")]) >= _minCasesCity){
            setState((){
              _countBRcities = _countBRcities + 1;
            });
            
            if(_db.getString('favorite_name') == city[columnTitles.indexOf("name")]){
              setState(() {
                currentlySelectedPin = pinInfo;
                pinPillPosition = 0;
                isFavorite = true;
              });
              goToFavoriteLocation();
            }

            markers.add(
              Marker(
                markerId: markerId,
                position: markerLocation,
                icon: bitmapIconCity,
                onTap: () {
                  Vibration.vibrate(duration: 10, amplitude: 255);
                  setState(() {
                    currentlySelectedPin = pinInfo;
                    pinPillPosition = 0;
                    isFavorite = _db.getString('favorite_name') == city[columnTitles.indexOf("name")];
                  });
                },
              ),
            );
          }

          if(int.parse(city[columnTitles.indexOf("total")]) >= 10000 && int.parse(city[columnTitles.indexOf("total")]) >= _minCasesCity){
            double radius = double.parse(city[columnTitles.indexOf("total")].toString()) * 3;
            if(radius > 30000) radius = 30000;
            else if(radius > 20000) radius = double.parse(city[columnTitles.indexOf("total")].toString());
            else if(radius >= 10000) radius = double.parse(city[columnTitles.indexOf("total")].toString()) * 2;
            
            radius = double.parse(city[columnTitles.indexOf("total")].toString());

            /*circles.add(Circle(
              circleId: CircleId('circle-' + city[columnTitles.indexOf("name")]),
              center: LatLng(double.parse(city[columnTitles.indexOf("lat")].toString()), double.parse(city[columnTitles.indexOf("lon")].toString())),
              radius: radius,
              strokeColor: Color.fromARGB(100, 200, 40, 40),
              fillColor: Color.fromARGB(30, 240, 40, 40),
              strokeWidth: 2,
            ));*/
          }
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
              //'suspects': formatted(st[columnTitles.indexOf("suspects")]), 'tests': formatted(st[columnTitles.indexOf("tests")]),
              //'cases_per100k': st[columnTitles.indexOf("totalCases_per_100k_inhabitants")].toString(),
              //'deaths_per100k': st[columnTitles.indexOf("deaths_per_100k_inhabitants")].toString()
              'vaccinated': st[columnTitles.indexOf("vaccinated")].toString()
            },
            labelColor: Colors.green[400]
          );
          _locationsRegions.add(pinInfo);

          if(_db.getString('favorite_name') == states[st[columnTitles.indexOf("state")]].name){
            setState(() {
              currentlySelectedPin = pinInfo;
              pinPillPosition = 0;
              isFavorite = true;
            });
            goToFavoriteLocation();
          }

          markers.add(
            Marker(
              markerId: markerId,
              position: markerLocation,
              icon: bitmapIconState,
              onTap: () {
                Vibration.vibrate(duration: 10, amplitude: 255);
                setState(() {
                  currentlySelectedPin = pinInfo;
                  pinPillPosition = 0;
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
    if(mounted){
      setState(() {
        markers =  markers;
        _areMarkersLoading = false;
      });
    }
  }

  String formatted(String str){
    if(str == '') return "";
    int val = int.parse(str);
    return new NumberFormat.decimalPattern('pt').format(val).toString();
  }

  searchLocation(pattern) async{
    List<String> places = [];
    if(pattern.length > 0){
      _locationsRegions.forEach((i){
        if(i.locationName.toLowerCase().contains(pattern.toLowerCase())){
          places.add(i.locationName);
        }
      });
      places.sort((a, b) => a.toString().compareTo(b.toString()));
      return places.toSet().toList(); // Remove duplicates
    } else{
      return [];
    }
  }
  
  void goToLocation(search){
    Vibration.vibrate(duration: 10, amplitude: 255);
    for(var i = 0; i < _locationsRegions.length; i++){
      var item = _locationsRegions[i];
      if(item.locationName.toLowerCase() == search.toLowerCase()){
        setState(() {
          currentlySelectedPin = item;
          pinPillPosition = 0;
          isFavorite = _db.getString('favorite_name') == item.locationName;
        });
        if(_panelController.isPanelOpen) _panelController.close();
        _mapControllerLoaded.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(item.lat, item.long), zoom: 10))
        );
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Opacity(
            opacity: _areMarkersLoading ? 0 : 1,
            child: GoogleMap(
              mapToolbarEnabled: false,
              myLocationEnabled: (_showLocation == PermissionStatus.granted),
              minMaxZoomPreference: new MinMaxZoomPreference(1.0, 12.0),
              initialCameraPosition: CameraPosition(
                target: LatLng(-18.2679862, -50.6720566),
                zoom: _currentZoom,
              ),
              markers: Set<Marker>.of(markers),
              //circles: Set<Circle>.of(circles),
              onMapCreated: (controller) => _onMapCreated(controller)
            ),
          ),

          MapPinPillComponent(
            pinPillPosition: pinPillPosition,
            currentlySelectedPin: currentlySelectedPin,
            isFavorite: isFavorite,
          ),
          
          SlidingUpPanel(
            controller: _panelController,
            backdropOpacity: 0.1,
            color: Colors.grey[100],
            backdropTapClosesPanel: true,
            backdropEnabled: true,
            header: Container(width: MediaQuery.of(context).size.width,height: 20, padding: new EdgeInsets.all(4.0),child: Align(alignment: Alignment.topCenter, child: Icon(Icons.arrow_upward, size: 25, color: Colors.blue))),
            minHeight: 40,
            maxHeight: 580,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0)),
            panel: Center(
              child: Details(configMarkers: configMarkers, searchLocation: searchLocation, goToLocation: goToLocation,
                minCasesCity: _minCasesCity, report: _globalInfo, reportBR: _countryInfo, countBRcities: _countBRcities),
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
            )
          ),

          // Map markers loading indicator
          if (_areMarkersLoading)
            (Padding(
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
              )
            ),
        ],
      ),
    );
  }
}