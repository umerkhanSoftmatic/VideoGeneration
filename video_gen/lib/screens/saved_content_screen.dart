import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:video_gen/services/storage_service.dart';
import 'package:video_gen/screens/video_generation_screen.dart';

class SavedContentScreen extends StatefulWidget {
  @override
  _SavedContentScreenState createState() => _SavedContentScreenState();
}

class _SavedContentScreenState extends State<SavedContentScreen> {
  String? audioPath;
  List<String> imagePaths = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedContent();
  }

  Future<void> _loadSavedContent() async {
    setState(() => isLoading = true);
    try {
      audioPath = await StorageService.getAudioPath();
      imagePaths = await StorageService.getImagePaths();
    } catch (e) {
      print('Error loading saved content: $e');
    }
    setState(() => isLoading = false);
  }

  void _navigateToVideoGeneration() async {
   try {
      if (await Permission.storage.request().isGranted) {
        final downloadsDirectory = Directory('/storage/emulated/0/Music');
        if (!downloadsDirectory.existsSync()) {
          throw Exception('Downloads directory not found.');
        }

        final mp3Files = downloadsDirectory
            .listSync()
            .where((file) =>
                file is File && file.path.endsWith('.mp3'))
            .toList()
            ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

        if (mp3Files.isEmpty) {
          throw Exception('No MP3 files found in Downloads folder.');
        }

        final latestAudioFile = mp3Files.first as File;

        if (imagePaths.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoGenerationScreen(
                images: imagePaths.map((path) => File(path)).toList(),
                audio: latestAudioFile,
              ),
            ),
          );
        } else {
          throw Exception('No images available for video generation.');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage permission denied.')),
        );
      }
    } catch (e) {
      print('Error during navigation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _viewConcatFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final concatFile = File('${directory.path}/concat.txt');

    if (await concatFile.exists()) {
      String contents = await concatFile.readAsString();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Concat File Contents'),
          content: SingleChildScrollView(
            child: Text(contents),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Concat file does not exist.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Content'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSavedContent,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (imagePaths.isNotEmpty) ...[
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: imagePaths.length,
                      itemBuilder: (context, index) {
                        return Image.file(
                          File(imagePaths[index]),
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ],
                
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _navigateToVideoGeneration,
                      child: Text('Generate Video'),
                    ),
                  ),
              ],
            ),
    );
  }
}
