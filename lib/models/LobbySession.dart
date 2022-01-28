import 'Lobby.dart';
import 'LobbyUser.dart';

class LobbySession {
  Lobby? lobby;
  LobbyUser? thisLobbyUser;

  LobbySession(this.lobby);

  LobbySession.isNull() {
    lobby = null;
  }

  setLobbyUser(LobbyUser lobbyUser) {
    this.thisLobbyUser = lobbyUser;
  }
}
