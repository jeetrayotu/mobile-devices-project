import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'notifications.dart';
import 'suggestion.dart';

class History extends StatefulWidget {
  final SuggestionModel? model;

  const History({super.key, required this.title, this.model});

  final String title;

  @override
  State<StatefulWidget> createState() => HistoryState(model);
}

class HistoryState extends State<History> {
  late SuggestionModel? model;
  bool showSnackBar = false;
  Notifications notif = Notifications();

  @override
  void initState() {
    notif.init();
    super.initState();
  }

  HistoryState(this.model);

  Future<void> _addSuggestionToFavourites(Suggestion suggestion) async {
    try {
      // Add to favourites table
      await widget.model?.insertSuggestion(suggestion, table: 'favourites');

      // Optionally show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
              '${FlutterI18n.translate(context, "message.added")} "${suggestion.displayName}" ${FlutterI18n.translate(context, "message.toFavourites")}',
            )
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${FlutterI18n.translate(context, "message.addingToFavourites")}: $e')),
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
      FlutterI18n.translate(context, "notification.locationDeleted"),
      '${locationName} ${FlutterI18n.translate(context, "notification.deletedFromHistory")}',
      FlutterI18n.translate(context, "notification.delete"),
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
            FlutterI18n.translate(context, "history.title"),
            style: const TextStyle(color: Colors.black), // The title shown in the app's top bar
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
                  return Center(
                      child: Padding(
                          padding: EdgeInsets.all(70),
                          child: Text(FlutterI18n.translate(context, "history.empty"))));
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
                                  "${FlutterI18n.translate(context, "coordinates.latitude")}: ${suggestion.coordinates.latitude} | ${FlutterI18n.translate(context, "coordinates.longitude")}: ${suggestion.coordinates.longitude}",
                                  style: const TextStyle(color: Colors.white)),
                            )));
                  },
                );
              },
            ),
    );
  }
}
