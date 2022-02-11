import 'package:activito/models/LobbySession.dart';
import 'package:activito/models/UserLocation.dart';
import 'package:activito/screens/LobbyScreen.dart';
import 'package:activito/services/CustomWidgets.dart';
import 'package:activito/services/Server.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class UserLocationScreen extends StatefulWidget {
  LobbySession lobbySession;
  UserLocation currentUserLocation;

  UserLocationScreen(this.lobbySession, this.currentUserLocation);

  @override
  State<UserLocationScreen> createState() => _UserLocationScreenState();
}

class _UserLocationScreenState extends State<UserLocationScreen> {
  UserLocationScreenBody? body;

  @override
  void initState() {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      showLocationOptionDialog(context).then((option) {
        if (option == 0) {
          continueToLobbyScreen(widget.currentUserLocation);
        }
      });
    });
    body = UserLocationScreenBody(widget.currentUserLocation);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text('Choose your desired location'),
      ),
      body: body,
      floatingActionButton: Container(
        width: 80,
        height: 80,
        child: FittedBox(
          child: FloatingActionButton(
            child: Icon(Icons.done_outline_rounded),
            onPressed: () {
              continueToLobbyScreen(UserLocation.fromDynamic(body!.marker.position));
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    ));
  }

  ///returns 0-"current" or 1-"Other"
  Future showLocationOptionDialog(BuildContext context) async =>
      await CustomWidgets.showTwoOptionDialog(
          context: context,
          mainTitle: 'What location should we use?',
          title1: 'My current location',
          title2: 'Choose a location',
          icon1: Icons.my_location_outlined,
          icon2: Icons.edit_location,
          onTap1: () => Navigator.pop(context, 0),
          onTap2: () => Navigator.pop(context, 1));

  Future<UserLocation> getCurrentLocation() async {
    LocationData locationData = await Location.instance.getLocation();
    return UserLocation(
        latitude: locationData.latitude!, longitude: locationData.longitude!);
  }

  void continueToLobbyScreen(UserLocation userLocation) {
    Server.updateUserLocation(widget.lobbySession.lobby!,
        widget.lobbySession.thisLobbyUser!.id, userLocation);
    Navigator.pop(context);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => LobbyScreen(widget.lobbySession, userLocation)));
  }
}

class UserLocationScreenBody extends StatefulWidget {
  UserLocation currentUserLocation;
  late Marker marker;

  UserLocationScreenBody(this.currentUserLocation) {
    marker = Marker(
        markerId: MarkerId('0'),
        draggable: false,
        position: currentUserLocation.toLatLng());
  }

  @override
  _UserLocationScreenBodyState createState() => _UserLocationScreenBodyState();
}

class _UserLocationScreenBodyState extends State<UserLocationScreenBody> {
  GoogleMapController? mapController;



  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      zoomControlsEnabled: false,
      initialCameraPosition: CameraPosition(
          target: widget.currentUserLocation.toLatLng(), zoom: 11),
      onMapCreated: (mapController) => this.mapController = mapController,
      markers: {widget.marker},
      onTap: onTap,
    );
  }

  void onTap(LatLng argument) {
    //mapController!.moveCamera() center the new marker when selected
    setState(() {
      widget.marker =
          Marker(markerId: MarkerId('0'), draggable: false, position: argument);
    });
  }
}
