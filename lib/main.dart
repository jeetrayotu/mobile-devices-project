import 'package:flutter/material.dart';
import 'search.dart';

var size = 20;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meet You There',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Meet You There Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  var textStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  var headerStyle = TextStyle(fontSize: 50, fontWeight: FontWeight.bold);
  var halfwayName = '';
  var halfwayAddress = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Expanded(child: Container(color: Colors.blue, width: double.infinity,
                child: Text('Map')
            ), flex: 2,),
            Expanded(child: Container(color: Colors.black12, width: double.infinity,
                child: Column(
                  children: [
                  Text('Halfway Point', style: headerStyle),
                  Align(alignment: Alignment.centerLeft, child: Text('Location: $halfwayName', style: textStyle)),
                  Align(alignment: Alignment.centerLeft, child: Text('Address: $halfwayName', style: textStyle)),
                ],
                ),
            ))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async{
          final locations = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SearchScreen()),
          );
          if (locations!=null)
            {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Halfway Point located}'))
              );
              setState(() {
                halfwayName = locations.toString();
                halfwayAddress = locations.toString();
              });
            }
        },
        child: const Icon(Icons.search),
      ),
    );
  }
}



/* TODO
* three screens: history screen (to scroll through past search)(DATABASE), favourite screen
*
*
*
* dialouge and picker
* notification
* snackbar
* local storage
* cloud storage
* HTTP requests
*
* firebase sotrage linked to local database
* refresh
*
*/