import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomWidgets {
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
}
