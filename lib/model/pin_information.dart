import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class PinInformation {
  final String pinPath, locationName;
  final Map<dynamic, dynamic> report;
  final Color labelColor;
  final double lat, long;

  PinInformation({this.pinPath, this.report, this.locationName, this.labelColor, this.lat, this.long});
}

class MapPinPillComponent extends StatefulWidget {
  double pinPillPosition;
  bool isFavorite;
  final PinInformation currentlySelectedPin;

  MapPinPillComponent({ Key key, this.pinPillPosition, this.currentlySelectedPin, this.isFavorite }) : super(key: key);

  @override
  State<StatefulWidget> createState() => MapPinPillComponentState();
}

class MapPinPillComponentState extends State<MapPinPillComponent> {
  SharedPreferences db;
  String _favoriteLocation = '';

  void initState(){
    super.initState();
    initPrefs();
  }
  
  void initPrefs() async{
    db = await SharedPreferences.getInstance();
    _favoriteLocation = (db.getString('favorite_name') ?? '');
  }

  void changeFavoriteCity(isLiked) async{
    _favoriteLocation = (db.getString('favorite_name') ?? '');
    if(_favoriteLocation != widget.currentlySelectedPin.locationName && !isLiked){
      db.setString('favorite_name', widget.currentlySelectedPin.locationName);
      db.setDouble('favorite_latitude', widget.currentlySelectedPin.lat);
      db.setDouble('favorite_longitude', widget.currentlySelectedPin.long);
    } else if(isLiked){
      db.setString('favorite_name', '');
      db.setDouble('favorite_latitude', 0);
      db.setDouble('favorite_longitude', 0);
    }
  }

  Future<bool> onLikeButtonTapped(bool isLiked) async{
    Vibration.vibrate(duration: 10, amplitude: 255);
    changeFavoriteCity(isLiked);
    
    return !isLiked;
  }

  @override
  Widget build(BuildContext context) {

    return AnimatedPositioned(
      top: widget.pinPillPosition,
      right: 0,
      left: 0,
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 200),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: EdgeInsets.only(left: 20, right: 20, top: 5),
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20)),
              boxShadow: <BoxShadow>[
                BoxShadow(blurRadius: 10, offset: Offset.zero, color: Colors.grey)
              ]
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(left: 15),
                  child: LikeButton(
                    size: 30,
                    circleColor: CircleColor(start: Colors.yellowAccent, end: Colors.orange),
                    bubblesColor: BubblesColor(
                      dotPrimaryColor: Colors.yellowAccent,
                      dotSecondaryColor: Colors.orange,
                    ),
                    isLiked: widget.isFavorite,
                    likeBuilder: (bool isLiked) {
                      return Icon(
                        isLiked ? Icons.star : Icons.star_border,
                        color: isLiked ? Colors.yellow[600] : Colors.grey,
                        size: 30,
                      );
                    },
                    onTap: onLikeButtonTapped,
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        RichText(
                          text: TextSpan(
                            style: TextStyle(color: widget.currentlySelectedPin.labelColor, fontSize: 14, fontWeight: FontWeight.bold),
                            children: [
                              WidgetSpan(
                                child: Padding(
                                  padding: EdgeInsets.only(right: 5.0),
                                  child: Icon(Icons.location_on, color: widget.currentlySelectedPin.labelColor, size: 16),
                                ),
                              ),
                              TextSpan(text: widget.currentlySelectedPin.locationName),
                            ],
                          ),
                        ),
                        if(widget.currentlySelectedPin.report['cases'] != null) Text('Casos Confirmados: ${widget.currentlySelectedPin.report['cases'].toString()}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        if(widget.currentlySelectedPin.report['recovered'] != null) Text('Casos Recuperados: ${widget.currentlySelectedPin.report['recovered'].toString()}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        if(widget.currentlySelectedPin.report['deaths'] != null) Text('Casos Fatais: ${widget.currentlySelectedPin.report['deaths'].toString()}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        if(widget.currentlySelectedPin.report['total_per100k'] != null) Text('Casos por 100 mil: ${widget.currentlySelectedPin.report['total_per100k'].toString()}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        if(widget.currentlySelectedPin.report['deaths_per100k'] != null) Text('Mortes por 100 mil: ${widget.currentlySelectedPin.report['deaths_per100k'].toString()}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  child: Container(
                    child: Padding(
                      padding: EdgeInsets.all(15),
                      child: Icon(Icons.close, color: Colors.grey,),
                    ),
                  ),
                  onTap: (){
                    setState(() {
                      widget.pinPillPosition = -100;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      );
  }
}