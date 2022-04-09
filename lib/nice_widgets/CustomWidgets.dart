import 'package:activito/main.dart';
import 'package:activito/models/LobbySession.dart';
import 'package:activito/screens/GalleryScreen.dart';
import 'package:activito/services/Server.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'EmptyContainer.dart';

class CustomDialogs {
  static Future showTwoOptionDialog(
      {required BuildContext context,
      required String mainTitle,
      bool isDismissible = true,
      required String title1,
      required String title2,
      required IconData icon1,
      required IconData icon2,
      required Function onTap1,
      required Function onTap2,
      int animationDuration = 300}) async {
    Widget foodCard = InkWell(
      child: Card(
        elevation: 8,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title1),
            Icon(
              icon1,
              size: 100,
            )
          ],
        ),
      ),
      onTap: () => onTap1(),
    );

    Widget otherCard = InkWell(
      child: Card(
        elevation: 8,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title2),
            Icon(
              icon2,
              size: 100,
            )
          ],
        ),
      ),
      onTap: () => onTap2(),
    );

    return await showGeneralDialog(
      context: context,
      transitionDuration: Duration(milliseconds: animationDuration),
      barrierDismissible: isDismissible,
      barrierLabel: "",
      pageBuilder: (context, _, __) {
        return Center(
          child: Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(mainTitle),
                Padding(padding: EdgeInsets.only(bottom: 15)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(child: foodCard),
                    Expanded(child: otherCard)
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// returns true to exit and false to stay
  static Future<bool> showExitConfirmationDialog(
      {required BuildContext context,
      required LobbySession lobbySession}) async {
    final results = await showGeneralDialog<bool>(
        context: context,
        pageBuilder: (context, _, __) {
          return Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('are you sure you want to quit the lobby?'),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          child: Text(
                            "cancel",
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                            Server.exitLobby(lobbySession);
                          },
                          child: Text(
                            "exit",
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
    return results!;
  }

  static Future<void> showNoPlacesFoundDialog(
      BuildContext context, LobbySession lobbySession) {
    return showGeneralDialog(
        context: context,
        pageBuilder: (_, __, ___) {
          return Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("we didn't find any places for you, sorry!"),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MyHomePage()));
                      },
                      child: Text(
                        "exit",
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }
}

///child should be TextFormField
class ActivitoTextFieldContainer extends StatelessWidget {
  Widget child;

  ActivitoTextFieldContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      width: MediaQuery.of(context).size.width * 0.8,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Theme.of(context).primaryColor.withAlpha(25)),
      child: child,
    );
  }
}

class ActivitoButtonContainer extends StatelessWidget {
  Widget child;
  double? widthRatio;

  ActivitoButtonContainer({required this.child, this.widthRatio});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha(60),
        borderRadius: BorderRadius.circular(14.0),
      ),
      width: MediaQuery.of(context).size.width * (widthRatio ??= 0.6),
      child: child,
    );
  }
}

class EmptySpace extends StatelessWidget {
  double height;

  EmptySpace({required this.height});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(top: height));
  }
}

class RatingRow extends StatelessWidget {
  num rating;
  num? userRatingsTotal;
  MainAxisAlignment? alignment;

  RatingRow(
      {required this.rating,
      required this.userRatingsTotal,
      this.alignment = MainAxisAlignment.start});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: alignment!, children: [
      Text(rating.toString()),
      RatingBarIndicator(
          itemBuilder: (ctx, i) => Icon(
                Icons.star,
                color: Colors.yellow.shade300,
              ),
          rating: rating.toDouble(),
          itemSize: 14),
      userRatingsTotal != null
          ? Text(' ($userRatingsTotal)')
          : EmptyContainer(),
    ]);
  }
}

class PriceLevelRow extends StatelessWidget {
  num priceLevel;

  PriceLevelRow(this.priceLevel);

  @override
  Widget build(BuildContext context) {
    return RatingBarIndicator(
      itemSize: 18,
      itemCount: priceLevel.toInt(),
      rating: priceLevel.toDouble(),
      itemBuilder: (ctx, i) => Icon(
        Icons.attach_money,
      ),
    );
  }
}

class ImagesRow extends StatefulWidget {
  double imageSize;
  List<String> imagesURLs;

  ImagesRow({required this.imageSize, required this.imagesURLs});

  @override
  State<ImagesRow> createState() => _ImagesRowState();
}

class _ImagesRowState extends State<ImagesRow> {
  @override
  Widget build(BuildContext context) {
    List<Widget> photosWidget = [];
    widget.imagesURLs.forEach((element) {
      photosWidget.add(Flexible(
        fit: FlexFit.loose,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => GalleryScreen(
                          photoUrls: widget.imagesURLs,
                          firstPage: widget.imagesURLs.indexOf(element),
                        )));
          },
          child: Container(
            padding: EdgeInsets.only(left: 6),
            height: widget.imageSize,
            width: widget.imageSize,
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              child: CachedNetworkImage(
                fit: BoxFit.fill,
                imageUrl: element,
                placeholder: (_, __) => Container(
                  color: Colors.grey.shade500,
                ),
                errorWidget: (_, __, ___) {
                  setState(() {
                    widget.imagesURLs.remove(element);
                  });
                  return EmptyContainer();
                },
              ),
            ),
          ),
        ),
      ));
    });
    photosWidget.add(Padding(
      padding: EdgeInsets.only(right: 6),
    ));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: photosWidget,
      ),
    );
  }
}

class StageTitle extends StatelessWidget {
  String title;

  StageTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.1),
        child: Text(
          title,
          style: TextStyle(
              fontSize: MediaQuery.of(context).size.height * 0.05,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
