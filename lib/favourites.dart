import 'package:flutter/material.dart';

class Favourites extends StatefulWidget
{
  @override
  State<StatefulWidget> createState() => favouriteState();
}

class favouriteState extends State<Favourites>
{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold provides the overall structure for the screen with an AppBar and body
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(style: TextStyle(color: Colors.white), "Favourites Page"),  // The title shown in the app's top bar
      ),
      // Padding widget adds space around the child widgets for better layout
      body: Padding(
        padding: const EdgeInsets.all(20.0),  // 20 pixels of padding on all sides
        // Column widget lays out its children in a vertical direction
        child: Column(
          children: <Widget>[
            Text('Favourites Database To Go Here'),


            SizedBox(height: 20),  // Adds 20 pixels of vertical space

            FloatingActionButton(
              onPressed: () {
                // pop the screen
                var value = 'pop';
                Navigator.pop(context, value);
              },
              child: Icon(Icons.save),
            ),
          ],
        ),
      ),
    );
  }
}

