import 'package:activito/screens/AuthScreens/ProfileImagePickerScreen.dart';
import 'package:activito/services/AuthService.dart';
import 'package:activito/services/Globals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Scaffold(body: _SignUpBody()));
  }
}

class _SignUpBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(Globals.appName + '\nSign Up', textAlign: TextAlign.center),
        Form(
            child: Column(
          children: [TextFormField()],
        )),
        TextButton(
            onPressed: signUpWithEmail, child: Text('sign up with email')),
        TextButton(
            onPressed: () => signUpWithGoogle(context),
            child: Text('sign up with google')),
        TextButton(
            onPressed: signUpWithFacebook,
            child: Text('sign up with facebook')),
      ],
    );
  }

  Future<void> signUpWithGoogle(BuildContext context) async {
    UserCredential? userCredential = await AuthService.signInWithGoogle();
    if (userCredential == null) {
      Fluttertoast.showToast(msg: "Sign Up failed");
      return;
    }

    final uid = AuthService.getCurrentFirebaseUserId();
    if (!userCredential.additionalUserInfo!.isNewUser) {
      userAlreadyExists(context, uid);
      return;
    }

    await AuthService.createAndLoginUser(uid, userCredential.user!.email);
    continueToProfilePicPickerScreen(context);
  }

  Future<void> signUpWithFacebook() async {}

  void signUpWithEmail() {}

  continueToProfilePicPickerScreen(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => ProfileImagePickerScreen()));
  }

  Future<void> userAlreadyExists(BuildContext context, String uid) async {
    await AuthService.loginUser(uid);
    Fluttertoast.showToast(msg: "user already exists");
    Navigator.pop(context, true);
  }
}
