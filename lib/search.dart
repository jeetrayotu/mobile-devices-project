import 'package:flutter/material.dart';
// import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SearchScreen extends StatelessWidget {

  final TextEditingController _locationA = TextEditingController();
  final TextEditingController _locationB = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold provides the overall structure for the screen with an AppBar and body
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(style: TextStyle(color: Colors.white), "Search Locations"),  // The title shown in the app's top bar
      ),
      // Padding widget adds space around the child widgets for better layout
      body: Padding(
        padding: const EdgeInsets.all(20.0),  // 20 pixels of padding on all sides
        // Column widget lays out its children in a vertical direction
        child: Column(
          children: <Widget>[
            // TextField to input the location A
            TextField(
              controller: _locationA,
              decoration: InputDecoration(
                labelText: 'Location A: ',
                suffixIcon: IconButton(onPressed: () async{
                  var value = await showDialog(
                      context: context,
                      builder: (context) => showPopup()
                  );
                },

                    icon: Icon(Icons.favorite))
              ),
            ),
            // TextField to input location B
            TextField(
              controller: _locationB,
              decoration: InputDecoration(
                labelText: 'Location B: ',
                  suffixIcon: IconButton(onPressed: () async{
                    var value = await showDialog(
                        context: context,
                        builder: (context) => showPopup()
                    );
                  },

                      icon: Icon(Icons.favorite))
              ),
            ),

            SizedBox(height: 20),  // Adds 20 pixels of vertical space

            FloatingActionButton(
              onPressed: () {
                // Captures the text entered by the user in both fields
                final locationA = _locationA.text;
                final locationB = _locationB.text;

                // Checks if required fields are not empty before submitting
                if (locationA.isNotEmpty && locationB.isNotEmpty) {
                  // Passes the captured data back to the previous screen and pops (closes) this screen
                  Navigator.pop(context, {
                    'locationA': locationA,
                    'locationB': locationB,
                  }
                  );
                };
              },
              child: Icon(Icons.save),
            ),
          ],
        ),
      ),
    );
  }
}


class showPopup extends StatefulWidget
{
  @override
  State<StatefulWidget> createState() => showPopupState();
}

class showPopupState extends State<showPopup>
{
  Widget build(BuildContext context)
  {
    return SimpleDialog(
      title: Text('Choose sorting method'),
      children: [
        SimpleDialogOption(
          child: const Text('SHOW DATABASE OF FAVOURITED LOCATIONS'),
          onPressed: () {
            Navigator.pop(context, 'WORD'); // Closes the dialog and returns true
          },
        ),
      ],
    );
  }
}

//ElevatedButton.icon(onPressed: (){}, label: Text('favourite'))