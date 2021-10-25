import 'package:activito/models/ActivitoUser.dart';
import 'package:activito/screens/AuthScreens/ProfileImagePickerScreen.dart';
import 'package:activito/services/AuthService.dart';
import 'package:activito/services/Globals.dart';
import 'package:activito/services/Server.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'SignUpScreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        leading: BackButton(
          color: Colors.black,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              Globals.appName + '\nLogin',
              textAlign: TextAlign.center,
            ),
            TextButton(
                onPressed: loginWithEmail, child: Text('log in with email')),
            TextButton(
                onPressed: loginWithGoogle, child: Text('log in with google')),
            TextButton(
                onPressed: loginWithFacebook,
                child: Text('log in with facebook')),
            TextButton(
              onPressed: () => continueToSignUpScreen(),
              child: Text("new to ${Globals.appName}?\nsign up here!"),
            )
          ],
        ),
      ),
    ));
  }

  void loginWithEmail() {
    Fluttertoast.showToast(msg: 'under construction');
  }

  Future<void> loginWithGoogle() async {
    final userCredential = await AuthService.signInWithGoogle();
    if (userCredential == null) {
      Fluttertoast.showToast(msg: "Login failed");
      return;
    }

    final uid = AuthService.getCurrentFirebaseUserId();
    if (userCredential.additionalUserInfo!.isNewUser) {
      createUserSkipSignUp(uid, userCredential.user!.email);
      return;
    }

    login(uid);
  }

  void loginWithFacebook() {
    Fluttertoast.showToast(msg: 'under construction');
  }

  // Navigator.pop returns true to initiate homepage to setState.
  Future<void> login(String id) async {
    await AuthService.loginUser(id);
    Navigator.pop(context, true);
  }

  void createUserSkipSignUp(String id, String? email) async {
    await AuthService.createAndLoginUser(id, email!);
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => ProfileImagePickerScreen()));
  }

  continueToSignUpScreen() async {
    final results = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => SignUpScreen()));
    Navigator.pop(context, results);
  }
}
