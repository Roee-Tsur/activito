import 'dart:io';
import 'package:activito/services/Server.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class ProfileImagePickerScreen extends StatefulWidget {
  late Widget pickedPicWidget;
  Widget? buttomNavigationWidget;

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
      bottomNavigationBar: widget.buttomNavigationWidget,
    );
  }

  Future<void> pickPicPressed() async {
    setState(() {
      widget.buttomNavigationWidget = getBottomNavigationWidget();
    });
    XFile? pickedPic =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    File? croppedPic = await ImageCropper.cropImage(
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        sourcePath: pickedPic!.path,
        cropStyle: CropStyle.circle);
    setState(() {
      widget.pickedPicWidget = Column(
        children: [
          Expanded(
            child: CircleAvatar(
              backgroundImage: Image.file(
                croppedPic!,
              ).image,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                TextButton(
                    onPressed: cancelButtonPressed,
                    child: Text(
                      'cancel',
                      style: TextStyle(color: Colors.redAccent),
                    )),
                TextButton(
                    onPressed: () => saveButtonPressed(croppedPic),
                    child: Text(
                      'save',
                      style: TextStyle(color: Colors.green),
                    ))
              ],
            ),
          )
        ],
      );
    });
  }

  Widget getBottomNavigationWidget() => BottomNavigationBar(items: [
        BottomNavigationBarItem(
            icon: Icon(Icons.image_search), label: "gallery"),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera_alt),
          label: "camera",
        )
      ]);

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
}
