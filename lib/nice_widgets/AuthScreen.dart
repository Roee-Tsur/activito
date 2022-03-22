import 'package:activito/nice_widgets/CustomWidgets.dart';
import 'package:activito/nice_widgets/EmptyContainer.dart';
import 'package:activito/services/Globals.dart';
import 'package:flutter/material.dart';

import '../screens/AuthScreens/SignUpScreen.dart';
import '../services/AuthService.dart';

class AuthScreen extends StatefulWidget {
  bool isLogin;
  String actionName = 'sign up';

  ///login = true || signup = false
  Function facebookAction, googleAction, emailAction;

  Widget? emailWidget;
  final emailFormKey = GlobalKey<FormState>();
  final emailFieldKey = GlobalKey<FormFieldState>();
  final emailFieldController = TextEditingController();
  final passwordFieldController = TextEditingController();

  AuthScreen(
      {required this.isLogin,
      required this.emailAction,
      required this.facebookAction,
      required this.googleAction}) {
    if (isLogin) this.actionName = "login";
  }

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  void initState() {
    widget.emailWidget = getInitialEmailButton();
    super.initState();
  }

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              widget.emailWidget ??= getInitialEmailButton(),
              EmptySpace(height: 12),
              ActivitoButtonContainer(
                child: TextButton(
                    onPressed: () => widget.googleAction(),
                    child: Text('${widget.actionName} with google')),
              ),
              EmptySpace(height: 12),
              /*ActivitoButtonContainer(
                child: TextButton(
                    onPressed: () => widget.facebookAction(),
                    child: Text('${widget.actionName} with facebook')),
              ),
              EmptySpace(height: 12),*/
              ActivitoButtonContainer(
                  child: widget.isLogin
                      ? TextButton(
                          onPressed: () => continueToSignUp(),
                          child:
                              Text("new to ${Globals.appName}? sign up here!"),
                        )
                      : EmptyContainer())
            ],
          ),
        ),
      ),
    ));
  }

  continueToSignUp() async {
    final results = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => SignUpScreen()));
    Navigator.pop(context, results);
  }

  Widget getInitialEmailButton() => ActivitoButtonContainer(
        child: TextButton(
            onPressed: () => emailButtonPressed(),
            child: Text('${widget.actionName} with email')),
      );

  void emailButtonPressed() {
    widget.emailWidget = Form(
      key: widget.emailFormKey,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ActivitoTextFieldContainer(
          child: TextFormField(
            key: widget.emailFieldKey,
            decoration: InputDecoration(
              border: UnderlineInputBorder(),
              labelText: 'Enter your email',
            ),
            controller: widget.emailFieldController,
            validator: (value) {
              if (value == null || value.trim().isEmpty)
                return 'please enter your email';
              if (!RegExp(
                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                  .hasMatch(value)) return 'please enter a valid email';
              return null;
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 20),
        ),
        PasswordTextField(widget.passwordFieldController),
        EmptySpace(height: 12),
        ActivitoButtonContainer(
          widthRatio: 0.4,
          child: TextButton(
              onPressed: () {
                if (!widget.emailFormKey.currentState!.validate()) return;
                widget.emailAction(widget.emailFieldController.text,
                    widget.passwordFieldController.text);
              },
              child: Text(widget.actionName)),
        ),
        EmptySpace(height: 10),
        widget.isLogin
            ? ActivitoButtonContainer(
                widthRatio: 0.4,
                child: TextButton(
                    onPressed: () {
                      if (!widget.emailFieldKey.currentState!.validate())
                        return;
                      AuthService.resetPassword(
                          widget.emailFieldController.text);
                    },
                    child: Text('reset password')),
              )
            : EmptyContainer(),
        SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Divider(
              color: Theme.of(context).primaryColor.withAlpha(80),
            ))
      ]),
    );
    setState(() {});
  }
}

class PasswordTextField extends StatefulWidget {
  TextEditingController controller;

  PasswordTextField(this.controller);

  @override
  _PasswordTextFieldState createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  late bool obscurePassword;

  @override
  void initState() {
    obscurePassword = true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ActivitoTextFieldContainer(
        child: TextFormField(
      obscureText: obscurePassword,
      decoration: InputDecoration(
        suffixIcon: IconButton(
            icon:
                Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              changeObscure();
            }),
        border: UnderlineInputBorder(),
        labelText: 'Enter your password',
      ),
      controller: widget.controller,
      validator: (value) {
        if (value == null || value.trim().isEmpty)
          return 'please enter your password';
        if (value.length < 4)
          return 'password must be at least 4 characters long';
        return null;
      },
    ));
  }

  void changeObscure() {
    setState(() {
      obscurePassword = !obscurePassword;
    });
  }
}
