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
  late Stream<DocumentSnapshot> lobbyStream;
  late Stream<QuerySnapshot<LobbyUser>> usersStream;
  UserLocation initialCameraPosition;

  LobbyScreen(this.lobbySession, this.initialCameraPosition);

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  Map<String, LobbyUser>? users;
  Set<Marker>? usersLocationMarkers;
  GoogleMapController? mapController;

  IconData _fabIcon = Icons.chat;
  Widget? _bodyWidget, _chatWidget;
  bool firstLoad = true;

  @override
  void initState() {
    usersLocationMarkers = {
      Marker(
          markerId: MarkerId("0"),
          position: widget.initialCameraPosition.toLatLng())
    };
    startListeners();
    _chatWidget = ChatWidget(widget.lobbySession);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (firstLoad) {
      _bodyWidget = getLobbyScreenBody();
      firstLoad = false;
    }
    return SafeArea(
        child: Scaffold(
            body: _bodyWidget,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endFloat,
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: FloatingActionButton(
                onPressed: () {
                  if (_fabIcon == Icons.chat) {
                    _fabIcon = Icons.map;
                    _bodyWidget = _chatWidget;
                  } else {
                    _fabIcon = Icons.chat;
                    _bodyWidget = getLobbyScreenBody();
                  }
                  setState(() {});
                },
                child: Icon(_fabIcon),
              ),
            )));
  }

  void startListeners() {
    widget.lobbyStream = Server.getLobbyEventListener(widget.lobbySession.lobby!);
    widget.lobbyStream.listen((event) {
      setState(() {
        widget.lobbySession.lobby = event.data() as Lobby;
      });
    });

    widget.usersStream = Server.getLobbyUsersEventListener(widget.lobbySession.lobby!);
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
    if (widget.lobbySession.thisLobbyUser!.isLeader)
      return GestureDetector(
        child: Container(
          color: Theme.of(context).primaryColor,
          child: Text(
            "START",
            style: TextStyle(fontSize: 32),
          ),
        ),
        onTap: () {
          Server.startLobby(widget.lobbySession.lobby!);
          Fluttertoast.showToast(msg: "Start started");
        },
      );
    else
      return EmptyContainer();
  }

  Widget? getLobbyScreenBody() {
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
}
