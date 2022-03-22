import 'dart:io';
import 'package:activito/nice_widgets/CustomWidgets.dart';
import 'package:activito/services/AuthService.dart';
import 'package:activito/services/Server.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class ProfileImagePickerScreen extends StatefulWidget {
  late Widget pickedPicWidget;

  ProfileImagePickerScreen() {
    this.pickedPicWidget = Icon(Icons.image, size: 50,);
  }

  @override
  State<ProfileImagePickerScreen> createState() =>
      _ProfileImagePickerScreenState();
}

class _ProfileImagePickerScreenState extends State<ProfileImagePickerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: InkWell(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,children: [
              Text(
                'click to choose profile picture',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                textAlign: TextAlign.center,
              ),EmptySpace(height: 20),
              widget.pickedPicWidget,
            ],
          ),
          onTap: pickPicPressed,
        ),
      ),
    );
  }

  Future<void> pickPicPressed() async {
    final method = await showPickMethodDialog();
    if (method == null) return;
    if (method == 2) {
      await AuthService.deleteProfilePic();
      Navigator.pop(context, true);
      return;
    }
    ImageSource imageSource;
    if (method == 0)
      imageSource = ImageSource.gallery;
    else
      imageSource = ImageSource.camera;
    XFile? pickedPic = await ImagePicker().pickImage(source: imageSource);
    File? croppedPic = await ImageCropper.cropImage(
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        sourcePath: pickedPic!.path,
        cropStyle: CropStyle.rectangle);
    setState(() {
      widget.pickedPicWidget = getPicPickedWidget(croppedPic);
    });
  }

  Widget getPicPickedWidget(File? croppedPic) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Image(
              image: Image.file(
                croppedPic!,
              ).image,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                  onPressed: cancelButtonPressed,
                  child: Text(
                    'cancel',
                    style: TextStyle(color: Colors.redAccent, fontSize: 20),
                  )),
              TextButton(
                  onPressed: () => saveButtonPressed(croppedPic),
                  child: Text(
                    'save',
                    style: TextStyle(color: Colors.green, fontSize: 20),
                  ))
            ],
          )
        ],
      );

  void cancelButtonPressed() {
    setState(() {
      widget.pickedPicWidget = Icon(Icons.image);
    });
  }

  //returns true to indicate new profilePic chosen and make HomeScreen refresh
  Future<void> saveButtonPressed(File croppedPic) async {
    await Server.setProfilePic(croppedPic);
    Navigator.pop(context, true);
  }

  /// 0 - gallery, 1 - camera, 2 - default, null- canceled dialog
  showPickMethodDialog() {
    return showGeneralDialog(
      context: context,
      transitionDuration: const Duration(milliseconds: 300),
      barrierDismissible: true,
      barrierLabel: "",
      pageBuilder: (context, _, __) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Card(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(
                    child: IconButton(
                        icon: Icon(Icons.image),
                        onPressed: () {
                          Navigator.pop(context, 0);
                        }),
                  ),
                  Flexible(child: Text("Gallery"))
                ]),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: IconButton(
                          icon: Icon(Icons.camera),
                          onPressed: () {
                            Navigator.pop(context, 1);
                          }),
                    ),
                    Flexible(child: Text("Camera"))
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: IconButton(
                          icon: Icon(Icons.cancel),
                          onPressed: () {
                            Navigator.pop(context, 2);
                          }),
                    ),
                    Flexible(child: Text("Remove"))
                  ],
                )
              ],
            ),
          ),
        );
      },
      transitionBuilder: (_, animation1, __, child) {
        return SlideTransition(
          position: Tween(
            begin: Offset(0, 1),
            end: Offset(0, 0),
          ).animate(animation1),
          child: child,
        );
      },
    );
  }
}
