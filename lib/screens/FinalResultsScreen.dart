import 'package:activito/models/LobbySession.dart';
import 'package:activito/models/UserLocation.dart';
import 'package:activito/nice_widgets/CustomWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:load/load.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/Lobby.dart';
import '../models/Place.dart';
import '../services/Server.dart';

class FinalResultsScreen extends StatelessWidget {
  Place place;
  LobbySession lobbySession;

  FinalResultsScreen({required this.place, required this.lobbySession});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => endLobby(context),
                )),
            Align(
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  EmptySpace(height: MediaQuery.of(context).size.height * 0.1),
                  Text(
                    'the winning place: ${place.name}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  EmptySpace(height: 15),
                  RatingRow(
                      rating: place.rating!,
                      userRatingsTotal: place.userRatingsTotal,
                      alignment: MainAxisAlignment.center),
                  TextButton(
                      onPressed: _launchMaps, child: Text(place.address)),
                  _iconButtonsRow()
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ImagesRow(
                      imageSize: 150,
                      imagesURLs: place.photos!,
                    ),
                    EmptySpace(height: 25),
                    _map(context),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _iconButtonsRow() {
    final iconButtons = List<Widget>.empty(growable: true);
    iconButtons.add(_iconButton(
        iconData: Icons.map,
        title: "open in map",
        onTap: () {
          _launchMaps();
        }));
    if (place.website != null)
      iconButtons.add(_iconButton(
          iconData: Icons.web_asset,
          title: 'website',
          onTap: () {
            launch(place.website!);
          }));
    if (place.phoneNumber != null)
      iconButtons.add(_iconButton(
          iconData: Icons.phone,
          title: 'phone',
          onTap: () {
            launch('tel:' + place.phoneNumber!);
          }));
    iconButtons.add(_iconButton(
        iconData: Icons.share,
        title: 'share',
        onTap: () {
          FlutterShare.share(
              title: 'activito',
              text:
                  'We voted for: ${place.name}! 🍴😋\nDownload the app and have a say next time!'); //TODO: add download link
        }));
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: iconButtons);
  }

  Widget _iconButton(
      {required IconData iconData,
      required String title,
      required Function onTap}) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Flexible(
          child: IconButton(icon: Icon(iconData), onPressed: () => onTap())),
      Flexible(child: Text(title))
    ]);
  }

  Widget _map(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.25,
      child: Stack(
        children: [
          GoogleMap(
            zoomControlsEnabled: false,
            initialCameraPosition:
                CameraPosition(target: place.location!.toLatLng(), zoom: 12),
            markers: {
              Marker(
                  markerId: MarkerId('0'),
                  position: place.location!.toLatLng(),
                  infoWindow: InfoWindow(title: place.name))
            },
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6, right: 10),
            child: Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () => _launchMaps(isDirections: true),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions),
                    Padding(
                      padding: EdgeInsets.only(left: 4),
                    ),
                    Text('get directions'),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _launchMaps({bool isDirections = false}) {
    if (isDirections) {
      launch(
          "https://www.google.com/maps/dir/?api=1&destination=${place.location!.toUrlParameter()}&destination_place_id=${place.placeId}");
    } else
      launch(
          "https://www.google.com/maps/search/?api=1&query=${place.location!.toUrlParameter()}&query_place_id=${place.placeId}");
  }

  endLobby(BuildContext context) {
    Navigator.of(context).pop();
    hideLoadingDialog();
    Server.exitLobby(lobbySession);
  }
}
