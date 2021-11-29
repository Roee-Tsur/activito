import 'dart:io';
import 'package:activito/services/Server.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class ProfileImagePickerScreen extends StatefulWidget {
  late Widget pickedPicWidget;

  ProfileImagePickerScreen() {
    this.pickedPicWidget = Icon(Icons.image);
  }

  @override
  State<ProfileImagePickerScreen> createState() =>
      _ProfileImagePickerScreenState();
}

class _ProfileImagePickerScreenState extends State<ProfileImagePickerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InkWell(
        child: Center(
          child: Container(
            child: Column(
              children: [
                Expanded(
                  child: Text(
                    'click to choose profile picture',
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: widget.pickedPicWidget,
                ),
              ],
            ),
            alignment: Alignment.center,
            width: 150,
            height: 150,
          ),
        ),
        onTap: pickPicPressed,
      ),
    );
  }

  Future<void> pickPicPressed() async {
    final method = await showPickMethodDialog();
    if (method == null) return;
    if (method == 2) {
      await Server.deleteProfilePic();
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
        cropStyle: CropStyle.circle);
    setState(() {
      widget.pickedPicWidget = getPicPickedWidget(croppedPic);
    });
  }

  Widget getPicPickedWidget(File? croppedPic) => Column(
        children: [
          Expanded(
            child: CircleAvatar(radius: 150,
              backgroundImage: Image.file(
                croppedPic!,
              ).image,
            ),
          ),
          Expanded(
            child: Row(
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
            ),
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
