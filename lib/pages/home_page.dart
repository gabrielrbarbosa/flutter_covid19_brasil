
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:covid_19_brasil/pages/charts_page.dart';
import 'package:covid_19_brasil/pages/map_page.dart';

class DrawerItem {
  String title;
  IconData icon;
  DrawerItem(this.title, this.icon);
}

class HomePage extends StatefulWidget {  
  final drawerItems = [
    new DrawerItem("Mapa Geral", Icons.location_on),
    new DrawerItem("Estatísticas", Icons.show_chart),
    new DrawerItem("Dados por Estado", Icons.map),
    new DrawerItem("Ministério da Saúde", Icons.new_releases)
  ];
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
   int _selectedDrawerIndex = 0;
   bool _isLoadingPage = true;

   GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

   void initState(){
     super.initState();
   }

  _getDrawerItemWidget(int pos) {
    switch (pos) {
      case 0:
        return new MapPage();
      case 1:
        return new ChartsPage();
      case 2:
        return Container(
          child: WebView(
            key: new Key('statesMapIframe'),
            initialUrl: Uri.dataFromString('<html><body style="margin: 0; padding: 0;"><iframe style="width:100%;height:100%" src="https://e.infogr.am/coronavirus-brasil-1hd12yzmlwww4km?live"></iframe></body></html>', mimeType: 'text/html').toString(),
            javascriptMode: JavascriptMode.unrestricted,
          )
        );
      case 3:
        return Opacity(opacity: _isLoadingPage ? 0 : 1, child: (Container(
          child: WebView(
            key: new Key('twitterIframe'),
            initialUrl: Uri.dataFromString('<html><body style="margin: 0; padding: 0;"><a class="twitter-timeline" href="https://twitter.com/minsaude?ref_src=twsrc%5Etfw">Tweets by minsaude</a> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script></body></html>', mimeType: 'text/html').toString(),
            javascriptMode: JavascriptMode.unrestricted,
            onPageFinished: (finish) {
              setState(() {
                _isLoadingPage = false;
              });
            },
          )
        )));
      default:
        return new Text("Error");
    }
  }

  _onSelectItem(int index) {
    if (_scaffoldKey.currentState.isEndDrawerOpen) {
      _scaffoldKey.currentState.openDrawer();
    } else {
      _scaffoldKey.currentState.openEndDrawer();
    }
    setState(() => _selectedDrawerIndex = index);
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

    return new Scaffold(
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
                  accountName: new Text("Informações sobre a COVID-19 no Brasil", style: TextStyle(color: Colors.black45)), 
                  accountEmail: null,
                  decoration: new BoxDecoration(image: new DecorationImage(
                    image: new AssetImage('assets/images/img_menu.png'),
                  )),),
              new Column(children: drawerOptions)
            ],
          ),
        ),
        body: _getDrawerItemWidget(_selectedDrawerIndex),
    );
  }
}

