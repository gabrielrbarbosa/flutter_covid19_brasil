import 'package:flutter_downloader/flutter_downloader.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../states.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  
  // Load page only once
  @override
  bool get wantKeepAlive => true;

  /// Set of displayed markers and cluster markers on the map
  List<Marker> markers = <Marker>[];
  double _currentZoom = 6;

  /// Map loading flag
  bool _isMapLoading = true;
  bool _areMarkersLoading = true;
  BitmapDescriptor bitmapIconCity, bitmapIconState;

  Map<String, dynamic> _countryInfo = {'cases': '0', 'active': '0', 'recovered': '0', 'deaths': '0'};
  String get info => 'Total: ' + _countryInfo["cases"].toString() + 
                      '\nAtivos: ' + _countryInfo['active'].toString() +
                      '\nRecuperados: ' + _countryInfo['recovered'].toString() +
                      '\nFatais: ' + _countryInfo['deaths'].toString();

  fetchData(country) async {
    final response = await http.get('https://corona.lmao.ninja/countries/' + country);
    
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      _countryInfo['cases'] = jsonResponse['cases'];
      _countryInfo['active'] = jsonResponse['active'];
      _countryInfo['recovered'] = jsonResponse['recovered'];
      _countryInfo['deaths'] = jsonResponse['deaths'];

      setState(() {
        _countryInfo = _countryInfo;
      });
    } else {
      throw Exception('Erro ao carregar informações.');
    }
  }

  /// Called when the Google Map widget is created. Updates the map loading state and inits the markers.
  void _onMapCreated(GoogleMapController controller) async {
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
    
    _mapController.complete(controller);

    fetchData('brazil');
    _requestDownload('https://raw.githubusercontent.com/wcota/covid19br/master/cases-gps.csv', 'cases-gps.csv');
    _requestDownload('https://raw.githubusercontent.com/wcota/covid19br/master/cases-brazil-total.csv', 'cases-brazil-total.csv');

     setState(() {
      _isMapLoading = false;
    });
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
    _createMarkers(text, filename);
  }

  void _createMarkers(txt, filename) async{
    var rows = txt.split("\n");

    if(filename == 'cases-gps.csv'){
      var count = 1;
      rows.forEach((strRow){
        if(strRow == "") return false;
        if(count > 1){
          var city = strRow.split(",");
          LatLng markerLocation = LatLng(double.parse(city[2].toString()), double.parse(city[3].toString()));
          InfoWindow info = new InfoWindow(title: city[1], snippet: 'Total: ' + city[4]);
          MarkerId markerId = MarkerId((count-1).toString());
          
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
      rows.forEach((strRow){
        if(strRow == "") return false;
        if(count > 2){
          var st = strRow.split(",");
          LatLng markerLocation = LatLng(
            states[st[1]].latitute, 
            states[st[1]].longitude
          );
          InfoWindow info = new InfoWindow(title: states[st[1]].name, snippet: 'Total: ' + st[2] + ' / Fatais: ' + st[5]);
          MarkerId markerId = MarkerId(st[1]);
          
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
          });
        }
        count++;
        return true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Google Map widget
          Opacity(
            opacity: 1,
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

          // Map markers loading indicator
          if (_areMarkersLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.bottomCenter,
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topRight,
                child: Card(
                  elevation: 2,
                  color: Colors.blue[300].withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      info,
                      style: TextStyle(color: Colors.white,
                      fontSize: 16),
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
