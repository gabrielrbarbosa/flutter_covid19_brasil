import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:statusbar/statusbar.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:covid_19_brasil/pages/charts_page.dart';
import 'package:covid_19_brasil/pages/map_page.dart';
import 'package:package_info/package_info.dart';

class DrawerItem {
  String title;
  IconData icon;
  DrawerItem(this.title, this.icon);
}

class HomePage extends StatefulWidget {  
  final drawerItems = [
    new DrawerItem("Casos de COVID-19 Brasil", Icons.location_on),
    new DrawerItem("Estatísticas", Icons.show_chart),
    new DrawerItem("Ministério da Saúde", Icons.healing),
    new DrawerItem("Dados Oficiais", Icons.pie_chart),
  ];
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  int _selectedDrawerIndex = 0;
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  void initState(){
    super.initState();
    StatusBar.color(Colors.blue);
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  aboutApp(){
    return showAboutDialog(context: context, applicationName: _packageInfo.appName, applicationVersion: _packageInfo.version, applicationIcon: FlutterLogo(), 
      applicationLegalese: """MIT License
        Copyright (c) 2021 Gabriel Ranéa Barbosa

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
        
        ------------------------------------------------
        Confirmed cases and deaths of COVID-19 in Brazil, at municipal (city) level. https://wcota.me/covid19br
        wcota/covid19br is licensed under the Creative Commons Attribution Share Alike 4.0 International
        """
      );
  }

  _getDrawerItemWidget(int pos) {
    switch (pos) {
      case 0:
        return MapPage();
      case 1:
        return ChartsPage();
      case 2:
        return (Container(
          child: WebView(
            key: Key('twitterIframe'),
            initialUrl: Uri.dataFromString('<html><body style="margin: 0; padding: 0;"><a class="twitter-timeline" href="https://twitter.com/minsaude?ref_src=twsrc%5Etfw">Tweets by minsaude</a> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script></body></html>', mimeType: 'text/html').toString(),
            javascriptMode: JavascriptMode.unrestricted
          )
        ));
      case 3:
        return Container(
          child: WebView(
            key: Key('covidGovIframe'),
            initialUrl: Uri.dataFromString('<html><body style="margin: 0; padding: 0;"><iframe style="width:100%;height:100%" src="https://covid.saude.gov.br/"></iframe></body></html>', mimeType: 'text/html').toString(),
            javascriptMode: JavascriptMode.unrestricted
          )
        );      
        break;
      default:
        return Text("Error");
    }
  }

  _onSelectItem(int index) {
    if (_scaffoldKey.currentState.isEndDrawerOpen) {
      _scaffoldKey.currentState.openDrawer();
    } else {
      _scaffoldKey.currentState.openEndDrawer();
    }
    if(index != _selectedDrawerIndex){
      setState(() => _selectedDrawerIndex = index );
    }
  }

  @override
  Widget build(BuildContext context) {
  var drawerOptions = <Widget>[];
    for (var i = 0; i < widget.drawerItems.length; i++) {
      var d = widget.drawerItems[i];
      drawerOptions.add(
        new ListTile(
          leading: new Icon(d.icon),
          title: new Text(d.title),
          selected: i == _selectedDrawerIndex,
          onTap: () => _onSelectItem(i),
        )
      );
    }
    drawerOptions.add(ListTile(
          leading: new Icon(Icons.info_outline),
          title: new Text("Sobre o Aplicativo"),
          onTap: () => aboutApp(),
        )
    );
    return FeatureDiscovery(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text(widget.drawerItems[_selectedDrawerIndex].title),
          backgroundColor: Colors.blue,
          brightness: Brightness.light
        ),
        drawer: new Drawer(
          child: new Column(
            children: <Widget>[
              new UserAccountsDrawerHeader(
                  accountName: null, 
                  accountEmail: null,
                  decoration: new BoxDecoration(image: new DecorationImage(
                    image: new AssetImage('assets/images/img_menu.png'),
                  )),),
              new Column(children: drawerOptions)
            ],
          ),
        ),
        body: _getDrawerItemWidget(_selectedDrawerIndex),
      ),
    );
  }
}

