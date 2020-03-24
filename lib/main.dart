import 'package:flutter/material.dart';
import 'package:covid_19_brasil/pages/home_page.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

void main() => runApp(MainPage());

class DrawerItem {
  String title;
  IconData icon;
  DrawerItem(this.title, this.icon);
}

class MainPage extends StatefulWidget {  
  final drawerItems = [
    new DrawerItem("Cidades", Icons.location_on),
    new DrawerItem("Estados", Icons.location_searching)
    //new DrawerItem("Países", Icons.map)
  ];
  @override
  State<StatefulWidget> createState() {
    return _MainPage();
  }
}

class _MainPage extends State<MainPage> {
   int _selectedDrawerIndex = 0;
   int flag = 0;

  _loadFlutterDownloader() async{
    await FlutterDownloader.initialize();
  }

  _getDrawerItemWidget(int pos) {
    if(pos == 0 && flag == 0){
      _loadFlutterDownloader();
      flag = 1;
    }

    switch (pos) {
      case 0:
        return new HomePage();
      case 1:
        return Container(
          child: WebView(
            initialUrl: Uri.dataFromString('<html><body style="margin: 0; padding: 0;"><iframe style="width:100%;height:100%" src="https://e.infogr.am/coronavirus-brasil-1hd12yzmlwww4km?live"></iframe></body></html>', mimeType: 'text/html').toString(),
            javascriptMode: JavascriptMode.unrestricted,
          )
        );
      case 2:
        return Container(
          child: WebView(
            initialUrl: Uri.dataFromString('<html><body style="margin: 0; padding: 0;"><iframe style="width:100%;height:100%" src="https://bing.com/covid"></iframe></body></html>', mimeType: 'text/html').toString(),
            javascriptMode: JavascriptMode.unrestricted,
          )
        );
      default:
        return new Text("Error");
    }
  }

  _onSelectItem(int index) {
    setState(() => _selectedDrawerIndex = index);
    Navigator.of(context).pop(); // close the drawer
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

    return MaterialApp(
      home: Scaffold(
      appBar: new AppBar(
        title: new Text(widget.drawerItems[_selectedDrawerIndex].title),
      ),
      drawer: new Drawer(
        child: new Column(
          children: <Widget>[
            new UserAccountsDrawerHeader(
                accountName: new Text("Informações do Coronavírus no Brasil"), accountEmail: null),
            new Column(children: drawerOptions)
          ],
        ),
      ),
      body: _getDrawerItemWidget(_selectedDrawerIndex),
    ),
    );
  }
}

