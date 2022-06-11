import 'package:activito/models/LobbySession.dart';
import 'package:activito/nice_widgets/EmptyContainer.dart';
import 'package:activito/services/Server.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/Place.dart';
import 'CustomWidgets.dart';

class LobbyPlacesList extends StatefulWidget {
  static String? selectedTile; //name of the place
  static int? votedIndex; //name of the place
  final List<Place> places;
  final GoogleMapController mapController;
  final LobbySession lobbySession;
  final DraggableScrollableController sheetController =
      DraggableScrollableController();

  LobbyPlacesList({
    required this.places,
    required this.mapController,
    required this.lobbySession,
  });

  @override
  _LobbyPlacesListState createState() => _LobbyPlacesListState();

  void animateSheetToInitialSize() {
    sheetController.animateTo(0.35,
        duration: Duration(milliseconds: 500), curve: Curves.linear);
  }
}

class _LobbyPlacesListState extends State<LobbyPlacesList> {

  @override
  Widget build(BuildContext context) {
    List<Widget> placesListTiles = [];
    widget.places.forEach((place) {
      placesListTiles.add(PlaceListTile(
          place,
          this,
          place.name == LobbyPlacesList.selectedTile,
          widget.mapController,
          this.widget.lobbySession));
    });
    return NotificationListener<DraggableScrollableNotification>(
        child: DraggableScrollableSheet(
            controller: widget.sheetController,
            initialChildSize: 0.35,
            maxChildSize: 0.8,
            minChildSize: 0.1,
            builder: (context, scrollController) {
              return Container(
                color: Colors.white,
                child: ListView(
                  controller: scrollController,
                  children: placesListTiles,
                ),
              );
            }));
  }
}

class PlaceListTile extends StatefulWidget {
  late final String id;
  final Place place;
  bool isSelected;
  final State parentState;
  final GoogleMapController mapController;
  final LobbySession lobbySession;

  PlaceListTile(this.place, this.parentState, this.isSelected,
      this.mapController, this.lobbySession) {
    this.id = place.name;
  }

  @override
  _PlaceListTileState createState() => _PlaceListTileState();
}

class _PlaceListTileState extends State<PlaceListTile> {

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.isSelected
          ? Theme.of(context).primaryColor.withAlpha(25)
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: IconButton(
              onPressed: changeExpanded,
              icon: Icon(widget.isSelected
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_up),
            ),
            onTap: changeExpanded,
            isThreeLine: true,
            title: Text(widget.place.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [getRatingRow(), getPriceLevelRow()],
            ),
          ),
          ImagesRow(imageSize: 80, imagesURLs: widget.place.photos!),
          EmptySpace(height: 15),
          widget.isSelected
              ? ElevatedButton(
                  onPressed: () => placeChosen(),
                  child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: Center(
                          child: Text(
                        "choose",
                        style: TextStyle(fontSize: 18),
                      ))),
                )
              : EmptyContainer(),
          Divider()
        ],
      ),
    );
  }

  changeExpanded() => setState(() {
        widget.isSelected = !widget.isSelected;
        if (widget.isSelected)
          widget.parentState.setState(() {
            LobbyPlacesList.selectedTile = widget.place.name;
          });
        widget.mapController.animateCamera(
            CameraUpdate.newLatLng(widget.place.location!.toLatLng()));
        widget.mapController
            .showMarkerInfoWindow(MarkerId(widget.place.placeId!));
      });

  placeChosen() {
    if (LobbyPlacesList.votedIndex == null) //first pick for the user
      Server.increaseInitialVoteCounter(widget.lobbySession.lobby!);
    LobbyPlacesList.votedIndex = widget
        .lobbySession.lobby!.placeRecommendations!
        .indexWhere((element) => widget.place.name == element.name);
  }

  Widget getRatingRow() {
    return widget.place.rating != null
        ? RatingRow(
            alignment: MainAxisAlignment.start,
            rating: widget.place.rating!,
            userRatingsTotal: widget.place.userRatingsTotal)
        : EmptyContainer();
  }

  getPriceLevelRow() {
    return widget.place.priceLevel != null
        ? PriceLevelRow(widget.place.priceLevel!)
        : EmptyContainer();
  }
}
