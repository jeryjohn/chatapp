import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:chat_app/src/features/chat/presentation/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class ReceiveMessageCard extends StatefulWidget {
  final String message;
  final String time;
  const ReceiveMessageCard({super.key, required this.message, required this.time});

  @override
  State<ReceiveMessageCard> createState() => _ReceiveMessageCardState();
}

class _ReceiveMessageCardState extends State<ReceiveMessageCard> {
  late PlayerController playerController;

  final player = AudioPlayer();
  var isPlaying = false;

  Future<String> downloadFromFirebase(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } else {
      throw Exception("Failed to download audio: ${response.statusCode}");
    }
  }

  @override
  void initState() {
    super.initState();
    playerController = PlayerController();
    _preparePlayer();

    playerController.onCompletion.listen((_) async {
      if (isPlaying) {
        await playerController.stopPlayer();
        await _preparePlayer();
        setState(() {
          isPlaying = false;
        });
      }
    });
  }

  Future<void> _preparePlayer() async {
    String path = widget.message;
    if (path.endsWith("m4a")) {
      path = await downloadFromFirebase(path);
      print(path);

      await playerController.preparePlayer(path: path, noOfSamples: 60, shouldExtractWaveform: true);
    } else {
      print(widget.message);
    }
  }

  Future<void> togglePlay() async {
    if (isPlaying) {
      await playerController.pausePlayer();
      setState(() {
        isPlaying = false;
      });
    } else {
      await playerController.startPlayer();
      setState(() {
        isPlaying = true;
      });
    }
  }

  @override
  void dispose() {
    playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final bool isMessage = widget.message.startsWith("http");
    final bool isAudio = widget.message.endsWith("m4a");
    return Align(
      alignment: Alignment.bottomLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.white)),
              borderOnForeground: true,
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isAudio
                        ? Row(
                            children: [
                              AudioFileWaveforms(size: Size(180, 70), playerController: playerController),
                              Card(
                                child: IconButton(
                                    onPressed: () async {
                                      togglePlay();
                                    },
                                    icon: isPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow)),
                              )
                            ],
                          )
                        : isMessage
                            ? Stack(children: [
                                Image.network(widget.message),
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: IconButton(
                                    onPressed: () async {
                                      await provider.downloadFile(context, widget.message);
                                    },
                                    icon: const Icon(
                                      Icons.download,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                )
                              ])
                            : Text(widget.message),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      widget.time,
                      style: const TextStyle(fontSize: 11),
                    )
                  ],
                ),
              )),
        ),
      ),
    );
  }
}
