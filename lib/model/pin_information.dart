import 'dart:ui';
import 'package:flutter/material.dart';

class PinInformation {
  String pinPath;
  Map<dynamic, dynamic> report;
  String locationName;
  Color labelColor;

  PinInformation({this.pinPath, this.report, this.locationName, this.labelColor});
}

class MapPinPillComponent extends StatefulWidget {

  double pinPillPosition;
  PinInformation currentlySelectedPin;

  MapPinPillComponent({ this.pinPillPosition, this.currentlySelectedPin });

  @override
  State<StatefulWidget> createState() => MapPinPillComponentState();
}

class MapPinPillComponentState extends State<MapPinPillComponent> {

  @override
  Widget build(BuildContext context) {

    return AnimatedPositioned(
      top: widget.pinPillPosition,
      right: 0,
      left: 0,
      duration: Duration(milliseconds: 300),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: EdgeInsets.only(left: 20, right: 20, top: 5),
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(50)),
              boxShadow: <BoxShadow>[
                BoxShadow(blurRadius: 20, offset: Offset.zero, color: Colors.grey.withOpacity(0.9))
              ]
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 40, height: 40,
                  margin: EdgeInsets.only(left: 10),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: new Image.asset(widget.currentlySelectedPin.pinPath, width: 50, height: 40),
                  )
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(widget.currentlySelectedPin.locationName, style: TextStyle(color: widget.currentlySelectedPin.labelColor)),
                        Text('Casos Confirmados: ${widget.currentlySelectedPin.report['cases'].toString()}', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        Text('Casos Fatais: ${widget.currentlySelectedPin.report['deaths'].toString()}', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Icon(Icons.close, color: Colors.grey,),
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