import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Main_Chat.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  bool isLoggedIn = false;
  User currentUser;

  Future<void> handlsSignIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
        idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);

    UserCredential firebaseUser =
        await firebaseAuth.signInWithCredential(credential);
    User user = firebaseUser.user;
    if (user != null) {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: user.uid)
          .get();
      //print(result);
      final List<DocumentSnapshot> documents = result.documents;
      if (documents.length == 0) {
        FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          'nickname': user.displayName,
          'photoUrl': user.photoUrl,
          'id': user.uid,
          'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
          'chattingWith': null
        });

        currentUser = user;
        await prefs.setString('id', currentUser.uid);
        await prefs.setString('nickname', currentUser.displayName);
        await prefs.setString('photoUrl', currentUser.photoUrl);
      } else {
        //currentUser = user;
        await prefs.setString('id', documents[0]['id']);
        await prefs.setString('nickname', documents[0]['nickname']);
        await prefs.setString('photoUrl', documents[0]['photoUrl']);
      }
    }
    await Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
          builder: (context) => Main_Chat(
            currentUserId: user.uid,
          ),
        ));
  }

  void isSignedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    isLoggedIn = await googleSignIn.isSignedIn();

    if (isLoggedIn) {
      Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) => Main_Chat(
              currentUserId: prefs.getString('id'),
            ),
          ));
    }
  }

  @override
  void initState() {
    isSignedIn();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Login_by(
            'images/google.png', "Continue with Google", () => handlsSignIn()),
      ),
    );
  }

  Login_by(namefile, text, Function ontab) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30),
      child: RaisedButton(
        onPressed: ontab,
        textColor: Colors.white,
        color: Colors.indigo,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              '$namefile',
              height: 30,
            ),
            Text(
              text,
              style: TextStyle(fontSize: 17),
            ),
            SizedBox()
          ],
        ),
      ),
    );
  }
}
