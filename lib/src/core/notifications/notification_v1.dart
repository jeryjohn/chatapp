import 'package:googleapis_auth/auth_io.dart' as auth;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:developer' as devtools show log;

Future<bool> sendPushMessage({
  required String recipientToken,
  required String title,
  required String body,
  required String type,
}) async {
  print(recipientToken);
  final jsonCredentials = await rootBundle.loadString('assets/data/data_key_cloud_console.json');
  final creds = auth.ServiceAccountCredentials.fromJson(jsonCredentials);

  final client = await auth.clientViaServiceAccount(
    creds,
    ['https://www.googleapis.com/auth/cloud-platform'],
  );

  final notificationData = {
    "message": {
      "token": recipientToken,
      "notification": {"title": title, "body": body},
      "data": {
        "title": title,
        "body": body,
        "type": type,
      }
    }
  };

  const String senderId = '900432906653';
  final response = await client.post(
    Uri.parse('https://fcm.googleapis.com/v1/projects/$senderId/messages:send'),
    headers: {
      'content-type': 'application/json',
    },
    body: jsonEncode(notificationData),
  );

  client.close();
  if (response.statusCode == 200) {
    return true; // Success!
  }

  devtools.log('Notification Sending Error Response status: ${response.statusCode}');
  devtools.log('Notification Response body: ${response.body}');
  return false;
}
