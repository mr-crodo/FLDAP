import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Weather App", style: TextStyle(color: Colors.black87)),
          centerTitle: true,
          backgroundColor: Colors.white,
          leading: IconButton(icon: Icon(Icons.menu), onPressed: () {}),
          iconTheme: IconThemeData(color: Colors.black54),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          actions: <Widget>[
            IconButton(icon: Icon(Icons.settings), onPressed: () {}),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }
}

Widget _buildBody() {
  return SingleChildScrollView(
    child: Column(children: <Widget>[_headerImage(), _weatherDescription()]),
  );
}

Widget _headerImage() {
  return Image(
    image: NetworkImage(
      'https://images.unsplash.com/photo-1566995589099-45de344a6dbe?q=80&w=3055&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    ),
    fit: BoxFit.cover,
  );
}

Widget _weatherDescription() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        'Tuesday - May 25',
        style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
      ),
      Divider(),
      Text(
        'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
        style: TextStyle(color: Colors.black54),
      ),
    ],
  );
}
