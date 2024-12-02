import 'package:flutter/material.dart';
import 'history.dart';
import 'notifications.dart';
import 'suggestion.dart';

class Favourites extends StatefulWidget {
  final SuggestionModel? model;

  const Favourites({super.key, required this.title, this.model});

  final String title;

  @override
  State<StatefulWidget> createState() => _FavouritesState(model);
}

class _FavouritesState extends State<Favourites> {
  late SuggestionModel? model;
  Notifications notif = Notifications();

  _FavouritesState(this.model);

  @override
  void initState() {
    notif.init();
    super.initState();
  }

  Future<void> _deleteSuggestion(Suggestion suggestion) async {
    try {
      notif.sendNotificationNow(
        'Delete Suggestion',
        'Suggestion "${suggestion.displayName}" has been deleted',
        'Delete',
      );

      await model?.deleteSuggestionByName(suggestion.displayName,
          table: "favourites");
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting suggestion: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ),
      body: model == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Suggestion>>(
              // future: model!.getAllSuggestions(),
              future: model!.getAllSuggestions(table: "favourites"),
              builder: (BuildContext context,
                  AsyncSnapshot<List<Suggestion>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading favourites: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                          'No favourites found. Add them by swiping right on a location on the history page.'),
                    ),
                  );
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
                              // child: Icon(Icons.favorite, color: Colors.deepPurpleAccent),
                              child: Row(children: <Widget>[
                                Text(
                                  "Haha, ",
                                  // Adapted From:
                                  // Answer: https://stackoverflow.com/a/41557140
                                  // User: https://stackoverflow.com/users/1630961/dvdwasibi
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.deepPurpleAccent),
                                ),
                                Text(
                                  "nope!",
                                  // Adapted From:
                                  // Answer 1: https://stackoverflow.com/a/69172018
                                  // User 1: https://stackoverflow.com/users/16252358/tushar-patel
                                  // Answer 2: https://stackoverflow.com/a/41557140
                                  // User 2: https://stackoverflow.com/users/1630961/dvdwasibi
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.deepPurpleAccent),
                                )
                              ])),
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
                          if (direction == DismissDirection.endToStart) {
                            // Swipe left to delete from history
                            await _deleteSuggestion(suggestion);
                            return true; // Allow the dismiss (delete action)
                          }
                          return false;
                        },
                        child: Card(
                            color: Colors.deepPurpleAccent,
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
