import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.cyanAccent, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: Text(FlutterI18n.translate(context, "settings.title")),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(FlutterI18n.translate(context, "settings.language")),
            SizedBox(width: 15), // Ensure this key exists
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    FlutterI18n.refresh(context, Locale('en'));
                    setState(() {});  // Force the page to rebuild to reflect language change
                  },
                  child: Text(FlutterI18n.translate(context, "settings.languages.english")),
                ),
                SizedBox(width: 15),
                ElevatedButton(
                  onPressed: () {
                    FlutterI18n.refresh(context, Locale('ru'));
                    setState(() {});  // Force the page to rebuild to reflect language change
                  },
                  child: Text(FlutterI18n.translate(context, "settings.languages.russian")),
                ),
                SizedBox(width: 15),
                ElevatedButton(
                  onPressed: () {
                    FlutterI18n.refresh(context, Locale('hi'));
                    setState(() {});  // Force the page to rebuild to reflect language change
                  },
                  child: Text(FlutterI18n.translate(context, "settings.languages.hindi")),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
