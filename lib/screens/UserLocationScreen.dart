import 'package:activito/models/LobbySession.dart';
import 'package:activito/models/UserLocation.dart';
import 'package:activito/screens/LobbyScreen.dart';
import 'package:activito/nice_widgets/CustomWidgets.dart';
import 'package:activito/services/Server.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class UserLocationScreen extends StatefulWidget {
  LobbySession lobbySession;
  UserLocation currentUserLocation;
  late Marker marker;

  UserLocationScreen(this.lobbySession, this.currentUserLocation);

  @override
  State<UserLocationScreen> createState() => _UserLocationScreenState();
}

class _UserLocationScreenState extends State<UserLocationScreen> {
  GoogleMapController? mapController;

  @override
  void initState() {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      showLocationOptionDialog(context).then((option) {
        if (option == 0) {
          continueToLobbyScreen(widget.currentUserLocation);
        }
      });
    });
    widget.marker = Marker(
        markerId: MarkerId('0'),
        draggable: false,
        position: widget.currentUserLocation.toLatLng());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return CustomDialogs.showExitConfirmationDialog(
          lobbySession: widget.lobbySession,
          context: context,
        );
      },
      child: SafeArea(
          child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Choose your location'),
        ),
        body: Stack(
          children: [
            GoogleMap(
              zoomControlsEnabled: false,
              initialCameraPosition: CameraPosition(
                  target: widget.currentUserLocation.toLatLng(), zoom: 11),
              onMapCreated: (mapController) =>
                  this.mapController = mapController,
              markers: {widget.marker},
              onTap: onTap,
            ),
            Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FloatingActionButton(
                    heroTag: 1,
                    onPressed: () {
                      mapController!.animateCamera(CameraUpdate.newLatLng(
                          widget.currentUserLocation.toLatLng()));
                      onTap(widget.currentUserLocation.toLatLng());
                    },
                    child: Icon(Icons.my_location),
                  ),
                ))
          ],
        ),
        floatingActionButton: Container(
          width: 80,
          height: 80,
          child: FittedBox(
            child: FloatingActionButton(
              heroTag: 2,
              child: Icon(Icons.done_outline_rounded),
              onPressed: () {
                continueToLobbyScreen(
                    UserLocation.fromDynamic(widget.marker.position));
              },
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      )),
    );
  }

  ///returns 0-"current location" or 1-"Other location"
  Future showLocationOptionDialog(BuildContext context) async =>
      await CustomDialogs.showTwoOptionDialog(
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
    widget.lobbySession.thisLobbyUser!.userLocation = userLocation;
    Navigator.pop(context);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                LobbyScreen(widget.lobbySession, userLocation)));
  }

  void onTap(LatLng argument) {
    setState(() {
      widget.marker =
          Marker(markerId: MarkerId('0'), draggable: false, position: argument);
      mapController!
          .animateCamera(CameraUpdate.newLatLng(widget.marker.position));
    });
  }
}
