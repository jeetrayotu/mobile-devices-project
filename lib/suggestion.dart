import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';

class Suggestion {
  late String displayName;
  late LatLng coordinates;
  DocumentReference? reference;

  Suggestion(this.displayName, this.coordinates, {this.reference});

  // Adapted From:
  // Answer: https://stackoverflow.com/a/62867620
  // User: https://stackoverflow.com/users/179715/jamesdlin
  // And: https://dart.dev/tools/linter-rules/hash_and_equals
  @override
  bool operator ==(Object other) =>
      other is Suggestion &&
          other.coordinates == coordinates;

  // Adapted From:
  // Answer: https://stackoverflow.com/a/62867620
  // User: https://stackoverflow.com/users/179715/jamesdlin
  // And: https://dart.dev/tools/linter-rules/hash_and_equals
  @override
  int get hashCode => coordinates.hashCode;

  Suggestion.fromMap(Map<String, dynamic> map) {
    displayName = map['display_name'] ?? map['displayName'] ?? 'Unknown Location';

    // Parse latitude
    dynamic lat = map['latitude'] ?? map['lat'];
    double latitude = lat is String ? double.parse(lat) : lat;

    // Parse longitude
    dynamic lon = map['longitude'] ?? map['lon'];
    double longitude = lon is String ? double.parse(lon) : lon;

    coordinates = LatLng(latitude, longitude);
    reference = map['reference'];
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'latitude': coordinates.latitude.toString(),
      'longitude': coordinates.longitude.toString(),
    };
  }
}

class SuggestionModel {
  Database database;

  SuggestionModel(this.database);

  Future<List<Suggestion>> searchSuggestions(String query) async {
    // First, search in local history database
    final List<Map<String, dynamic>> localResults = await database.query(
      'history',
      where: 'displayName LIKE ?',
      whereArgs: ['%$query%'],
    );

    List<Suggestion> historySuggestions = localResults
        .map((map) => Suggestion.fromMap(map))
        .toList();

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': 5,
        },
      );

      if (response.data != null && response.data is List) {
        final externalSuggestions = response.data
            .where((dynamic suggestion) => suggestion is Map<String, dynamic>) // Filter valid maps
            .map<Suggestion>((dynamic suggestion) {
          try {
            return Suggestion.fromMap(suggestion);
          } catch (e) {
            print('Error parsing external suggestion: $e');
            throw Exception('Invalid suggestion format');
          }
        })
            .toList();

        // Save external suggestions to history for future use
        // for (var suggestion in externalSuggestions) {
        //   await insertSuggestion(suggestion);
        // }

        // Adapted From:
        // Answer: https://stackoverflow.com/a/51446910
        // User: https://stackoverflow.com/users/1058292/atreeon
        return Set<Suggestion>.from(historySuggestions + externalSuggestions).toList();
      }
    } catch (e) {
      print('Error fetching external suggestions: $e');
    }

    return historySuggestions;
  }

  Future<void> insertSuggestion(Suggestion suggestion, {String table = 'history'}) async {
    try {
      await database.insert(
        table,
        suggestion.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await FirebaseFirestore.instance
          .collection(table)
          .doc(suggestion.displayName)
          .set(suggestion.toMap());
    } catch (e) {
      print('Error inserting suggestion: $e');
    }
  }

  // Method to get all suggestions from history
  Future<List<Suggestion>> getAllSuggestions({String table = 'history'}) async {
    final List<Map<String, dynamic>> results = await database.query(table);
    return results.map((map) => Suggestion.fromMap(map)).toList();
  }

  // Method to delete a suggestion by name
  Future<void> deleteSuggestionByName(String name, {String table = "history"}) async {
    await database.delete(
      table,
      where: "displayName = ?",
      whereArgs: [name],
    );
    await FirebaseFirestore.instance.collection('grades').doc(name).delete();
  }

  Future<List<Suggestion>> getAllFireSuggestions({String table = "history"}) async {
    // Implement Firebase fetch logic
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(table)
          .get();

      return querySnapshot.docs
          .map((doc) => Suggestion.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching Firebase suggestions: $e');
      return [];
    }
  }
}