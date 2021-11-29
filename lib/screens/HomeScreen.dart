import 'dart:io';

import 'package:activito/models/Lobby.dart';
import 'package:activito/models/LobbySession.dart';
import 'package:activito/models/LobbyUser.dart';
import 'package:activito/models/UserLocation.dart';
import 'package:activito/screens/AuthScreens/ProfileImagePickerScreen.dart';
import 'package:activito/screens/AuthScreens/SigninScreen.dart';
import 'package:activito/screens/LobbyScreen.dart';
import 'package:activito/screens/UserLocationScreen.dart';
import 'package:activito/services/AuthService.dart';
import 'package:activito/services/CustomWidgets.dart';
import 'package:activito/services/Globals.dart';
import 'package:activito/services/Server.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

typedef VoidCallback = void Function();

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Activito'),
        leading: AuthLeadingAppBarWidget(),
      ),
      body: HomeScreenBody(),
    ));
  }
}

class HomeScreenBody extends StatelessWidget {
  final lobbyCodeController = TextEditingController();
  final userNameController = TextEditingController(
      text: AuthService.isUserConnected()
          ? AuthService.currentUser!.nickName
          : '');
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Form(
                key: formKey,
                child: TextFormField(
                  decoration: InputDecoration(hintText: "name"),
                  textAlign: TextAlign.center,
                  controller: userNameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'please enter your name';
                    return null;
                  },
                ),
              ),
            ),
            Expanded(
              child: TextField(
                decoration: InputDecoration(hintText: "lobby code"),
                textAlign: TextAlign.center,
                inputFormatters: [
                  TextInputFormatter.withFunction(
                      (oldValue, newValue) => TextEditingValue(
                            text: newValue.text.toUpperCase(),
                            selection: newValue.selection,
                          ))
                ],
                controller: lobbyCodeController,
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => actionButtonPressed(context, "join"),
                child: Text('join'),
              ),
            ),
            Expanded(
              child: Row(children: [
                HomeRowWidget(
                  buttonText: 'create lobby',
                  onPressed: () => actionButtonPressed(context, "create"),
                ),
                HomeRowWidget(
                    buttonText: 'friends', onPressed: friendsButtonPressed),
                HomeRowWidget(
                    buttonText: 'settings', onPressed: settingsButtonPressed)
              ]),
            )
          ],
        ),
      ),
    );
  }

  actionButtonPressed(BuildContext context, String action) async {
    if (!formKey.currentState!.validate()) return;
    String userName = userNameController.value.text;
    LobbySession? lobbySession;

    if (action == "join") lobbySession = await joinLobbyButtonPressed(userName);
    if (action == "create")
      lobbySession = await createLobbyButtonPressed(userName, context);

    openUserLocationScreen(context, lobbySession!);
  }

  Future<LobbySession> joinLobbyButtonPressed(String nickName) async {
    String enteredCode = lobbyCodeController.value.text;
    LobbyUser lobbyUser = LobbyUser(name: nickName);
    return await Server.joinLobby(
        enteredCode: enteredCode, lobbyUser: lobbyUser);
  }

  Future<LobbySession> createLobbyButtonPressed(
      String nickName, BuildContext context) async {
    String lobbyType = await CustomWidgets.showTwoOptionDialog(
        context: context,
        mainTitle: "What are you looking for?",
        title1: 'something to eat or drink',
        title2: "other activities",
        icon1: Icons.fastfood,
        icon2: Icons.local_activity,
        onTap1: () => Navigator.pop(context, 'food'),
        onTap2: () => Fluttertoast.showToast(msg: 'Under construction'));
    LobbyUser lobbyUser = LobbyUser(name: nickName, isLeader: true);
    return await Server.createLobby(lobbyType: lobbyType, lobbyUser: lobbyUser);
  }

  void friendsButtonPressed() {}

  void settingsButtonPressed() {}

  Future<void> openUserLocationScreen(
      BuildContext context, LobbySession lobbySession) async {
    if (await Permission.locationWhenInUse.isGranted) {
      UserLocation currentUserLocation =
          UserLocation.fromDynamic(await Location.instance.getLocation());
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  UserLocationScreen(lobbySession, currentUserLocation)));
    } else {
      await showGeneralDialog(
          context: context,
          pageBuilder: (context, _, __) {
            return Center(
                child: Card(
                    child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    "${Globals.appName} needs access to your location, the app won't work without it",textAlign: TextAlign.center,),
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('continue'))
              ],
            )));
          });
      if (await Permission.locationWhenInUse.request().isGranted) {
        UserLocation currentUserLocation = UserLocation.fromDynamic(
            await Location.instance.getLocation());
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    UserLocationScreen(lobbySession, currentUserLocation)));
      } else
        return;
    }
  }
}

class AuthLeadingAppBarWidget extends StatefulWidget {
  @override
  _AuthLeadingAppBarWidgetState createState() =>
      _AuthLeadingAppBarWidgetState();
}

class _AuthLeadingAppBarWidgetState extends State<AuthLeadingAppBarWidget> {
  late Widget leadingWidget;

  @override
  Widget build(BuildContext context) {
    determineWidget();
    return TextButton(onPressed: _onPressed, child: leadingWidget);
  }

  _onPressed() async {
    if ((leadingWidget as Text).data == "login") {
      final isUserConnected = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ));
      print(isUserConnected);
      if (isUserConnected != null) setState(() {});
    }
  }

  void determineWidget() {
    if (AuthService.isUserConnected())
      this.leadingWidget = getUserConnectedWidget();
    else
      this.leadingWidget = getLogInWidget();
  }

  Widget getUserConnectedWidget() => PopupMenuButton(
      child: FutureBuilder(
        future: Server.getCurrentUserProfilePic(),
        builder: (BuildContext context, AsyncSnapshot<Image> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CircleAvatar(
              backgroundImage: snapshot.data!.image,
            );
          } else {
            return CircleAvatar(
                backgroundImage:
                    Image.asset("assets/defaultProfilePic.jpg").image);
          }
        },
      ),
      onSelected: (String value) async {
        if (value == "logout") {
          setState(() {
            AuthService.logout();
          });
        }
        if (value == "profilePic") {
          final isProfilePicUpdated = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ProfileImagePickerScreen()));
          if (isProfilePicUpdated) setState(() {});
        }
      },
      itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              child: Text("logout"),
              value: "logout",
            ),
            PopupMenuItem(
              child: Text("choose profile pic"),
              value: "profilePic",
            )
          ]);

  Widget getLogInWidget() => this.leadingWidget = Text(
        "login",
        style: TextStyle(color: Colors.black),
      );
}

class HomeRowWidget extends StatelessWidget {
  String buttonText;
  VoidCallback onPressed;

  HomeRowWidget({required this.buttonText, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: TextButton(onPressed: onPressed, child: Text(buttonText)),
      fit: FlexFit.tight,
    );
  }
}
