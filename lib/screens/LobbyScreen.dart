import 'dart:async';

import 'package:activito/models/Message.dart';
import 'package:activito/models/Place.dart';
import 'package:activito/nice_widgets/ChatWidget.dart';
import 'package:activito/models/Lobby.dart';
import 'package:activito/models/LobbySession.dart';
import 'package:activito/models/LobbyUser.dart';
import 'package:activito/models/UserLocation.dart';
import 'package:activito/nice_widgets/EmptyContainer.dart';
import 'package:activito/services/Server.dart';
import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

//TODO: check what happens if 2 markers overlap
class LobbyScreen extends StatefulWidget {
  LobbySession lobbySession;
  late Stream<DocumentSnapshot> lobbyStream;
  late Stream<QuerySnapshot<Message>> messagesStream;
  late Stream<QuerySnapshot<LobbyUser>> usersStream;
  List<StreamSubscription?> eventListenersList = [];
  UserLocation initialCameraPosition;
  static List<Message>? messages;
  int newMessagesIndicator = 0;

  LobbyScreen(this.lobbySession, this.initialCameraPosition);

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  Map<String, LobbyUser>? users;
  Set<Marker>? markers;
  GoogleMapController? mapController;

  Widget? _bodyWidget, _chatWidget;
  bool firstLoad = true;

  @override
  void initState() {
    markers = {
      Marker(
          markerId: MarkerId("0"),
          position: widget.initialCameraPosition.toLatLng())
    };
    startListeners();
    _chatWidget = ChatWidget(widget.lobbySession);
    super.initState();
  }

  @override
  void dispose() {
    widget.eventListenersList.forEach((element) {
      if (element != null) element.cancel();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (firstLoad) {
      _bodyWidget = getLobbyScreenBody();
      firstLoad = false;
    } else if (_bodyWidget != _chatWidget) _bodyWidget = getLobbyScreenBody();
    if (widget.lobbySession.lobby!.placeRecommendations != null &&
        widget.lobbySession.lobby!.placeRecommendations!.isNotEmpty &&
        widget.lobbySession.lobby!.isStarted) {
      setState(() {
        showPlaceSelection();
      });
    }
    return SafeArea(
        child: Scaffold(
            body: _bodyWidget,
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            floatingActionButton: Padding(
              padding: EdgeInsets.only(bottom: 30, right: 20),
              child: Badge(
                showBadge: widget.newMessagesIndicator > 0,
                badgeContent: Text(widget.newMessagesIndicator.toString(),
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ChatWidget(widget.lobbySession)));
                    setState(() {
                      widget.newMessagesIndicator = 0;
                    });
                  },
                  child: Icon(
                    Icons.chat,
                  ),
                ),
              ),
            )));
  }

  void startListeners() {
    widget.lobbyStream =
        Server.getLobbyEventListener(widget.lobbySession.lobby!);
    final lobbyListener = widget.lobbyStream.listen((event) {
      setState(() {
        widget.lobbySession.lobby = event.data() as Lobby;
      });
    });

    widget.messagesStream =
        Server.getLobbyMessagesEventListener(widget.lobbySession.lobby!);
    final messagesListener = widget.messagesStream.listen((event) {
      final data = event.docs;
      setState(() {
        final newMessagesList =
            List.generate(data.length, (index) => data[index].data());
        if (LobbyScreen.messages == null)
          widget.newMessagesIndicator = newMessagesList.length;
        else
          widget.newMessagesIndicator =
              newMessagesList.length - LobbyScreen.messages!.length;

        print("new messages event: " + widget.newMessagesIndicator.toString());
        LobbyScreen.messages = newMessagesList;
      });
    });

    widget.usersStream =
        Server.getLobbyUsersEventListener(widget.lobbySession.lobby!);
    final usersListener = widget.usersStream.listen((event) {
      final data = event.docs;
      setState(() {
        List<LobbyUser> values =
            List.generate(data.length, (index) => data[index].data());
        List<String> keys =
            List.generate(values.length, (index) => values[index].id);
        users = Map.fromIterables(keys, values);
        setUpUserLocationMarkers();
        print(markers.toString());
      });
    });

    widget.eventListenersList.add(messagesListener);
    widget.eventListenersList.add(lobbyListener);
    widget.eventListenersList.add(usersListener);
  }

  ///should be used inside setState
  void setUpUserLocationMarkers() {
    users!.forEach((_, lobbyUser) {
      markers!.clear();
      markers!.add(Marker(
          markerId: MarkerId(lobbyUser.userLocation.toString()),
          position: lobbyUser.userLocation.toLatLng(),
          infoWindow: InfoWindow(title: lobbyUser.name)));
    });
  }

  Widget getStartButton() {
    if (widget.lobbySession.thisLobbyUser!.isLeader)
      return GestureDetector(
        child: Container(
          color: Theme.of(context).primaryColor,
          child: Text(
            "START",
            style: TextStyle(fontSize: 32),
          ),
        ),
        onTap: () async {
          Fluttertoast.showToast(msg: "Start started");
          Server.startLobby(widget.lobbySession.lobby!);
        },
      );
    else
      return EmptyContainer();
  }

  Widget? getLobbyScreenBody() {
    return Stack(
      children: [
        GoogleMap(
          zoomControlsEnabled: false,
          initialCameraPosition: CameraPosition(
              target: widget.initialCameraPosition.toLatLng(), zoom: 11),
          markers: markers!,
          onMapCreated: (controller) => mapController = controller,
        ),
        Positioned(
            child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).size.height / 8),
            child: getStartButton(),
          ),
        ))
      ],
    );
  }

  void showPlaceSelection() {
    widget.lobbySession.lobby!.placeRecommendations!
        .forEach((placeType, place) {
      print("placeType: $placeType\nplace: $place");
      if (placeType == "cheapest") {
        //TODO: add icon
        markers!.add(Marker(
            position: place.location!.toLatLng(),
            markerId: MarkerId(Uuid().v4()),
            onTap: () => showPlaceDialog(place, placeType)));
      }
      print(markers!.last);
    });
  }

  ///returns true if place selected
  bool showPlaceDialog(Place place, String placeType) {
    String titleText = '';
    Color backgroundColor = Colors.white;
    if (placeType == 'cheapest') {
      titleText = 'The Cheapest: ' + place.name;
      backgroundColor = Colors.green.shade200;
    }
    if (placeType == 'bestRating') {
      titleText = 'Best Rating: ' + place.name;
      backgroundColor = Colors.yellow.shade200;
    }

    showGeneralDialog(
        context: context,
        pageBuilder: (context, _, __) {
          return Center(
              child: Card(
                  child: Stack(
            children: [
              Align(
                child: ListTile(
                  title: Text(titleText),
                  subtitle: Row(
                    children: [
                      Icon(Icons.star),
                      Text(place.rating.toString() +
                          place.userRatingTotal.toString()),
                    ],
                  ),
                ),
                alignment: Alignment.topLeft,
              )
            ],
          )));
        });
    return true;
  }
}
