class ActivitoUser {
  String id;
  String email;
  late String nickName;
//TODO: home location

  ActivitoUser(this.id, this.email);

  ActivitoUser.fromJson(Map<String, Object?> json)
      : this(json['id'] as String, json['email'] as String);

  void setNickName(String newNickName) {
    this.nickName = newNickName;
  }

  String getId() => id;

  String getNickName() => nickName;

  Map<String, Object?> toJson() => {'id': id, 'email': nickName};
}
