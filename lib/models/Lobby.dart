class Lobby {
  late String lobbyCode;
  late List<String> users;

  Lobby(this.lobbyCode, this.users);

  Lobby.fromJson(Map<String, dynamic> json)
      : this(json['lobbyCode'] as String, json['users'] as List<String>);

  Map<String, Object?> toJson() => {"lobbyCode": lobbyCode, "users": users};
}
