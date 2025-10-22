import 'package:chat_app/src/features/home/pages/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupAndLoginProvider extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController logemailController = TextEditingController();
  final TextEditingController logpasswordController = TextEditingController();

  Future<void> uploadUserDataToDB(User user) async {
    final data = await FirebaseFirestore.instance
        .collection("userDetails")
        .add({"username": nameController.text.trim(), "usermail": emailController.text.trim(), "uid": user.uid, "profileImage": ""});

    print(data);
  }

  Future<void> createUserWithEmailAndPassword(BuildContext context) async {
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final user = userCredential.user;

      if (user != null) {
        await uploadUserDataToDB(user);
      }
      print(UserCredential);
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ));

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account created successfully")));
    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email already exist")));
      } else if (e.code == "invalid-email") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid email")));
      } else if (e.code == "weak-password") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Weak password password should be greater than 6 characters")));
      } else if (e.code == "too-many-requests") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Try again after sometimes")));
      } else if (e.code == "network-request-failed") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connect to good internet connection and try again")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unexpected error occured")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unexpected error occured")));
    }
  }

//login

  Future<void> loginWithEmailAndPassword(BuildContext context) async {
    try {
      final userCreditials = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: logemailController.text.trim(),
        password: logpasswordController.text.trim(),
      );
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ));
      print(userCreditials);
    } on FirebaseAuthException catch (e) {
      if (e.code == "invalid-email") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid email")));
      } else if (e.code == "user-not-found") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User not found")));
      } else if (e.code == "wrong-password") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wrong password")));
      } else if (e.code == "INVALID_LOGIN_CREDENTIALS" || e.code == "invalid-credential") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login creditials not matched")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unexpected error occured")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unexpected error occured")));
    }
  }
}
