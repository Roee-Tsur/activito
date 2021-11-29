///in firestore each Lobby has a collection of users (LobbyUser)
class Lobby {
  late String id;
  ///"food" or "other"
  late String lobbyType;
  late String lobbyCode;

  Lobby(this.lobbyCode, this.lobbyType);

  Lobby.fromJson(Map<String, dynamic> json) {
    this.id = json["id"];
    this.lobbyType = json['lobbyType'];
    this.lobbyCode = json['lobbyCode'];
  }

  Map<String, Object?> toJson() => {'id': id, "lobbyCode": lobbyCode, "lobbyType": lobbyType};
}
