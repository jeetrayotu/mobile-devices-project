import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notifications.dart';
import 'suggestion.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import for notifications

// class Suggestion {
//   late String displayName;
//   late LatLng coordinates;
//   DocumentReference? reference;
//
//   Suggestion(this.displayName, this.coordinates, {this.reference});
//
//   Suggestion.fromMap(Map<String, dynamic> map) {
//     displayName = map['display_name'] ?? map['displayName'];
//     double latitude;
//     if (map['lat'] == null) {
//       latitude = double.parse(map['lat']);
//     } else if (map['latitude'] is double) {
//       latitude = map['latitude'];
//     } else {
//       latitude = double.parse(map['latitude']);
//     }
//     double longitude;
//     if (map['lon'] == null) {
//       longitude = double.parse(map['lon']);
//     } else if (map['latitude'] is double) {
//       longitude = map['longitude'];
//     } else {
//       longitude = double.parse(map['longitude']);
//     }
//     coordinates = LatLng(latitude, longitude);
//     reference = map['reference'];
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'displayName': displayName,
//       'latitude': coordinates.latitude.toString(),
//       'longitude': coordinates.longitude.toString(),
//     };
//   }
// }
//
// class SuggestionModel {
//   Database database;
//   FirebaseFirestore firebase = FirebaseFirestore.instance;
//
//   SuggestionModel(this.database);
//
//   Future<void> insertSuggestion(Suggestion suggestion,
//       {String table = 'history'}) async {
//     await database.insert(
//       table,
//       suggestion.toMap(),
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );
//   }
//
//   // Adapted From: https://firebase.google.com/docs/firestore/quickstart#add_data
//   Future<void> insertFireSuggestion(Suggestion suggestion,
//       {String table = 'history'}) async {
//     await firebase
//         .collection(table)
//         .add(suggestion.toMap())
//         .then((DocumentReference doc) => suggestion.reference = doc);
//   }
//
//   Future<void> updateSuggestion(Suggestion suggestion,
//       {String table = 'history'}) async {
//     await database.update(
//       table,
//       suggestion.toMap(),
//       where: "displayName = ?",
//       whereArgs: [suggestion.displayName],
//     );
//   }
//
//   // Adapted From: https://firebase.google.com/docs/firestore/manage-data/add-data#update-data
//   Future<void> updateFireSuggestion(Suggestion suggestion,
//       {String table = 'history'}) async {
//     if (suggestion.reference == null) {
//       await insertFireSuggestion(suggestion);
//     } else {
//       await firebase
//           .collection(table)
//           .doc(suggestion.reference!.id)
//           .update(suggestion.toMap());
//     }
//   }
//
//   Future<void> deleteSuggestionByName(String displayName,
//       {String table = 'history'}) async {
//     await database.delete(
//       table,
//       where: 'displayName = ?',
//       whereArgs: [displayName],
//     );
//   }
//
//   // Adapted From: https://firebase.google.com/docs/firestore/manage-data/delete-data#delete_documents
//   Future<void> deleteFireSuggestionById(String referenceId,
//       {String table = 'history'}) async {
//     await firebase.collection(table).doc(referenceId).delete();
//   }
//
//   // Method to read rows from the 'grades' table [7]
//   Future<List<Suggestion>> getAllSuggestions({String table = 'history'}) async {
//     final List<Map<String, dynamic>> maps = await database.query(table);
//     List<Suggestion> suggestions =
//         maps.map((suggestion) => Suggestion.fromMap(suggestion)).toList();
//     print(suggestions);
//     return suggestions;
//   }
//
//   // Adapted From: https://firebase.google.com/docs/firestore/query-data/get-data#get_all_documents_in_a_collection
//   // And:
//   // Answer: https://stackoverflow.com/a/45200659
//   // User: https://stackoverflow.com/users/5189745/hadrien-lejard
//   Future<List<Suggestion>> getAllFireSuggestions(
//       {String table = 'history'}) async {
//     List<Suggestion> suggestions = [];
//     await firebase.collection(table).get().then((querySnapshot) {
//       suggestions = querySnapshot.docs
//           .map((docSnapshot) => Suggestion.fromMap(
//               {...docSnapshot.data(), "reference": docSnapshot.reference}))
//           .toList();
//     });
//     return suggestions;
//   }
// }

class History extends StatefulWidget {
  final SuggestionModel? model;

  const History({super.key, required this.title, this.model});

  final String title;

  @override
  State<StatefulWidget> createState() => historyState(model);
}

class historyState extends State<History> {
  late SuggestionModel? model;
  bool showSnackBar = false;
  Notifications notif = Notifications();

  void initState() {
    notif.init();
    super.initState();
  }

  historyState(this.model);

  Future<void> _addSuggestionToFavourites(Suggestion suggestion) async {
    try {
      // Add to favourites table
      await widget.model?.insertSuggestion(suggestion, table: 'favourites');

      // Optionally show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Added "${suggestion.displayName}" to favourites')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to favourites: $e')),
      );
    }
  }

  String _getShortLocationName(String fullName) {
    // Split the full address by commas and return the first part
    List<String> parts = fullName.split(',');
    return parts.isNotEmpty ? parts[0].trim() : fullName;
  }

  Future<void> _deleteSuggestion(Suggestion suggestion) async {
    // Extract a shorter name from the full address (displayName)
    String locationName = _getShortLocationName(suggestion.displayName);

    notif.sendNotificationNow(
      'Delete Suggestion',
      'Suggestion "$locationName" has been deleted',
      'Delete',
    );

    await model!.deleteSuggestionByName(
      suggestion.displayName,
      table: 'history',
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold provides the overall structure for the screen with an AppBar and body
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.cyanAccent, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text(
            widget.title,
            style: const TextStyle(color: Colors.black),// The title shown in the app's top bar
          ),
        ),
      ),
      // Adapted From: https://chatgpt.com/share/671e8456-8e90-8000-b9de-afb2cd0d21a4
      // And:
      // Answer: https://stackoverflow.com/a/76126936
      // User: https://stackoverflow.com/users/1817391/aleksey
      body: model == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Suggestion>>(
              future: model!.getAllSuggestions(),
              builder: (BuildContext futureContext,
                  // Adapted From:
                  // Answer: https://stackoverflow.com/a/67482488
                  // User: https://stackoverflow.com/users/6413387/towhid
                  AsyncSnapshot<List<Suggestion>> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child:
                          CircularProgressIndicator()); // Show loading indicator while fetching data
                }

                if (snapshot.data!.isEmpty) {
                  return const Center(
                      child: Padding(
                          padding: EdgeInsets.all(70),
                          child: Text(
                              'No suggestions found. Add them by searching for and selecting locations on the previous screen')));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (itemContext, index) {
                    Suggestion suggestion = snapshot.data![index];
                    return Dismissible(
                        key: Key(suggestion.displayName),
                        // Adapted From: https://www.dhiwise.com/post/how-to-implement-flutter-swipe-action-cell-in-mobile-app
                        background: const Row(children: <Widget>[
                          Padding(
                              padding: EdgeInsets.only(left: 12),
                              child: Icon(Icons.favorite, color: Colors.blue)),
                          Spacer(),
                        ]),
                        secondaryBackground: const Row(children: <Widget>[
                          Spacer(),
                          Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.delete,
                                color: Colors.red,
                              ))
                        ]),

                        // Adapted From: https://docs.flutter.dev/cookbook/gestures/dismissible
                        // And:
                        // Answer: https://stackoverflow.com/a/64669848
                        // User: https://stackoverflow.com/users/8532605/unicornsonlsd
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Swipe right to add to favourites
                            await _addSuggestionToFavourites(suggestion);
                            return false; // Prevent the dismiss from happening
                          } else if (direction == DismissDirection.endToStart) {
                            // Swipe left to delete from history
                            await _deleteSuggestion(suggestion);
                            return true; // Allow the dismiss (delete action)
                          }
                          return false;
                        },
                        child: Card(
                            color: Colors.blue,
                            child: ListTile(
                              title: Text(suggestion.displayName,
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                  "Latitude: ${suggestion.coordinates.latitude} | Longitude: ${suggestion.coordinates.longitude}",
                                  style: const TextStyle(color: Colors.white)),
                            )));
                  },
                );
              },
            ),
    );
  }
}
