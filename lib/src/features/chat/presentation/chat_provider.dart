import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
// import 'package:file_picker/file_picker.dart';
import 'package:chat_app/src/core/notifications/notification_v1.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class ChatProvider extends ChangeNotifier {
  TextEditingController messageController = TextEditingController();
  File? _imageFile;
  String? url;
  String? audioUrl;
  // String? fileUrl;
  final ImagePicker picker = ImagePicker();
  XFile? pickedFile;
  // File? _pickedFile;
  bool showButton = false;
  bool isRecording = false;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final record = AudioRecorder();

  Future<void> UpLoadMessagestoDB(dynamic uid, dynamic recipientToken) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserName = currentUser!.email.toString();
      final now = Timestamp.now();
      final selectedUserId = uid;
      final cleanedMessage = messageController.text.trim();

      if (cleanedMessage.isNotEmpty) {
        final userMessage = await FirebaseFirestore.instance
            .collection("messages")
            .add({"usersmessage": cleanedMessage, "time": now, "currentUserId": currentUser!.uid, "selectedUser": selectedUserId});
        await sendPushMessage(recipientToken: recipientToken, title: currentUserName, body: "sent you a meassage", type: "text");
        print(userMessage);
      } else {
        print("space cant be sent");
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> UpLoadImagetoDB(dynamic uid, dynamic recipientToken) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserName = currentUser!.email.toString();
      final now = Timestamp.now();
      final selectedUserId = uid;

      final imageUrl = url;
      await sendPushMessage(recipientToken: recipientToken, title: currentUserName, body: "sent you a image", type: "text");
      final userMessage = await FirebaseFirestore.instance
          .collection("messages")
          .add({"imageUrl": imageUrl, "time": now, "currentUserId": currentUser!.uid, "selectedUser": selectedUserId});

      print(userMessage);
    } catch (e) {
      print(e);
    }
  }

  Future<void> UpLoadAudiotoDB(dynamic uid, dynamic recipientToken) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserName = currentUser!.email.toString();
      final now = Timestamp.now();
      final selectedUserId = uid;

      final m4aUrl = audioUrl;

      final userMessage = await FirebaseFirestore.instance
          .collection("messages")
          .add({"audiourl": m4aUrl, "time": now, "currentUserId": currentUser!.uid, "selectedUser": selectedUserId});
      await sendPushMessage(recipientToken: recipientToken, title: currentUserName, body: "sent you a audio", type: "text");
      print(userMessage);
    } catch (e) {
      print(e);
    }
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+
      if (await Permission.photos.isGranted) return true;
      var status = await Permission.photos.request();
      if (status.isGranted) return true;

      // For Android <=12
      if (await Permission.storage.isGranted) return true;
      var status2 = await Permission.storage.request();
      return status2.isGranted;
    }
    return true; // iOS doesn't need manual permission
  }

  //image upload

  Future<void> captureImage(dynamic uid, dynamic recipientToken) async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        _imageFile = File(pickedFile!.path);
        await uploadImageToCloudinary(uid, recipientToken);
      } else {
        print("No image selected");
      }
      notifyListeners();
    } else {
      print("permission denied");
    }
  }

  Future<void> pickImage(dynamic uid) async {
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

  Future<void> uploadImageToCloudinary(dynamic uid, dynamic recipientToken) async {
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
      UpLoadImagetoDB(uid, recipientToken);
      print(url);
    }
    notifyListeners();
  }

  //download image

  Future<void> downloadFile(BuildContext context, String url) async {
    bool permissionGranted = await requestStoragePermission();
    if (!permissionGranted) throw "Permission denied";

    final dio = Dio();
    final response = await dio.get(url, options: Options(responseType: ResponseType.bytes));
    final bytes = Uint8List.fromList(response.data);

    Directory dir;
    if (Platform.isAndroid) {
      dir = Directory("/storage/emulated/0/Download/ChatApp");
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    String filePath = "${dir.path}/IMG_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("image saved to $filePath")));
    print("Saved image: $filePath");
  }

  //recording audio

  @override
  void dispose() {
    record.dispose();
    super.dispose();
  }

  Future<void> startRecording(BuildContext context) async {
    try {
      if (await record.hasPermission()) {
        final directory = Directory("/storage/emulated/0/Download/ChatApp");
        final filePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';

        await record.start(const RecordConfig(), path: filePath);

        isRecording = true;

        print('Recording started: $filePath');
      } else {
        print('Recording permission denied');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
    } catch (e) {
      print('Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $e')),
      );
    }
    notifyListeners();
  }

  Future<void> stopRecording(BuildContext context, dynamic uid, dynamic recipientToken) async {
    try {
      final path = await record.stop();
      final directory = "/storage/emulated/0/Download/ChatApp";

      isRecording = false;

      if (path != null) {
        print('Recording ${path} to ${directory}');
        var apiUrl = Uri.parse("https://api.cloudinary.com/v1_1/dayhgjzd3/video/upload");
        final request = await http.MultipartRequest("POST", apiUrl)
          ..fields["upload_preset"] = "audiopreset"
          ..files.add(await http.MultipartFile.fromPath("file", path));
        final response = await request.send();
        if (response.statusCode == 200) {
          final responseData = await response.stream.toBytes();
          final responseString = String.fromCharCodes(responseData);
          final responseJson = jsonDecode(responseString);
          final url = responseJson["secure_url"] ?? "";
          audioUrl = url.replaceAll("mp4", "m4a");
          UpLoadAudiotoDB(uid, recipientToken);
          print('uploaded to cloudinary $audioUrl');
        } else {
          print('could not upload to cloudinary');
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');

      isRecording = false;
    }
    notifyListeners();
  }

  // Future<void> pickFile(dynamic uid) async {
  //   FilePickerResult? result = await FilePicker.platform.pickFiles();
  //   if (result != null && result.files.single.path != null) {
  //     _pickedFile = File(result.files.single.path!);
  //     await uploadFileToCloudinary(uid);
  //   } else {
  //     print("No file selected");
  //   }
  //   notifyListeners();
  // }

  // Future<void> uploadFileToCloudinary(dynamic uid) async {
  //   if (_pickedFile == null) return;

  //   var apiUrl =
  //       Uri.parse("https://api.cloudinary.com/v1_1/dayhgjzd3/raw/upload");

  //   final request = http.MultipartRequest('POST', apiUrl)
  //     ..fields['upload_preset'] = "filepreset"
  //     ..files.add(await http.MultipartFile.fromPath('file', _pickedFile!.path));

  //   final response = await request.send();
  //   if (response.statusCode == 200) {
  //     final responseData = await response.stream.toBytes();
  //     final responseString = String.fromCharCodes(responseData);
  //     final jsonMap = jsonDecode(responseString);
  //     fileUrl = jsonMap["secure_url"] ?? "";
  //     await uploadFileToDB(uid);
  //     print("File uploaded: $fileUrl");
  //   } else {
  //     print("File upload failed");
  //   }
  //   notifyListeners();
  // }

  // Future<void> uploadFileToDB(dynamic uid) async {
  //   final currentUser = FirebaseAuth.instance.currentUser;
  //   final now = Timestamp.now();

  //   await FirebaseFirestore.instance.collection("messages").add({
  //     "fileUrl": fileUrl,
  //     "time": now,
  //     "currentUserId": currentUser!.uid,
  //     "selectedUser": uid
  //   });
  // }
}
