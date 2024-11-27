import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'favourites.dart';
import 'history.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  // await dotenv.load(fileName: "key.env"); // Ensure dotenv is loaded
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Map Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyMapPage(),
    );
  }
}

// final String _orsApiKey = dotenv.env['ORS_API_KEY'] ?? ''; // Load API key from .env
final String _orsApiKey =
    "5b3ce3597851110001cf6248915fcc15b154412d8281d6dd9c531ddf";

class MyMapPage extends StatefulWidget {
  @override
  _MyMapPageState createState() => _MyMapPageState();
}

class _MyMapPageState extends State<MyMapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<Suggestion> _suggestions = [];

  var textStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  var headerStyle = TextStyle(fontSize: 50, fontWeight: FontWeight.bold);

  LatLng _currentCenter = LatLng(43.9458, -78.8964); // Ontario Tech University
  // 43.891190, -78.862850
  LatLng? _destination; // Selected destination coordinates
  LatLng?
      _meetup; // Meetup spot halfway between destination and current location.
  List<LatLng> _routePoints = []; // Points for the polyline route
  SuggestionModel? _model;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    var dbPath = await getDatabasesPath();
    String path = join(dbPath, 'suggestiondatabase.db');

    _model = SuggestionModel(await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
            "CREATE TABLE history(displayName TEXT PRIMARY KEY, latitude TEXT, longitude TEXT)");
        await db.execute(
            "CREATE TABLE favourites(displayName TEXT PRIMARY KEY, latitude TEXT, longitude TEXT)");
      },
    ));
    // TODO
    // for (Suggestion suggestion in await _model!.getAllSuggestions(comparator: _comparator)) {
    //   _model!.deleteSuggestionByName(suggestion.displayName);
    // }
    print(await _model!.getAllSuggestions());
    setState(() {});
  }

  _goToHistory(context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => History(title: "History", model: _model)),
    );
  }

  _goToFavourites(context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Favourites(title: "Favourites")),
    );
  }

  showOptions(BuildContext context) async {
    var results =
        await showDialog(context: context, builder: (context) => showPopup());

    return results;
  }

  Future<void> _getSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    try {
      final response = await Dio().get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': input,
          'format': 'json',
          'addressdetails': 1,
          'limit': 5,
        },
      );

      setState(() {
        _suggestions = response.data
            .map<Suggestion>((suggestion) => Suggestion.fromMap(suggestion))
            .toList();
      });
    } catch (e) {
      print('Error fetching suggestions: $e');
    }
  }

  Future<void> _onSuggestionTap(Suggestion suggestion) async {
    setState(() {
      _destination = suggestion.coordinates;
      _suggestions = [];
      _searchController.clear();
    });
    _mapController.move(_destination!, 13.0);
    await _model!.insertSuggestion(suggestion);
    await _fetchMeetup(); // Fetch the meetup location when a destination is selected
    await _fetchRoute(); // Fetch the route when a destination is selected
  }

  // Calculate the halfway point between two coordinates
  LatLng calculateHalfwayPoint(LatLng coord1, LatLng? coord2) {
    return LatLng((coord1.latitude + coord2!.latitude) / 2,
        (coord1.longitude + coord2.longitude) / 2);
  }

  // Adapted From: https://ask.openrouteservice.org/t/find-nearest-x/3996
  // And: https://openrouteservice.org/dev/#/api-docs
  Future<void> _fetchMeetup() async {
    if (_destination == null) return;

    LatLng _halfway = calculateHalfwayPoint(_currentCenter, _destination);
    List<double> _halfwayCoordinates = [_halfway.longitude, _halfway.latitude];
    // [-78.88780834814952, 43.917912400000006]
    // {"type": "Point", "coordinates": [-78.88780834814952, 43.917912400000006]}
    print(_halfwayCoordinates);

    final meetupUrl = Uri.parse('https://api.openrouteservice.org/pois');

    try {
      final response = await http.post(meetupUrl,
          headers: {
            'Authorization': _orsApiKey,
            'Accept':
                'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
            'Content-Type': 'application/json; charset=utf-8'
          },
          // Adapted From: https://chatgpt.com/share/6737943d-d888-8000-9fa7-a08c34c1d057
          body: jsonEncode({
            'request': 'pois',
            'geometry': {
              'buffer': 500,
              'geojson': {
                'type': 'Point',
                'coordinates': _halfwayCoordinates,
              },
            },
            'limit': 2,
            'sortby': 'distance',
          }));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Meetup Coordinates Data: $data'); // Debug print

        if (data['features'] != null && data['features'].isNotEmpty) {
          final coordinates =
              data['features'][0]['geometry']['coordinates'] as List;

          setState(() {
            _meetup = LatLng(coordinates[1], coordinates[0]);
          });
          print("Meetup Coordinates: $_meetup"); // Debug print
        } else {
          print("No meetup coordinates in the response.");
        }
      } else {
        print(
            'Failed to load meetup coordinates: Error ${response.statusCode} with response ${response.body}');
      }
    } catch (e) {
      print('Error fetching meetup coordinates: $e');
    }
  }

  Future<void> _fetchRoute() async {
    if (_destination == null || _meetup == null) return;

    final routeUrl = Uri.parse(
      // 'https://api.openrouteservice.org/v2/directions/foot-walking?api_key=$_orsApiKey&start=${_currentCenter.longitude},${_currentCenter.latitude}&end=${_destination!.longitude},${_destination!.latitude}',
      'https://api.openrouteservice.org/v2/directions/driving-car/geojson',
    );

    try {
      final response = await http.post(routeUrl,
          headers: {
            'Authorization': _orsApiKey,
            'Accept':
                'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
            'Content-Type': 'application/json; charset=utf-8'
          },
          // Adapted From: https://chatgpt.com/share/6737943d-d888-8000-9fa7-a08c34c1d057
          // And: https://openrouteservice.org/dev/#/api-docs
          body: jsonEncode({
            'coordinates': [
              [_currentCenter.longitude, _currentCenter.latitude],
              [_meetup!.longitude, _meetup!.latitude],
              [_destination!.longitude, _destination!.latitude]
            ],
          }));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Route data: $data'); // Debug print

        if (data['features'].isNotEmpty) {
          final coordinates =
              data['features'][0]['geometry']['coordinates'] as List;

          setState(() {
            _routePoints = coordinates.map((coord) {
              return LatLng(coord[1], coord[0]); // Convert to LatLng
            }).toList();
          });
          print("Route points: $_routePoints"); // Debug print
        } else {
          print("No route found in the response.");
        }
      } else {
        print('Failed to load route: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Meet Me There'),
        actions: [
          IconButton(
              onPressed: () {
                _goToFavourites(context);
              },
              icon: const Icon(
                Icons.favorite,
                color: Colors.white,
              )),
          IconButton(
              onPressed: () {
                _goToHistory(context);
              },
              icon: const Icon(
                Icons.history,
                color: Colors.white,
              )),
          IconButton(
              onPressed: () async {
                for (Suggestion suggestion
                    in await _model!.getAllSuggestions()) {
                  _model!.updateFireSuggestion(suggestion);
                }
              },
              icon: const Icon(
                Icons.upload,
                color: Colors.white,
              )),
          IconButton(
              onPressed: () async {
                for (Suggestion suggestion
                    in await _model!.getAllFireSuggestions()) {
                  _model!.insertSuggestion(suggestion);
                }
              },
              icon: const Icon(
                Icons.download,
                color: Colors.white,
              ))
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                      hintText: "Search destination",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                          onPressed: () {
                            var result = showOptions(context);
                          },
                          icon: const Icon(Icons.menu))),
                  onChanged: _getSuggestions,
                ),
                if (_suggestions.isNotEmpty)
                  Container(
                    height: 150,
                    child: ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return Row(children: <Widget>[
                          ListTile(
                            title: Text(suggestion.displayName),
                            onTap: () => _onSuggestionTap(suggestion),
                          ),
                          IconButton(
                              onPressed: () => setState(() {
                                    if (suggestion.favourited) {
                                      suggestion.favourited = false;
                                      _model!.deleteSuggestionByName(
                                          suggestion.displayName,
                                          table: "favourites");
                                    } else {
                                      suggestion.favourited = true;
                                      _model!.insertSuggestion(suggestion,
                                          table: "favourites");
                                    }
                                  }),
                              icon: Icon(suggestion.favourited
                                  ? Icons.favorite
                                  : Icons.favorite_outline)),
                        ]);
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _currentCenter,
                zoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: _currentCenter,
                      builder: (ctx) => const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 40.0,
                      ),
                    ),
                    if (_destination != null)
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: _destination!,
                        builder: (ctx) => const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40.0,
                        ),
                      ),
                    if (_destination != null)
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: _meetup!,
                        builder: (ctx) => const Icon(
                          Icons.location_pin,
                          color: Colors.green,
                          size: 40.0,
                        ),
                      ),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue, // Route color
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class showPopup extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => showPopupState();
}

class showPopupState extends State<showPopup> {
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text('Saved Locations'),
      children: [
        SimpleDialogOption(
          child: const Text('SHOWS DATABASE OF SAVED LOCATIONS FOR SELECTION'),
          onPressed: () {
            Navigator.pop(
                context, 'WORD'); // Closes the dialog and returns true
          },
        ),
      ],
    );
  }
}
