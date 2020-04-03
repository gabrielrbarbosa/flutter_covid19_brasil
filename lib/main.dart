
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splashscreen/splashscreen.dart';
import 'package:covid_19_brasil/pages/home_page.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.blue, // navigation bar color
    statusBarColor: Colors.pink, // status bar color
  ));
  runApp(MainPage());
}

class DrawerItem {
  String title;
  IconData icon;
  DrawerItem(this.title, this.icon);
}

class MainPage extends StatefulWidget {  
  final drawerItems = [
    new DrawerItem("Mapa Geral", Icons.location_on),
    new DrawerItem("Estatísticas", Icons.show_chart),
    new DrawerItem("Dados por Estado", Icons.map),
    new DrawerItem("Ministério da Saúde", Icons.new_releases)
  ];
  @override
  State<StatefulWidget> createState() {
    return _MainPage();
  }
}

class AfterSplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new HomePage();
  }
}

class _MainPage extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: new SplashScreen(
        seconds: 2,
        navigateAfterSeconds: new AfterSplashScreen(),
        title: new Text('Informações sobre a COVID-19',
        style: new TextStyle(
          fontSize: 20.0
        ),),
        image: Image.asset('assets/images/img_menu.png'),
        backgroundColor: Colors.white,
        styleTextUnderTheLoader: new TextStyle(),
        photoSize: 200.0,
        loaderColor: Colors.blue
      ),
    );
  }
}

