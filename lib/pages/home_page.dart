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

class _HomePageState extends State<HomePage>{
  final Completer<GoogleMapController> _mapController = Completer();

  /// Set of displayed markers and cluster markers on the map
  List<Marker> markers = <Marker>[];
  double _currentZoom = 4;

  /// Map loading flag
  bool _isMapLoading = true;
  bool _areMarkersLoading = true;
  BitmapDescriptor bitmapIconCity, bitmapIconState;

  Map<String, dynamic> _countryInfo = {'cases': 0, 'active': 0, 'recovered': 0, 'deaths': 0, 'fatality': 0};
  String get info => 'Total: ' + _countryInfo["cases"].toString() + 
                      '\nAtivos: ' + _countryInfo['active'].toString() +
                      '\nRecuperados: ' + _countryInfo['recovered'].toString() +
                      '\nFatais: ' + _countryInfo['deaths'].toString() +
                      '\nLetalidade: ' + _countryInfo['fatality'].toString() + '%';          

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

  fetchData(country) async {      
    final response = await http.get('https://corona.lmao.ninja/countries/' + country);
    
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      _countryInfo['cases'] = int.parse(jsonResponse['cases'].toString());
      _countryInfo['active'] = int.parse(jsonResponse['active'].toString());
      _countryInfo['recovered'] = int.parse(jsonResponse['recovered'].toString());
      _countryInfo['deaths'] = int.parse(jsonResponse['deaths'].toString());
      _countryInfo['fatality'] = ((_countryInfo['deaths'] / _countryInfo['cases']) * 100).toStringAsFixed(2);

      setState(() {
        _countryInfo = _countryInfo;
      });
    } else {
      throw Exception('Erro ao carregar informações.');
    }
  }

  /// Called when the Google Map widget is created. Updates the map loading state and inits the markers.
  void _onMapCreated(GoogleMapController controller) async {
    _mapController.complete(controller);

    fetchData('brazil');
    _requestDownload('https://raw.githubusercontent.com/wcota/covid19br/master/cases-gps.csv', 'cases-gps.csv');
    _requestDownload('https://raw.githubusercontent.com/wcota/covid19br/master/cases-brazil-total.csv', 'cases-brazil-total.csv');
  }

  void _requestDownload(link, filename) async{
    var dir = await getExternalStorageDirectory();
    await FlutterDownloader.enqueue(
      url: link,
      savedDir: dir.path,
      showNotification: false,
      openFileFromNotification: false
    );
    FlutterDownloader.registerCallback((id, status, progress) {
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
