import 'package:activito/models/LobbySession.dart';
import 'package:activito/models/LobbyUser.dart';
import 'package:activito/models/UserLocation.dart';
import 'package:activito/screens/AuthScreens/ProfileImagePickerScreen.dart';
import 'package:activito/screens/AuthScreens/SigninScreen.dart';
import 'package:activito/screens/UserLocationScreen.dart';
import 'package:activito/nice_widgets/CustomWidgets.dart';
import 'package:activito/services/Globals.dart';
import 'package:activito/services/Server.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:load/load.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/AuthService.dart';

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
  final nameFieldKey = GlobalKey<FormFieldState>();

  LobbyUser? thisLobbyUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmptySpace(height: 20),
                ActivitoTextFieldContainer(
                  child: TextFormField(
                    key: nameFieldKey,
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Enter your name',
                    ),
                    textAlign: TextAlign.center,
                    controller: userNameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'please enter your name';
                      return null;
                    },
                  ),
                ),
                EmptySpace(height: 16),
                ActivitoTextFieldContainer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Enter lobby code',
                    ),
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      TextInputFormatter.withFunction(
                          (oldValue, newValue) => TextEditingValue(
                                text: newValue.text.toUpperCase(),
                                selection: newValue.selection,
                              ))
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'please enter a lobby code';
                      if (value.length != 6)
                        return 'the lobby code should be 6 characters long';
                      return null;
                    },
                    controller: lobbyCodeController,
                  ),
                ),
                EmptySpace(height: 40),
                ActivitoButtonContainer(
                  child: TextButton(
                    onPressed: () => actionButtonPressed(context, "join"),
                    child: Text('join'),
                  ),
                ),
                EmptySpace(height: 10),
                ActivitoButtonContainer(
                  child: TextButton(
                    child: Text('create lobby'),
                    onPressed: () => actionButtonPressed(context, "create"),
                  ),
                ),
                EmptySpace(height: 26),
                ActivitoButtonContainer(
                  child: TextButton(
                      child: Text('friends'), onPressed: friendsButtonPressed),
                ),
                EmptySpace(height: 10),
                ActivitoButtonContainer(
                  child: TextButton(
                      child: Text('settings'),
                      onPressed: settingsButtonPressed),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  actionButtonPressed(BuildContext context, String action) async {
    if (action == 'join') {
      if (!formKey.currentState!.validate()) return;
    } else if (!nameFieldKey.currentState!.validate()) return;

    String userName = userNameController.value.text;
    LobbySession? lobbySession;

    FocusScope.of(context).unfocus();

    if (action == "join") lobbySession = await joinLobbyButtonPressed(userName);
    if (action == "create")
      lobbySession = await createLobbyButtonPressed(userName, context);

    lobbySession!.setLobbyUser(thisLobbyUser!);
    openUserLocationScreen(context, lobbySession);
  }

  Future<LobbySession> joinLobbyButtonPressed(String nickName) async {
    showLoadingDialog();
    String enteredCode = lobbyCodeController.value.text;
    thisLobbyUser = LobbyUser(name: nickName);
    return await Server.joinLobby(
        enteredCode: enteredCode, lobbyUser: thisLobbyUser!);
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
    showLoadingDialog();
    thisLobbyUser = LobbyUser(name: nickName, isLeader: true);
    return await Server.createLobby(
        lobbyType: lobbyType, lobbyUser: thisLobbyUser!);
  }

  void friendsButtonPressed() {}

  void settingsButtonPressed() {}

  Future<void> openUserLocationScreen(
      BuildContext context, LobbySession lobbySession) async {
    bool isPermissionGranted = await Permission.locationWhenInUse.isGranted;
    hideLoadingDialog();
    if (isPermissionGranted) {
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
                  "${Globals.appName} needs access to your location, the app won't work without it",
                  textAlign: TextAlign.center,
                ),
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('continue'))
              ],
            )));
          });
      if (await Permission.locationWhenInUse.request().isGranted) {
        UserLocation currentUserLocation =
            UserLocation.fromDynamic(await Location.instance.getLocation());
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
  void initState() {
    AuthService.firebaseAuth.userChanges().listen((event) {
      setState(() {});
    });
    super.initState();
  }

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

  Widget getUserConnectedWidget() {
    return PopupMenuButton(
        child: CircleAvatar(
          child: CachedNetworkImage(
            imageUrl: AuthService.getCurrentUserProfilePic(),
            placeholder: (context, _) {
              return CircleAvatar(
                  backgroundImage:
                      Image.asset("assets/defaultProfilePic.jpg").image);
            },
            errorWidget: (context, __, _) {
              return CircleAvatar(
                  backgroundImage:
                      Image.asset("assets/defaultProfilePic.jpg").image);
            },
          ),
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
  }

  Widget getLogInWidget() => this.leadingWidget = Text(
        "login",
        style: TextStyle(color: Colors.black),
      );
}
