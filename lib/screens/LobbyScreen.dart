import 'package:activito/nice_widgets/ChatWidget.dart';
import 'package:activito/models/Lobby.dart';
import 'package:activito/models/LobbySession.dart';
import 'package:activito/models/LobbyUser.dart';
import 'package:activito/models/UserLocation.dart';
import 'package:activito/nice_widgets/EmptyContainer.dart';
import 'package:activito/services/Server.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

//TODO: check what happens if 2 markers overlap
class LobbyScreen extends StatefulWidget {
  LobbySession lobbySession;
  late Lobby lobby;
  late String thisLobbyUserId;
  late Stream<DocumentSnapshot> lobbyStream;
  late Stream<QuerySnapshot<LobbyUser>> usersStream;
  UserLocation initialCameraPosition;

  LobbyScreen(this.lobbySession, this.initialCameraPosition) {
    this.lobby = lobbySession.lobby!;
    this.thisLobbyUserId = lobbySession.thisLobbyUserId;

  }

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  Map<String, LobbyUser>? users;
  Set<Marker>? usersLocationMarkers;
  GoogleMapController? mapController;

  @override
  void initState() {
    usersLocationMarkers = {
      Marker(
          markerId: MarkerId("0"),
          position: widget.initialCameraPosition.toLatLng())
    };
    startListeners();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(body: getBody()),
    );
  }

  Widget getBody() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
              target: widget.initialCameraPosition.toLatLng(), zoom: 11),
          markers: usersLocationMarkers!,
          onMapCreated: (controller) => mapController = controller,
        ),
        Positioned(
          child: Align(
              alignment: Alignment.bottomCenter,
              child: ChatWidget(users![widget.thisLobbyUserId]!, widget.lobby)),
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

  void startListeners() {
    widget.lobbyStream = Server.getLobbyEventListener(widget.lobby);
    widget.lobbyStream.listen((event) {
      setState(() {
        widget.lobby = event.data() as Lobby;
      });
    });

    widget.usersStream = Server.getLobbyUsersEventListener(widget.lobby);
    widget.usersStream.listen((event) {
      final data = event.docs;
      setState(() {
        List<LobbyUser> values =
            List.generate(data.length, (index) => data[index].data());
        List<String> keys =
            List.generate(values.length, (index) => values[index].id);
        users = Map.fromIterables(keys, values);
        setUpUserLocationMarkers();
        print(usersLocationMarkers.toString());
      });
    });
  }

  ///should be used inside setState
  void setUpUserLocationMarkers() {
    users!.forEach((_, lobbyUser) {
      usersLocationMarkers!.add(Marker(
          markerId: MarkerId(lobbyUser.userLocation.toString()),
          position: lobbyUser.userLocation.toLatLng(),
          infoWindow: InfoWindow(title: lobbyUser.name)));
    });
  }

  Widget getStartButton() {
    if (users![widget.thisLobbyUserId]!.isLeader)
      return GestureDetector(
        child: Container(
          color: Theme.of(context).primaryColor,
          child: Text(
            "START",
            style: TextStyle(fontSize: 32),
          ),
        ),
        onTap: () {
          Fluttertoast.showToast(msg: "Start started");
        },
      );
    else
      return EmptyContainer();
  }
}
