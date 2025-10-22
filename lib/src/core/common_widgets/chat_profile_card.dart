import 'package:flutter/material.dart';

class ChatProfileCard extends StatelessWidget {
  final String userName;
  final String lastMessage;
  final String time;
  final String imageUrl;

  const ChatProfileCard({
    super.key,
    required this.userName,
    required this.lastMessage,
    required this.time,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
        child: ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(imageUrl),
      ),
      title: Text(userName),
      subtitle: Text(lastMessage),
      trailing: Text(time.toString()),
    ));
  }
}
