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
      body: Center(
        child:Padding(
            padding: const EdgeInsets.all(20.0),  // 20 pixels of padding on all sides
            // Column widget lays out its children in a vertical direction
            child: IconButton(icon: const Icon(Icons.refresh),
              onPressed: (){
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No Favourites found'),
                      action: SnackBarAction(label: 'Okay', onPressed: (){}),
                    )
                );
              },
            )
        ),
      )
    );
  }
}

