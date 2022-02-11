import 'package:activito/screens/AuthScreens/SigninScreen.dart';
import 'package:activito/screens/HomeScreen.dart';
import 'package:activito/services/AuthService.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'services/Server.dart';

void main() async {
  await initializeApp();
  runApp(MyApp());
}

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AuthService.initUser();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activito',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: SafeArea(child: MyHomePage()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return HomeScreen();
  }
}
