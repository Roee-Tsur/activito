import 'package:activito/screens/HomeScreen.dart';
import 'package:activito/services/AuthService.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:load/load.dart';

void main() async {
  await initializeApp();
  runApp(MyApp());
}

Future<void> initializeApp() async {
  ///TODO: fix facebook login, exit galleryscreen with swipe
  ///change app name: WTD(what to do), wtg(where to go)
  ///when leader exits lobby declare new leader
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  AuthService.initUser();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Activito',
        theme: ThemeData(
          primarySwatch: Colors.purple,
        ),
        home: LoadingProvider(
          themeData: LoadingThemeData(),
          loadingWidgetBuilder: (context, themeData) {
            return SizedBox(
                height: 40,
                width: 40,
                child: Image.asset('assets/loading.gif'));
          },
          child: SafeArea(child: MyHomePage()),
        ));
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
