import 'dart:io';

import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/src/features/api/firebase_api.dart';
import 'package:chat_app/src/features/chat/pages/chat_page.dart';
import 'package:chat_app/src/core/common_widgets/chat_profile_card.dart';
import 'package:chat_app/src/features/authentication/log_in_page.dart';
import 'package:chat_app/src/features/home/presentation/home_page_provider.dart';
import 'package:chat_app/src/features/home/presentation/profile_update_page_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    Future.microtask(
      () {
        final provider = context.read<HomePageProvider>();
        provider.listenToMessages();
        provider.listenTouSer();
      },
    );
  }

  Future<void> _initializeFirebase() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseApi().initNotification();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HomePageProvider>(context);

    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  useSafeArea: false,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Log out"),
                      content: const Text("Are you sure you want to log out"),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Cancel")),
                        TextButton(
                            onPressed: () {
                              FirebaseAuth.instance.signOut();
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                  (Route<dynamic> route) => false);
                            },
                            child: const Text("Log out"))
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.logout_rounded)),
          title: const Text(
            "Home Page",
          ),
          centerTitle: true,
          actions: [
            GestureDetector(
                onTap: () async {
                  final updateprovider = context.read<ProfileUpdatePageProvider>();
                  await updateprovider.pickImage();

                  if (updateprovider.pickedFile != null) {
                    await showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return Consumer<ProfileUpdatePageProvider>(
                          builder: (context, updateprovider, _) {
                            return Row(
                              children: [
                                Flexible(
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 300,
                                    child: Stack(children: [
                                      Positioned.fill(
                                        child: Image.file(
                                          File(updateprovider.pickedFile!.path),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ]),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    try {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (_) => const Center(child: CircularProgressIndicator()),
                                      );

                                      await updateprovider.uploadImageToCloudinary();

                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Profile Photo uploaded successfully!")),
                                      );
                                    } catch (e) {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Upload failed: $e")),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.check, color: Colors.green),
                                )
                              ],
                            );
                          },
                        );
                      },
                    );
                  }
                },
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("userDetails")
                      .where("uid", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                      .limit(1)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(
                          "https://res.cloudinary.com/dayhgjzd3/image/upload/v1760684518/picture-profile-icon-male-icon-human-or-people-sign-and-symbol-vector_mcbpo6.jpg",
                        ),
                      );
                    }

                    final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                    final imageUrl = data["profileImage"].isNotEmpty
                        ? data["profileImage"]
                        : "https://res.cloudinary.com/dayhgjzd3/image/upload/v1760684518/picture-profile-icon-male-icon-human-or-people-sign-and-symbol-vector_mcbpo6.jpg";

                    return CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(imageUrl),
                    );
                  },
                )),
            const SizedBox(
              width: 15,
            )
          ],
        ),
        // body: FutureBuilder(
        //   future: FirebaseFirestore.instance.collection("userDetails").get(),
        //   builder: (context, snapshot) {
        //     if (snapshot.connectionState == ConnectionState.waiting) {
        //       return const Center(
        //         child: CircularProgressIndicator(),
        //       );
        //     }

        //     if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        //       return const Center(
        //         child: Text("No users found"),
        //       );
        //     }

        //     final currentUser = FirebaseAuth.instance.currentUser;

        body: provider.finalDetails.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                // itemCount: snapshot.data!.docs.length,
                // itemBuilder: (context, index) {
                //   final doc =
                //       snapshot.data!.docs[index].data() as Map<String, dynamic>;
                //   final email = doc['usermail'] ?? "No email";
                //   final name = doc['username'] ?? "Unknown";
                //   final uid = doc['uid'];
                itemCount: provider.finalDetails.length,
                itemBuilder: (context, index) {
                  final chat = provider.finalDetails[index];

                  final dateTimee = chat["time"];
                  final name = chat["name"];
                  final message = chat["message"];
                  final imageLink = chat["imageUrl"].isNotEmpty
                      ? chat["imageUrl"]
                      : "https://res.cloudinary.com/dayhgjzd3/image/upload/v1760684518/picture-profile-icon-male-icon-human-or-people-sign-and-symbol-vector_mcbpo6.jpg";
                  final email = chat["email"];
                  final uid = chat["uid"];
                  final recipientToken = chat["recipientToken"];

                  final time = dateTimee != null ? DateFormat("dd/MM/yyyy HH:mm").format(dateTimee) : "";

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            uid: uid,
                            recipientToken: recipientToken,
                            name: uid == currentUserId ? "$name (you)" : name,
                          ),
                        ),
                      );
                    },
                    child: ChatProfileCard(
                        userName: uid == currentUserId ? "$name (you)" : name, lastMessage: message ?? "", time: time, imageUrl: imageLink),
                  );
                },
              ));
  }
}
