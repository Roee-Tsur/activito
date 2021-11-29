import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'LobbyUser.dart';

class Message {
  late String id;
  late LobbyUser sender;
  late String value;

  ///generates ID
  Message(this.sender, this.value) {
    this.id = Uuid().v4();
  }

  Message.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sender = LobbyUser.fromJson(json['sender']);
    value = json['value'];
  }

  Map<String, Object?> toJson() =>
      {'id': id, 'sender': sender.toJson(), 'value': value};
}
