import 'dart:async';

import 'package:activito/models/Message.dart';
import 'package:activito/models/Place.dart';
import 'package:activito/nice_widgets/ChatWidget.dart';
import 'package:activito/models/Lobby.dart';
import 'package:activito/models/LobbySession.dart';
import 'package:activito/models/LobbyUser.dart';
import 'package:activito/models/UserLocation.dart';
import 'package:activito/nice_widgets/CustomWidgets.dart';
import 'package:activito/nice_widgets/EmptyContainer.dart';
import 'package:activito/nice_widgets/LobbyPlacesList.dart';
import 'package:activito/screens/FinalResultsScreen.dart';
import 'package:activito/services/Server.dart';
import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/countdown.dart';
import 'package:flutter_countdown_timer/current_remaining_time.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:load/load.dart';

import '../services/Globals.dart';

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
  Set<Marker> markers = {};
  GoogleMapController? mapController;

  Widget _placesList = EmptyContainer(),
      _countDownTimer = EmptyContainer(),
      _lobbyCodeWidget = EmptyContainer(),
      _stageTitle = EmptyContainer();

  @override
  void initState() {
    startListeners();
    super.initState();

    _lobbyCodeWidget = Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Container(
            child: Text(
          'code: ' + widget.lobbySession.lobby!.lobbyCode,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        )),
      ),
    );

    if (!widget.lobbySession.thisLobbyUser!.isLeader)
      _stageTitle = StageTitle(title: 'waiting for lobby the start');
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
    return WillPopScope(
      onWillPop: () => CustomDialogs.showExitConfirmationDialog(
          context: context, lobbySession: widget.lobbySession),
      child: SafeArea(
          child: Scaffold(
              body: getLobbyScreenBody(),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
              floatingActionButton: Padding(
                padding: EdgeInsets.only(bottom: 40, right: 20),
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
              ))),
    );
  }

  void startListeners() {
    widget.lobbyStream =
        Server.getLobbyEventListener(widget.lobbySession.lobby!);
    final lobbyListener = widget.lobbyStream.listen((event) {
      setState(() {
        widget.lobbySession.lobby = event.data() as Lobby;
        if (widget.lobbySession.lobby!.lobbyStage == Lobby.findingPlaces)
          _stageTitle = StageTitle(title: 'looking for places');
        if (widget.lobbySession.lobby!.lobbyStage == Lobby.votingStage) {
          startVotingStage();
        }
        if (widget.lobbySession.lobby!.lobbyStage == Lobby.finalVotesStage) {
          startFinalVotes();
        }
        if (widget.lobbySession.lobby!.lobbyStage == Lobby.finalStage) {
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => FinalResultsScreen(
                        place: widget.lobbySession.lobby!.placeRecommendations![
                            widget.lobbySession.lobby!.winningPlaceIndex!
                                .toInt()],
                        lobbySession: widget.lobbySession,
                      )));
        }
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
      addMarker(lobbyUser: lobbyUser);
    });
  }

  Widget getStartButton() {
    if (widget.lobbySession.thisLobbyUser!.isLeader &&
        widget.lobbySession.lobby!.lobbyStage == Lobby.openStage) {
      return ElevatedButton(
        onPressed: () async {
          Server.startLobby(widget.lobbySession.lobby!);
        },
        child: Text(
          "START",
          style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.08),
        ),
      );
    } else {
      return EmptyContainer();
    }
  }

  Widget? getLobbyScreenBody() {
    return Stack(
      children: [
        GoogleMap(
          zoomControlsEnabled: false,
          initialCameraPosition: CameraPosition(
              target: widget.initialCameraPosition.toLatLng(), zoom: 11),
          markers: markers,
          onMapCreated: (controller) => mapController = controller,
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.15),
            child: getStartButton(),
          ),
        ),
        _stageTitle,
        _lobbyCodeWidget,
        _placesList,
        _countDownTimer
      ],
    );
  }

  Future<void> startVotingStage() async {
    _lobbyCodeWidget = EmptyContainer();

    if (widget.lobbySession.lobby!.placeRecommendations == null) {
      await CustomDialogs.showNoPlacesFoundDialog(context, widget.lobbySession);
      Navigator.pop(context);
      return;
    }
    widget.lobbySession.lobby!.placeRecommendations!.forEach((place) {
      print("place: $place");
      addMarker(place: place);
    });

    _stageTitle = StageTitle(title: 'start voting!');

    //shows list
    _placesList = LobbyPlacesList(
        places: widget.lobbySession.lobby!.placeRecommendations!,
        mapController: mapController!,
        lobbySession: widget.lobbySession);
  }

  ///pass one of the parameters
  addMarker({Place? place, LobbyUser? lobbyUser}) {
    assert(place != null || lobbyUser != null);

    String id, title;
    LatLng latLng;
    if (place != null) {
      id = place.placeId!;
      title = place.name;
      latLng = place.location!.toLatLng();
    } else {
      id = lobbyUser!.id;
      title = lobbyUser.name;
      latLng = lobbyUser.userLocation.toLatLng();
    }

    markers.add(Marker(
        icon: lobbyUser != null
            ? BitmapDescriptor.defaultMarkerWithHue(lobbyUser.getColor())
            : BitmapDescriptor.defaultMarker,
        markerId: MarkerId(id),
        position: latLng,
        infoWindow: InfoWindow(title: title)));

    //updates camera position to include all markers
    if (markers.length == 1) return;
    List<LatLng> latLngs = [];
    markers.forEach((element) {
      latLngs.add(element.position);
    });
    mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(_boundsFromLatLngList(latLngs), 100));
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty);
    double x0, x1, y0, y1;
    x0 = x1 = list.first.latitude;
    y0 = y1 = list.first.longitude;
    for (LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }
    return LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
  }

  void startFinalVotes() {
    final votingTimeLength = 5000; //5 seconds
    (_placesList as LobbyPlacesList).animateSheetToInitialSize();
    _stageTitle = EmptyContainer();
    _countDownTimer = Align(
      alignment: Alignment.topCenter,
      child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).size.height / 8),
          child: Container(
              child: CountdownTimer(
                  endTime: widget.lobbySession.lobby!.startCountDownTime!
                          .millisecondsSinceEpoch +
                      votingTimeLength,
                  widgetBuilder: (context, remainingTime) {
                    if (remainingTime == null) return Text("timer over");
                    return StageTitle(
                        title:
                            getSecsFromRemainingTime(remainingTime).toString());
                  },
                  onEnd: countDownEnd))),
    );
  }

  void countDownEnd() {
    showLoadingDialog();
    setState(() {
      _countDownTimer = EmptyContainer();
      _placesList = EmptyContainer();
      _lobbyCodeWidget = EmptyContainer();
    });

    _stageTitle = StageTitle(title: 'counting votes');

    final vote = LobbyPlacesList.votedIndex!;
    Server.addFinalVote(widget.lobbySession.lobby!, vote);
  }

  int getSecsFromRemainingTime(CurrentRemainingTime remainingTime) {
    int secs = remainingTime.sec ?? 0;
    if (remainingTime.days != null) secs += remainingTime.days! * 24 * 60 * 60;
    if (remainingTime.hours != null) secs += remainingTime.hours! * 60 * 60;
    if (remainingTime.min != null) secs += remainingTime.min! * 60;
    return secs;
  }
}
