import 'Lobby.dart';

class LobbySession {
  Lobby? lobby;
  String thisLobbyUserId='';

  LobbySession(this.lobby, this.thisLobbyUserId);

  LobbySession.isNull() {
    lobby = null;
  }
}