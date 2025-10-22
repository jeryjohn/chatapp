import 'dart:convert';
import 'dart:io';
// import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileUpdatePageProvider extends ChangeNotifier {
  File? _imageFile;

  String? url;
  String? audioUrl;
  final ImagePicker picker = ImagePicker();
  XFile? pickedFile;
  bool showButton = false;
  bool isRecording = false;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> pickImage() async {
    var status = await Permission.photos.request();
    var status2 = await Permission.storage.request();
    if (status.isGranted || status2.isGranted) {
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _imageFile = File(pickedFile!.path);
      } else {
        print("No image selected");
      }
      notifyListeners();
    } else {
      print("permission denied");
    }
  }

  Future<void> uploadImageToCloudinary() async {
    var apiUrl = Uri.parse("https://api.cloudinary.com/v1_1/dayhgjzd3/image/upload");

    final request = http.MultipartRequest('POST', apiUrl)
      ..fields['upload_preset'] = "imagepreset"
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        _imageFile!.path,
      ));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = jsonDecode(responseString);
      url = jsonMap["secure_url"] ?? "";
      if (url != null && url!.isNotEmpty) {
        await UpLoadImagetoDB();
      }
      print(url);
    } else {
      print("Cloudinary upload failed with status: ${response.statusCode}");
    }
    notifyListeners();
  }

  Future<void> UpLoadImagetoDB() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final query = await FirebaseFirestore.instance.collection("userDetails").where("uid", isEqualTo: currentUser.uid).limit(1).get();

    if (query.docs.isNotEmpty) {
      final docId = query.docs.first.id;
      await FirebaseFirestore.instance.collection("userDetails").doc(docId).update({
        "profileImage": url,
      });
      print("Profile image updated successfully!");
    } else {
      print("No document found for this user");
    }
  }
}
