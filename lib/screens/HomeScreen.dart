import 'package:activito/models/Lobby.dart';
import 'package:activito/screens/AuthScreens/ProfileImagePickerScreen.dart';
import 'package:activito/screens/AuthScreens/SigninScreen.dart';
import 'package:activito/screens/LobbyScreen.dart';
import 'package:activito/services/AuthService.dart';
import 'package:activito/services/Server.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
  final userNameController = TextEditingController();
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
    Lobby? joinedLobby;

    if (action == "join") joinedLobby = await joinLobbyButtonPressed(userName);
    if (action == "create")
      joinedLobby = await createLobbyButtonPressed(userName);

    openLobbyScreen(context, joinedLobby);
  }

  Future<Lobby?> joinLobbyButtonPressed(String userName) async {
    String enteredCode = lobbyCodeController.value.text;
    return await Server.joinLobby(enteredCode, userName);
  }

  Future<Lobby?> createLobbyButtonPressed(String userName) async {
    return await Server.createLobby(userName);
  }

  void friendsButtonPressed() {}

  void settingsButtonPressed() {}

  void openLobbyScreen(BuildContext context, Lobby? joinedLobby) {
    if (joinedLobby != null)
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => LobbyScreen(joinedLobby)));
  }
}

class AuthLeadingAppBarWidget extends StatefulWidget {
  @override
  _AuthLeadingAppBarWidgetState createState() =>
      _AuthLeadingAppBarWidgetState();
}

class _AuthLeadingAppBarWidgetState extends State<AuthLeadingAppBarWidget> {
  late Widget authLeadingAppBarWidget;

  _AuthLeadingAppBarWidgetState() {
    determineWidget();
  }

  @override
  Widget build(BuildContext context) {
    determineWidget();
    return TextButton(onPressed: _onPressed, child: authLeadingAppBarWidget);
  }

  _onPressed() async {
    if ((authLeadingAppBarWidget as Text).data == "login") {
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
    if (AuthService.currentUser == null)
      this.authLeadingAppBarWidget = getLogInWidget();
    else
      this.authLeadingAppBarWidget = getUseConnectedWidget();
  }

  Widget getUseConnectedWidget() => PopupMenuButton(
      child: FutureBuilder(
        future: Server.getCurrentUserProfilePic(),
        builder: (BuildContext context, AsyncSnapshot<Image> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final data = snapshot.data;
            if (data != null)
              return CircleAvatar(
                backgroundImage: data.image,
              );
            else
              return CircleAvatar(
                  backgroundImage:
                      Image.asset("assets/defaultProfilePic.jpg").image);
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
          final isProfilePidUpdated = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ProfileImagePickerScreen()));
          if (isProfilePidUpdated)
            setState(() {});
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

  Widget getLogInWidget() => this.authLeadingAppBarWidget = Text(
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
