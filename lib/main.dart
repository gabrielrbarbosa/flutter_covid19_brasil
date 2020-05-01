import 'package:flutter/material.dart';
import 'package:splashscreen/splashscreen.dart';
import 'package:covid_19_brasil/pages/home_page.dart';

void main() {
  runApp(MainPage());
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: new SplashScreen(
        seconds: 1,
        navigateAfterSeconds: new HomePage(),
        title: new Text('Informações sobre a COVID-19',
        style: new TextStyle(
          fontSize: 20.0
        ),),
        image: Image.asset('assets/images/img_menu.png'),
        backgroundColor: Colors.white,
        styleTextUnderTheLoader: new TextStyle(),
        photoSize: 200.0,
        loaderColor: Colors.white
      ),
    );
  }
}

