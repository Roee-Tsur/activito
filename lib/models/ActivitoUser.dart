import 'package:activito/models/ActivitoFirestoreModel.dart';

class ActivitoUser extends ActivitoFirestoreModel {
  late String id;
  late String? photoUrl;
  //late String nickName;

  ActivitoUser(this.id, this.photoUrl);

  ActivitoUser.fromJson(Map<String, Object?> json) {
    this.id = validateJsonField(json['id']);
    this.photoUrl = validateJsonField(json['photoUrl']);
    //this.nickName = validateJsonField(json['nickName']);
  }


  Map<String, Object?> toJson() =>
      {'id': id, 'photoUrl': photoUrl, /*'nickName': nickName*/};
}
