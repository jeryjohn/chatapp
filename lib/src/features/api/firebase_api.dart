import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotification() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print("User granted permission: ${settings.authorizationStatus}");

    if (settings.authorizationStatus == AuthorizationStatus.authorized || settings.authorizationStatus == AuthorizationStatus.provisional) {
      String? token = await _firebaseMessaging.getToken();
      _updateFCMTokenToDB(token!);
      print("FCM Token: $token");
    } else {
      print("User declined or has not accepted permission");
    }
  }

  Future<void> _updateFCMTokenToDB(String token) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final query = await FirebaseFirestore.instance.collection("userDetails").where("uid", isEqualTo: currentUser.uid).limit(1).get();

    if (query.docs.isNotEmpty) {
      final docId = query.docs.first.id;
      await FirebaseFirestore.instance.collection("userDetails").doc(docId).update({"fcmToken": token});
      print(" FCM token updated successfully!");
    } else {
      print(" No document found for this user");
    }
  }
}
