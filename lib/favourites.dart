import 'package:flutter/material.dart';
import 'history.dart';
import 'notifications.dart';

class Favourites extends StatefulWidget {
  final SuggestionModel? model;

  const Favourites({super.key, required this.title, this.model});

  final String title;

  @override
  State<StatefulWidget> createState() => favouritesState(model);
}

class favouritesState extends State<Favourites> {
  late SuggestionModel? model;
  bool showSnackBar = false;
  Notifications notif = Notifications();

  void initState()
  {
    notif.init();
    super.initState();
  }

  favouritesState(this.model);

  Future<void> _deleteSuggestion(Suggestion suggestion) async {
    notif.sendNotificationNow('Delete Suggestion', 'Suggestion Deleted', 'Delete');

    await model!.deleteSuggestionByName(suggestion.displayName);
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold provides the overall structure for the screen with an AppBar and body
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
            style: const TextStyle(color: Colors.white),
            widget.title), // The title shown in the app's top bar
      ),
      // Adapted From: https://chatgpt.com/share/671e8456-8e90-8000-b9de-afb2cd0d21a4
      // And:
      // Answer: https://stackoverflow.com/a/76126936
      // User: https://stackoverflow.com/users/1817391/aleksey
      body: model == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Suggestion>>(
        future: model!.getAllSuggestions(table: "favourites"),
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
                    padding: const EdgeInsets.all(70),
                    child: IconButton(icon: const Icon(Icons.refresh),
                      onPressed: (){
                        // Display message if no values are found
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No suggestions found. Add them by searching for locations on the previous screen'),
                              action: SnackBarAction(label: 'Okay', onPressed: (){}),
                            )
                        );
                      },
                    )
                ));
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
                        child: Icon(Icons.edit, color: Colors.blue)),
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
                    // Adapted From: https://www.dhiwise.com/post/how-to-implement-flutter-swipe-action-cell-in-mobile-app
                    if (direction == DismissDirection.endToStart) {
                      await _deleteSuggestion(suggestion);
                      return true;
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
