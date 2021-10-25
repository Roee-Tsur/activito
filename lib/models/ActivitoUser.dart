class ActivitoUser {
  String id;
  String email;

  ActivitoUser(this.id, this.email);

  ActivitoUser.fromJson(Map<String, Object?> json)
      : this(json['id'] as String, json['email'] as String);

  void setUserName(String newUserName) {
    this.email = newUserName;
  }

  String getId() => id;

  String getEmail() => email;

  Map<String, Object?> toJson() => {'id': id, 'email': email};
}
