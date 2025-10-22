import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePageProvider extends ChangeNotifier {
  DateTime? time;
  int? selectedUser;
  String? message;
  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> userDetails = [];
  List<Map<String, dynamic>> finalDetails = [];
  String? username;
  int? uid;
  dynamic recipientToken;

  HomePageProvider() {
    listenToMessages();
    listenTouSer();
  }

  Future<void> listenToMessages() async {
    FirebaseFirestore.instance.collection("messages").snapshots().listen(
      (snapshot) {
        messages = snapshot.docs.map(
          (doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              "currentUserId": data["currentUserId"],
              "selectedUser": data["selectedUser"],
              "message": data["usersmessage"] ?? data["imageUrl"] ?? data["audiourl"],
              "time": (data["time"] as Timestamp).toDate()
            };
          },
        ).toList();
        checkData();
      },
    );
  }

  Future<void> listenTouSer() async {
    FirebaseFirestore.instance.collection("userDetails").snapshots().listen(
      (snapshot) {
        userDetails = snapshot.docs.map(
          (doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {"uid": data["uid"], "recipientToken": data["fcmToken"], "username": data["username"], "profileImage": data["profileImage"]};
          },
        ).toList();
        checkData();
      },
    );
  }

  // void mergeData() {
  //   finalDetails = messages.map(
  //     (msg) {
  //       final user = userDetails.firstWhere(
  //           (u) => u["uid"].toString() == msg["selectedUser"].toString(),
  //           orElse: () => {"username": "unknown"});
  //       return {
  //         "message": msg["message"],
  //         "time": msg["time"],
  //         "username": user["username"]
  //       };
  //     },
  //   ).toList();
  //   notifyListeners();
  // }
  // Future<void> getChatInfoForHomeScreen() async {
  //   QuerySnapshot snapshot =
  //       await FirebaseFirestore.instance.collection("messages").get();
  //   messages = snapshot.docs.map((doc) {
  //     final data = doc.data() as Map<String, dynamic>;
  //     return {
  //       "currentUserId": data["currentUserId"],
  //       "selectedUser": data["selectedUser"],
  //       "message": data["usersmessage"] ?? data["imageUrl"] ?? data["audiourl"],
  //       "time": (data["time"] as Timestamp).toDate(),
  //     };
  //   }).toList();

  //   checkData();
  //   notifyListeners();
  // }

  // Future<void> getUserDetails() async {
  //   QuerySnapshot snapshot =
  //       await FirebaseFirestore.instance.collection("userDetails").get();
  //   userDetails = snapshot.docs.map((doc) {
  //     final data = doc.data() as Map<String, dynamic>;
  //     return {
  //       "username": data["username"],
  //       "uid": data["uid"],
  //       "email": data["usermail"]
  //     };
  //   }).toList();
  //   checkData();
  //   notifyListeners();
  // }

  void checkData() {
    finalDetails = [];
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    for (var user in userDetails) {
      Map<String, dynamic>? userMsg;

      final userMsgs = messages.where((msg) {
        return (msg["currentUserId"].toString() == currentUserId && msg["selectedUser"].toString() == user["uid"].toString()) ||
            (msg["currentUserId"].toString() == user["uid"].toString() &&
                msg["selectedUser"].toString() == currentUserId &&
                recipientToken == user["recipientToken"].toString());
      }).toList();

      if (userMsgs.isNotEmpty) {
        userMsgs.sort((a, b) => b["time"].compareTo(a["time"]));
        userMsg = userMsgs.first;
      }

      String finalMessage = "";
      if (userMsg != null) {
        final msg = userMsg["message"]?.toString() ?? "";
        if (msg.contains(".jpg")) {
          finalMessage = "Image";
        } else if (msg.contains(".m4a")) {
          finalMessage = "Voice";
        } else {
          finalMessage = msg;
        }
      }

      finalDetails.add({
        "uid": user["uid"],
        "email": user["email"],
        "message": finalMessage,
        "time": userMsg?["time"],
        "name": user["username"],
        "imageUrl": user["profileImage"],
        "recipientToken": user["recipientToken"],
      });
    }

    notifyListeners();
  }
}
