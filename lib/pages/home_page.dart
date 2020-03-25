import 'package:flutter_downloader/flutter_downloader.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:fluster/fluster.dart';
import 'package:flutter/material.dart';
import 'package:covid_19_brasil/helpers/map_marker.dart';
import 'package:covid_19_brasil/helpers/map_helper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;

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
  final Set<Marker> _markers = Set();

  /// Minimum zoom at which the markers will cluster
  final int _minClusterZoom = 4;

  /// Maximum zoom at which the markers will cluster
  final int _maxClusterZoom = 12;

  /// [Fluster] instance used to manage the clusters
  Fluster<MapMarker> _clusterManager;

  /// Current map zoom
  double _currentZoom = 4;

  /// Map loading flag
  bool _isMapLoading = true;

  /// Markers loading flag
  bool _areMarkersLoading = true;

  /// Url image used on normal markers
  final String _markerImageUrl = 'https://img.icons8.com/office/80/000000/marker.png';

  /// Color of the cluster circle
  final Color _clusterColor = Colors.red;

  /// Color of the cluster text
  final Color _clusterTextColor = Colors.white;

  final List<MapMarker> markers = [];

  Map<String, dynamic> _countryInfo = {'cases': '0', 'active': '0', 'recovered': '0', 'deaths': '0'};
  String get info => 'Total de Casos: ' + _countryInfo["cases"].toString() + 
                      '\nCasos Ativos: ' + _countryInfo['active'].toString() +
                      '\nCasos Recuperados: ' + _countryInfo['recovered'].toString() +
                      '\nCasos Fatais: ' + _countryInfo['deaths'].toString();

  fetchData(country) async {
    final response =
      await http.get('https://corona.lmao.ninja/countries/' + country);

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

  /// Called when the Google Map widget is created. Updates the map loading state
  /// and inits the markers.
  void _onMapCreated(GoogleMapController controller) async {
    _mapController.complete(controller);

    setState(() {
      _isMapLoading = false;
    });

    fetchData('brazil');
     _requestDownload('https://raw.githubusercontent.com/wcota/covid19br/master/cases-gps.csv');
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
      _fileToString('cases-gps.csv');
    });
  }

  void _fileToString(filename) async{
    var dir = await getExternalStorageDirectory();
    var fullPath = dir.path + "/" + filename;
    File file = new File(fullPath);
    String text = await file.readAsString();
    _createMarkers(text);
  }

  void _createMarkers(txt) async{
    final BitmapDescriptor markerImage = await MapHelper.getMarkerImageFromUrl(_markerImageUrl);
    var rows = txt.split("\n");

    var count = 1;

    rows.forEach((strRow){
      if(strRow == "") return false;
      if(count > 1){
        var city = strRow.split(",");
        LatLng markerLocation = LatLng(double.parse(city[2].toString()), double.parse(city[3].toString()));
        InfoWindow info = new InfoWindow(title: city[1], snippet: 'Total: ' + city[4]);

        markers.add(
          MapMarker(
            id: count.toString(),
            position: markerLocation,
            icon: markerImage,
            infoWindow: info
          ),
        );
      }
      count++;
      return true;
    });

    _clusterManager = await MapHelper.initClusterManager(
      markers,
      _minClusterZoom,
      _maxClusterZoom,
    );

    _updateMarkers();
  }

  /// Gets the markers and clusters to be displayed on the map for the current zoom level and
  /// updates state.
  Future<void> _updateMarkers([double updatedZoom]) async {
    if (_clusterManager == null || updatedZoom == _currentZoom) return;

    if (updatedZoom != null) {
      _currentZoom = updatedZoom;
    }

    setState(() {
      _areMarkersLoading = true;
    });

    final updatedMarkers = await MapHelper.getClusterMarkers(
      _clusterManager,
      _currentZoom,
      _clusterColor,
      _clusterTextColor,
      80,
    );

    _markers
      ..clear()
      ..addAll(updatedMarkers);

    setState(() {
      _areMarkersLoading = false;
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
              markers: _markers,
              onMapCreated: (controller) => _onMapCreated(controller),
              onCameraMove: (position) => _updateMarkers(position.zoom),
              gestureRecognizers: Set()
              ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer()))
              ..add(Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer())),
            ),
          ),

          // Map loading indicator
          Opacity(
            opacity: _isMapLoading ? 1 : 0,
            child: Center(child: CircularProgressIndicator()),
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
