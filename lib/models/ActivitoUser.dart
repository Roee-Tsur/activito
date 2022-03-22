import 'package:activito/models/ActivitoFirestoreModel.dart';

class ActivitoUser extends ActivitoFirestoreModel {
  late String id;
  late String? photoUrl;
  late List<String>? friends;
  //late String nickName;

  ActivitoUser(this.id, this.photoUrl);

  ActivitoUser.fromJson(Map<String, Object?> json) {
    this.id = validateJsonField(json['id']);
    this.photoUrl = validateJsonField(json['photoUrl']);
    //this.nickName = validateJsonField(json['nickName']);

    this.friends = [];
    List friendsList =
    List<String>.from(validateJsonField(json["friends"]));
    friendsList.forEach((value) {
      this.friends!.add(value);
    });
  }


  Map<String, Object?> toJson() =>
      {'id': id, 'photoUrl': photoUrl, 'friends' : friends /*'nickName': nickName*/};
}
