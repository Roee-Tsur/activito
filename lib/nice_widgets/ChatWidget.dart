import 'dart:collection';

import 'package:activito/models/Lobby.dart';
import 'package:activito/models/LobbyUser.dart';
import 'package:activito/models/Message.dart';
import 'package:activito/services/Server.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatWidget extends StatefulWidget {
  final RATION_CHAT_HEIGHT = 4;

  static double TEXT_SIZE = 8;

  static late Lobby lobby;

  ChatWidget(Lobby _lobby) {
    ChatWidget.lobby = _lobby;
  }

  @override
  _ChatWidgetState createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        alignment: Alignment.bottomCenter,
        width: size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: MessagesListWidget(size)),
            ),
            Align(alignment: Alignment.bottomCenter, child: ChatTextField(size))
          ],
        ),
      ),
    );
  }
}

class MessagesListWidget extends StatefulWidget {
  Size size;
  List<Message>? messages;

  Stream<QuerySnapshot<Message>>? messagesStream;

  MessagesListWidget(this.size);

  @override
  _MessagesListWidgetState createState() => _MessagesListWidgetState();
}

class _MessagesListWidgetState extends State<MessagesListWidget> {
  @override
  void initState() {
    widget.messagesStream =
        Server.getLobbyMessagesEventListener(ChatWidget.lobby);
    widget.messagesStream!.listen((event) {
      final data = event.docs;
      setState(() {
        widget.messages =
            List.generate(data.length, (index) => data[index].data());
      });
      print(widget.messages);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages == null) {
      return Container(
        width: 0,
        height: 0,
      );
    }
    int length = widget.messages!.length;
    if (length > 4) length = 4;
    List<Widget> widgetsList = List.generate(
        length, (index) => MessageWidget(widget.size, widget.messages![length - 1 - index]));
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widgetsList,
      ),
    );
  }
}

class MessageWidget extends StatelessWidget {
  final RATION_MESSAGE_HEIGHT = 16;
  final Size size;
  final Message message;

  MessageWidget(this.size, this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      decoration: BoxDecoration(color: Colors.white24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Text(message.sender.name), Text(message.value, textAlign: TextAlign.start,)],
      ),
    );
  }
}

class ChatTextField extends StatefulWidget {
  final Size size;

  ChatTextField(this.size);

  @override
  State<ChatTextField> createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends State<ChatTextField> {
  TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomCenter,
      width: widget.size.width,
      constraints: BoxConstraints(minHeight: ChatWidget.TEXT_SIZE),
      child: Row(
        children: [
          SizedBox(
            width: widget.size.width * 0.75,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(hintText: "Message"),
                controller: textEditingController,
              ),
            ),
          ),
          Expanded(
              child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: FloatingActionButton(
                      child: Icon(Icons.send),
                      onPressed: sendButtonPressed,
                      elevation: 0,
                    ),
                  )))
        ],
      ),
    );
  }

  void sendButtonPressed() {
    String messageText = textEditingController.text;
    /*Server.sendMessage(
        lobby: ChatWidget.lobby,
        sender: ChatWidget.thisLobbyUser,
        messageValue: messageText);*/
  }
}
