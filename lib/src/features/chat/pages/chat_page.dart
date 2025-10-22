import 'dart:io';
import 'package:chat_app/src/features/chat/presentation/chat_provider.dart';
import 'package:chat_app/src/core/common_widgets/receive_message_card.dart';
import 'package:chat_app/src/core/common_widgets/sent_message_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

class ChatPage extends StatefulWidget {
  final dynamic uid;
  final dynamic recipientToken;
  final String name;
  const ChatPage({super.key, required this.name, this.uid, this.recipientToken});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool _showButton = false;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final record = AudioRecorder();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back_ios_new)),
        title: Text(widget.name),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("messages").orderBy("time", descending: true).snapshots(),
            builder: (context, snapshot) {
              final messages = snapshot.data?.docs;
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return ListView.builder(
                reverse: true,
                itemCount: messages!.length,
                itemBuilder: (context, index) {
                  final data = messages[index].data() as Map<String, dynamic>;
                  final timeStamp = messages[index]["time"] as Timestamp;
                  final dateTime = timeStamp.toDate();
                  final time = DateFormat("dd/MM/yyyy HH:mm").format(dateTime);

                  final sentUserId = messages[index]["currentUserId"];
                  final receiveuserId = messages[index]["selectedUser"];
                  if (receiveuserId == widget.uid && sentUserId == currentUserId || receiveuserId == currentUserId && sentUserId == widget.uid) {
                    final messageText = data.containsKey("usersmessage") ? data["usersmessage"] : null;
                    final imageUrl = data.containsKey("imageUrl") ? data["imageUrl"] : null;
                    final audioUrl = data.containsKey("audiourl") ? data['audiourl'] : null;
                    if (sentUserId == currentUserId) {
                      return messageText != null
                          ? SentMessageCard(
                              message: messages[index]["usersmessage"] ?? '',
                              time: time,
                            )
                          : audioUrl != null
                              ? SentMessageCard(message: audioUrl, time: time)
                              : SentMessageCard(message: imageUrl ?? "", time: time);
                    } else {
                      return messageText != null
                          ? ReceiveMessageCard(
                              message: messages[index]["usersmessage"] ?? "",
                              time: time,
                            )
                          : audioUrl != null
                              ? ReceiveMessageCard(message: audioUrl, time: time)
                              : ReceiveMessageCard(message: imageUrl ?? "", time: time);
                    }
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              );
            },
          )),
          TextField(
            onTap: () {
              setState(() {
                _showButton = true;
              });
            },
            controller: provider.messageController,
            decoration: InputDecoration(
              hintText: provider.isRecording ? "Recording" : "Message",
              prefixIcon: IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      useSafeArea: true,
                      context: context,
                      shape: const RoundedRectangleBorder(),
                      builder: (context) {
                        return SizedBox(
                          height: 130,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    GestureDetector(
                                        onTap: () async {
                                          await provider.pickImage(widget.uid);
                                          if (provider.pickedFile != null) {
                                            await showModalBottomSheet(
                                              context: context,
                                              builder: (context) {
                                                return Consumer<ChatProvider>(
                                                  builder: (context, provider, _) {
                                                    return Row(
                                                      children: [
                                                        Flexible(
                                                          child: SizedBox(
                                                            width: double.infinity,
                                                            height: 300,
                                                            child: Stack(children: [
                                                              Positioned.fill(
                                                                child: Image.file(
                                                                  File(provider.pickedFile!.path),
                                                                  fit: BoxFit.cover,
                                                                ),
                                                              ),
                                                            ]),
                                                          ),
                                                        ),
                                                        IconButton(
                                                            onPressed: () async {
                                                              await provider.uploadImageToCloudinary(widget.uid, widget.recipientToken);
                                                              Navigator.of(context).pop();
                                                            },
                                                            icon: const Icon(Icons.send))
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          }

                                          Navigator.of(context).pop();
                                        },
                                        child: const Card(child: Icon(Icons.image, size: 60))),
                                    const Text("Image")
                                  ],
                                ),
                                const SizedBox(
                                  width: 40,
                                ),
                                Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        // if (provider.fileUrl != null &&
                                        //     provider.fileUrl!.isNotEmpty) {
                                        //   showDialog(
                                        //     context: context,
                                        //     builder: (_) => AlertDialog(
                                        //       title:
                                        //           const Text("File Uploaded"),
                                        //       content: Text(
                                        //           "File uploaded successfully!"),
                                        //       actions: [
                                        //         TextButton(
                                        //           onPressed: () =>
                                        //               Navigator.of(context)
                                        //                   .pop(),
                                        //           child: const Text("OK"),
                                        //         )
                                        //       ],
                                        //     ),
                                        //   );
                                        // }

                                        Navigator.of(context).pop();
                                      },
                                      child: const Card(child: Icon(Icons.edit_document, size: 60)),
                                    ),
                                    const Text("Document")
                                  ],
                                ),
                                const SizedBox(
                                  width: 40,
                                ),
                                Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        await provider.captureImage(widget.uid, widget.recipientToken);
                                        Navigator.of(context).pop();
                                      },
                                      child: const Card(child: Icon(Icons.camera_alt_rounded, size: 60)),
                                    ),
                                    const Text("Camera")
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.attach_file_rounded)),
              border: const OutlineInputBorder(),
              suffixIcon: _showButton
                  ? GestureDetector(
                      onTap: () async {},
                      child: IconButton(
                          onPressed: () {
                            provider.UpLoadMessagestoDB(widget.uid, widget.recipientToken);
                            provider.messageController.clear();
                          },
                          icon: const Icon(Icons.send)),
                    )
                  : IconButton(
                      onPressed: () async {
                        provider.isRecording ? provider.stopRecording(context, widget.uid, widget.recipientToken) : provider.startRecording(context);
                      },
                      icon: provider.isRecording
                          ? Icon(Icons.keyboard_voice_rounded, color: Colors.green)
                          : Icon(
                              Icons.keyboard_voice_rounded,
                            )),
            ),
          )
        ],
      ),
    );
  }
}
