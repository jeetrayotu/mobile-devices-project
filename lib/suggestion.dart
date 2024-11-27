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

    // If local results are insufficient, fetch external suggestions
    if (historySuggestions.isEmpty) {
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
              return Suggestion.fromMap(suggestion as Map<String, dynamic>);
            } catch (e) {
              print('Error parsing external suggestion: $e');
              throw Exception('Invalid suggestion format');
            }
          })
              .toList();

          // Save external suggestions to history for future use
          for (var suggestion in externalSuggestions) {
            await insertSuggestion(suggestion);
          }

          return externalSuggestions;
        }
      } catch (e) {
        print('Error fetching external suggestions: $e');
      }
    }

    return historySuggestions;
  }

  Future<void> insertSuggestion(Suggestion suggestion) async {
    try {
      await database.insert(
        'history',
        suggestion.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error inserting suggestion: $e');
    }
  }

  // Method to get all suggestions from history
  Future<List<Suggestion>> getAllSuggestions() async {
    final List<Map<String, dynamic>> results = await database.query('history');
    return results.map((map) => Suggestion.fromMap(map)).toList();
  }

  // Method to delete a suggestion by name
  Future<void> deleteSuggestionByName(String displayName) async {
    await database.delete(
      'history',
      where: 'displayName = ?',
      whereArgs: [displayName],
    );
  }

  // Methods for handling Firebase suggestions (based on the upload/download icons in the main file)
  Future<void> updateFireSuggestion(Suggestion suggestion) async {
    // Implement Firebase update logic
    try {
      await FirebaseFirestore.instance
          .collection('suggestions')
          .doc(suggestion.displayName)
          .set(suggestion.toMap());
    } catch (e) {
      print('Error updating Firebase suggestion: $e');
    }
  }

  Future<List<Suggestion>> getAllFireSuggestions() async {
    // Implement Firebase fetch logic
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('suggestions')
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