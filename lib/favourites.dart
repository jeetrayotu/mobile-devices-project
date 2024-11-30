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

      await model?.deleteSuggestionByName(suggestion.displayName, table: "favorites");
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
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: model == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Suggestion>>(
        // future: model!.getAllSuggestions(),
        future: model!.getAllSuggestions(table: "favorites"),
        builder: (BuildContext context, AsyncSnapshot<List<Suggestion>> snapshot) {
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('No favourites found. Tap to refresh.'),
                  onPressed: () {
                    setState(() {});
                  },
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final suggestion = snapshot.data![index];

              return Dismissible(
                key: Key(suggestion.displayName),
                background: Container(
                  color: Colors.blue,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    await _deleteSuggestion(suggestion);
                    return true;
                  }
                  return false;
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Text(
                      suggestion.displayName,
                      style: const TextStyle(color: Colors.black),
                    ),
                    subtitle: Text(
                      "Latitude: ${suggestion.coordinates.latitude}, Longitude: ${suggestion.coordinates.longitude}",
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
