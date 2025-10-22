import 'package:chat_app/src/core/notifications/noti_service.dart';
import 'package:chat_app/src/features/chat/presentation/chat_provider.dart';
import 'package:chat_app/src/features/home/pages/home_page.dart';
import 'package:chat_app/src/features/authentication/sign_up_page.dart';
import 'package:chat_app/src/features/authentication/signup_and_login_provider.dart';
import 'package:chat_app/src/features/home/presentation/home_page_provider.dart';
import 'package:chat_app/src/features/home/presentation/profile_update_page_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  // FirebaseMessaging.onBackgroundMessage(backgroundHandler);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => SignupAndLoginProvider()),
      ChangeNotifierProvider(create: (context) => ChatProvider()),
      ChangeNotifierProvider(create: (context) => HomePageProvider()),
      ChangeNotifierProvider(create: (context) => ProfileUpdatePageProvider())
    ],
    child: MyApp(),
  ));
}

// Future backgroundHandler(RemoteMessage message) async {}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    pushNotificationsService.initialise();
    FirebaseMessaging.instance.getInitialMessage().then((message) {});

    // To initialise when app is not terminated
    FirebaseMessaging.onMessage.listen((message) {
      if (message.notification != null) {
        pushNotificationsService.display(message);
      }
    });

    // To handle when app is open in
    // user divide and heshe is using it
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("on message opened app");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            if (snapshot.data != null) {
              return const HomePage();
            } else {
              return const SignUpPage();
            }
          },
        ));
  }
}
