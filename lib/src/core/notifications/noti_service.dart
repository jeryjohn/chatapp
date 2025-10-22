import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class pushNotificationsService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static void initialise() {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> display(RemoteMessage message) async {
    // To display the notification in device
    try {
      print(message.notification!.android!.sound);
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      NotificationDetails notificationDetails = NotificationDetails(
        android:
            AndroidNotificationDetails(message.notification!.android!.sound ?? "Channel Id", message.notification!.android!.sound ?? "Main Channel",
                groupKey: "gfg",
                color: Colors.green,
                importance: Importance.max,
                sound: RawResourceAndroidNotificationSound(message.notification!.android!.sound ?? "gfg"),

                // different sound for
                // different notification
                playSound: true,
                priority: Priority.high),
      );
      await flutterLocalNotificationsPlugin.show(id, message.notification?.title, message.notification?.body, notificationDetails,
          payload: message.data['route']);
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
