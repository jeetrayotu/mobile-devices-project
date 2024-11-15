import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as Path;
import 'package:csv/csv.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Node {// the node class, contains the location and list of nearby nodes
  int _id;
  List<Node> _nearbyNodes = [];
  List<int> _xy = [0, 0];

  Node(this._id, [List<int>? xy]) {
    if (xy != null && xy.length == 2) {
      _xy = xy;
    }
  }

  int get id => _id;
  List<Node> get nearbyNodes => _nearbyNodes;
  List<int> get xy => _xy;

  void addNearbyNode(Node node) {
    _nearbyNodes.add(node);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'x': _xy[0],
      'y': _xy[1],
      'nearbyNodes': jsonEncode(_nearbyNodes.map((n) => n.id).toList()),
    };
  }

  static Future<List<Node>> loadNodesFromCSV() async {
    final csvString = await rootBundle.loadString('assets/nodes.csv');
    final lines = csvString.split('\n');
    Map<int, Node> nodeMap = {};
    List<List<dynamic>> connections = [];

    // First pass: Create nodes and populate nodeMap
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || !line.endsWith(';')) continue;
      line = line.substring(0, line.length - 1);
      final row = CsvToListConverter().convert(line)[0];
      int id = row[0];
      int x = row[1];
      int y = row[2];
      Node node = Node(id, [x, y]);
      nodeMap[id] = node;
      connections.add(row);
    }

    // Second pass: Establish bidirectional links using nearby node IDs
    for (var row in connections) {
      int id = row[0];
      Node node = nodeMap[id]!;
      List<int> nearbyIds = row.sublist(3).map((e) => int.parse(e.toString())).toList();
      for (int nearbyId in nearbyIds) {
        Node? nearbyNode = nodeMap[nearbyId];
        if (nearbyNode != null && !node.nearbyNodes.contains(nearbyNode)) {
          node.addNearbyNode(nearbyNode);
          nearbyNode.addNearbyNode(node);
        }
      }
    }

    return nodeMap.values.toList();
  }

  // Override the toString method to display id, coordinates, and nearby node IDs, for testing
  @override
  String toString() {
    List<int> nearbyIds = _nearbyNodes.map((n) => n.id).toList();
    return 'Node{id: $_id, coordinates: ($_xy), connected to: $nearbyIds}';
  }
}

class DatabaseHelper {//database, don't delete or edit
  static final DatabaseHelper instance = DatabaseHelper._internal();
  Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = Path.join(await getDatabasesPath(), 'nodes.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE nodes(
            id INTEGER PRIMARY KEY,
            x INTEGER,
            y INTEGER,
            nearbyNodes TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertNode(Node node) async {
    final db = await database;
    await db.insert('nodes', node.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Node>> getAllNodes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('nodes');

    List<Node> nodes = [];
    for (var map in maps) {
      Node node = Node(
        map['id'],
        [map['x'], map['y']],
      );

      List<int> nearbyIds = List<int>.from(jsonDecode(map['nearbyNodes']));
      for (int id in nearbyIds) {
        node.addNearbyNode(Node(id));
      }

      nodes.add(node);
    }
    return nodes;
  }

}

// Calculate the halfway point between two coordinates
List<double> calculateHalfwayPoint(List<int> coord1, List<int> coord2) {
  double xMid = (coord1[0] + coord2[0]) / 2;
  double yMid = (coord1[1] + coord2[1]) / 2;
  return [xMid, yMid];
}

// Find the closest node to a given point
Node findClosestNode(List<double> point, List<Node> nodes) {
  Node? closestNode;
  double minDistance = double.infinity;

  for (Node node in nodes) {
    double distance = sqrt(pow(node.xy[0] - point[0], 2) + pow(node.xy[1] - point[1], 2));
    if (distance < minDistance) {
      minDistance = distance;
      closestNode = node;
    }
  }

  return closestNode!;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load nodes from CSV file and save to database
  List<Node> nodes = await Node.loadNodesFromCSV();// comment this out after creating the DB
  final dbHelper = DatabaseHelper.instance;

  // Insert nodes into the database
  for (Node node in nodes) {
    await dbHelper.insertNode(node);
  }

  // Retrieve nodes from the database
  List<Node> storedNodes = await dbHelper.getAllNodes();

  // Example: Finding halfway point and closest node
  List<int> coord1 = [-2, -3];
  List<int> coord2 = [1, 4];

  // Step 1: Calculate the halfway point
  List<double> halfwayPoint = calculateHalfwayPoint(coord1, coord2);
  print("Halfway point: $halfwayPoint");

  // Step 2: Find the closest node to the halfway point
  Node closestNode = findClosestNode(halfwayPoint, storedNodes);
  print("Closest node to halfway point: ${closestNode.id}");
}