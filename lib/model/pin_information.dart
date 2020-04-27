import 'package:flutter/material.dart';

class PinInformation {
  String pinPath;
  Map<dynamic, dynamic> report;
  String locationName;
  Color labelColor;

  PinInformation({this.pinPath, this.report, this.locationName, this.labelColor});
}

class MapPinPillComponent extends StatefulWidget {

  double pinPillPosition, height;
  PinInformation currentlySelectedPin;

  MapPinPillComponent({
    Key key,
    this.pinPillPosition,
    this.currentlySelectedPin,
    this.height
  }) : super(key: key);

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
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 200),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: EdgeInsets.only(left: 20, right: 20, top: 5),
            height: widget.height,
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
                        Text(widget.currentlySelectedPin.locationName, style: TextStyle(color: widget.currentlySelectedPin.labelColor, fontSize: 14, fontWeight: FontWeight.bold)),
                        if(widget.currentlySelectedPin.report['cases'] != null) Text('Casos Confirmados: ${widget.currentlySelectedPin.report['cases'].toString()}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        if(widget.currentlySelectedPin.report['recovered'] != null) Text('Casos Recuperados: ${widget.currentlySelectedPin.report['recovered'].toString()}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        if(widget.currentlySelectedPin.report['deaths'] != null) Text('Casos Fatais: ${widget.currentlySelectedPin.report['deaths'].toString()}', style: TextStyle(fontSize: 14, color: Colors.grey[600]))
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