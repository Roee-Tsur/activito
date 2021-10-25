import 'package:activito/models/Lobby.dart';
import 'package:flutter/material.dart';

class LobbyScreen extends StatefulWidget {
  Lobby lobby;

  LobbyScreen(this.lobby);

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Text("lobby code: ${widget.lobby.lobbyCode}"),
            Text("lobby users: ${widget.lobby.users.toString()}"),
          ],
        ),
      ),
    );
  }
}
