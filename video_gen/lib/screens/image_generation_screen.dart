import 'package:flutter/material.dart';
import 'video_generation_screen.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:video_gen/services/storage_service.dart';

class ImageGenerationScreen extends StatelessWidget {
  final List<Uint8List> imageBytesList;
  final bool loadFromStorage;

  ImageGenerationScreen({
    required this.imageBytesList,
    this.loadFromStorage = false,
  });

  Future<List<File>> _saveImages(BuildContext context) async {
    List<File> savedImages = [];
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${directory.path}/images');
      
      if (await imageDir.exists()) {
        await imageDir.delete(recursive: true);
      }
      await imageDir.create();

      List<String> imagePaths = [];
      for (int i = 0; i < imageBytesList.length; i++) {
        final filePath = '${imageDir.path}/generated_image_$i.png';
        final file = File(filePath);
        await file.writeAsBytes(imageBytesList[i]);
        savedImages.add(file);
        imagePaths.add(filePath);
        print('Image $i saved at: $filePath');
      }

      await StorageService.saveImagePaths(imagePaths);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Images saved successfully')),
      );
    } catch (e) {
      print('Error saving images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving images: $e')),
      );
    }
    return savedImages;
  }

Future<void> _navigateToVideoGeneration(BuildContext context) async {
    try {
      final savedImages = await _saveImages(context);

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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoGenerationScreen(
            images: savedImages,
            audio: latestAudioFile,
          ),
        ),
      );
    } catch (e) {
      print('Error during navigation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<List<Uint8List>> _loadSavedImages() async {
    List<Uint8List> loadedImages = [];
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${directory.path}/images');
      
      if (await imageDir.exists()) {
        final files = await imageDir.list().where((entity) => 
          entity.path.endsWith('.png')).toList();
        
        for (var file in files) {
          final bytes = await File(file.path).readAsBytes();
          loadedImages.add(bytes);
        }
      }
    } catch (e) {
      print('Error loading saved images: $e');
    }
    return loadedImages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generated Images'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Uint8List>>(
          future: loadFromStorage ? _loadSavedImages() : Future.value(imageBytesList),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            
            final images = snapshot.data ?? [];
            
            if (images.isEmpty) {
              return Center(child: Text('No images found'));
            }

            return Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    itemCount: images.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      return Image.memory(images[index]);
                    },
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => _saveImages(context),
                      child: Text('Save Images'),
                    ),
                    ElevatedButton(
                      onPressed: () => _navigateToVideoGeneration(context),
                      child: Text('Accept and Continue'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
