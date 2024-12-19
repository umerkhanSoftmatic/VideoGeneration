import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:io';
import 'package:video_gen/screens/image_generation_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioGenerationScreen extends StatefulWidget {
  final String generatedText;

  AudioGenerationScreen({required this.generatedText});

  @override
  _AudioGenerationScreenState createState() => _AudioGenerationScreenState();
}

class _AudioGenerationScreenState extends State<AudioGenerationScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isDownloadingAudio = false;
  bool _isLoadingImage = false;

Future<bool> _requestPermissions() async {
  final status = await Permission.storage.request();
  return status.isGranted;
}


Future<void> _downloadAudio() async {
  setState(() {
    _isDownloadingAudio = true;
  });

  try {
    final permissionGranted = await _requestPermissions();
    if (!permissionGranted) {
      throw Exception('Storage permission not granted');
    }
    final downloadsDirectoryPath = '/storage/emulated/0/Download';

    final downloadsDirectory = Directory(downloadsDirectoryPath);
    if (!await downloadsDirectory.exists()) {
      throw Exception('Downloads directory does not exist');
    }

    final filePath = '$downloadsDirectoryPath/generated_audio.mp3';

    await _flutterTts.synthesizeToFile(widget.generatedText, filePath);

    print('Audio saved at: $filePath');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Audio saved at $filePath')),
    );
  } catch (e) {
    print('Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    setState(() {
      _isDownloadingAudio = false;
    });
  }
}




  Future<void> _navigateToImageGeneration() async {
    setState(() {
      _isLoadingImage = true;
    });

    try {
      List<Uint8List> imageBytesList = [];
      Random random = Random();

      for (int i = 0; i < 8; i++) {
        final response = await http.post(
          Uri.parse(
              'https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-3.5-large-turbo'),
          headers: {
            'Authorization': 'Bearer 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',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'inputs': widget.generatedText,
            'parameters': {
              'seed': random.nextInt(1000000000),
            },
          }),
        );

        if (response.statusCode == 200) {
          final imageBytes = response.bodyBytes;
          imageBytesList.add(imageBytes);
        } else if (response.statusCode == 429) {
          await Future.delayed(Duration(seconds: 1));
          i--;
        } else {
          throw Exception(
              'Failed to generate image $i. HTTP status: ${response.statusCode}');
        }

        await Future.delayed(Duration(seconds: 1));
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ImageGenerationScreen(imageBytesList: imageBytesList),
        ),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoadingImage = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step 2: Audio Generation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Generated Text:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    widget.generatedText,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isDownloadingAudio ? null : _downloadAudio,
              child: _isDownloadingAudio
                  ? CircularProgressIndicator()
                  : Text('Download Audio'),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoadingImage ? null : _navigateToImageGeneration,
              child: _isLoadingImage
                  ? CircularProgressIndicator()
                  : Text('Generate Images'),
            ),
          ],
        ),
      ),
    );
  }
}


