import 'dart:async';
import 'dart:collection';

import 'package:activito/models/Lobby.dart';
import 'package:activito/models/LobbySession.dart';
import 'package:activito/models/LobbyUser.dart';
import 'package:activito/models/Message.dart';
import 'package:activito/nice_widgets/EmptyContainer.dart';
import 'package:activito/services/Server.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatWidget extends StatefulWidget {
  static double TEXT_SIZE = 8;

  static late LobbySession _lobbySession;

  ChatWidget(LobbySession _lobbySession) {
    ChatWidget._lobbySession = _lobbySession;
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
          child: ChatBodyWidget(size)),
    );
  }
}

class ChatBodyWidget extends StatefulWidget {
  Size size;
  List<Message>? messages;

  Stream<QuerySnapshot<Message>>? messagesStream;

  ChatBodyWidget(this.size);

  @override
  _ChatBodyWidgetState createState() => _ChatBodyWidgetState();
}

class _ChatBodyWidgetState extends State<ChatBodyWidget> {
  StreamSubscription? eventListener;

  @override
  void initState() {
    widget.messagesStream =
        Server.getLobbyMessagesEventListener(ChatWidget._lobbySession.lobby!);
    eventListener = widget.messagesStream!.listen((event) {
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
  void dispose() {
    eventListener!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: NeverScrollableScrollPhysics(),reverse: true,
      children: [
        Align(
            alignment: Alignment.bottomCenter,
            child: ChatTextField(widget.size, addMessage)),
        Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: getMessagesList(),
        )
      ],
    );
  }

  Widget getMessagesList() {
    if (widget.messages == null) {
      return Container(
        width: 0,
        height: 0,
      );
    }
    return ListView.builder(
        itemCount: widget.messages!.length,
        physics: AlwaysScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.only(top: 10, bottom: 10),
        itemBuilder: (context, index) {
          return MessageWidget(widget.size,
              widget.messages![widget.messages!.length - 1 - index]);
        });
  }

  void addMessage(Message message) {
    setState(() {
      if (widget.messages == null)
        widget.messages = List.generate(1, (index) => message);
      else
        widget.messages!.insert(0, message);
    });
  }
}

class MessageWidget extends StatelessWidget {
  final Size size;
  final Message message;

  MessageWidget(this.size, this.message);

  @override
  Widget build(BuildContext context) {
    bool isSender =
        message.sender.id == ChatWidget._lobbySession.thisLobbyUser!.id;
    return Container(
      padding: EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 10),
      child: Align(
        alignment: isSender ? Alignment.bottomRight : Alignment.bottomLeft,
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: (isSender ? Colors.blue[200] : Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              isSender
                  ? EmptyContainer()
                  : Text(
                      message.sender.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
              Text(
                message.value,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ChatTextField extends StatefulWidget {
  final Size size;
  Function addMessageUI;

  ChatTextField(this.size, this.addMessageUI);

  @override
  State<ChatTextField> createState() => ChatTextFieldState();
}

class ChatTextFieldState extends State<ChatTextField> {
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
                maxLines: null,
                keyboardType: TextInputType.multiline,
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
    Message message;
    String messageText = textEditingController.text.trim();
    if (messageText.isNotEmpty) {
      message = Server.sendMessage(
          lobby: ChatWidget._lobbySession.lobby!,
          sender: ChatWidget._lobbySession.thisLobbyUser!,
          messageValue: messageText);
      widget.addMessageUI(message);
    }
    textEditingController.clear();
  }
}
