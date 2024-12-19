import 'dart:io';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
//import 'package:video_gen/screens/video_editing_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoGenerationScreen extends StatefulWidget {
  final List<File> images;
  final File audio;

  VideoGenerationScreen({required this.images, required this.audio});

  @override
  _VideoGenerationScreenState createState() => _VideoGenerationScreenState();
}

class _VideoGenerationScreenState extends State<VideoGenerationScreen> {
  String outputVideoPath = '';
  bool isProcessing = false;
  final double fps = 24.0;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    generateVideo();
  }

Future<void> generateVideo() async {
  setState(() {
    isProcessing = true;
  });

  try {
    final directory = await getApplicationDocumentsDirectory();
    final tempPath = directory.path;

    // Create a concat file for FFmpeg
    final concatFile = File('$tempPath/concat.txt');
    StringBuffer concatContent = StringBuffer();

    // Ensure all images are included in the video
    for (var file in widget.images) {
      concatContent.writeln("file '${file.path.replaceAll("'", "\\'")}'");
      concatContent.writeln("duration 6"); // Display each image for 3 seconds
    }

    // Add the last image without a duration to mark the end of the video
    concatContent.writeln("file '${widget.images.last.path.replaceAll("'", "\\'")}'");

    // Before writing to concat.txt
    print('Concat file contents:\n$concatContent');

    // Write to concat.txt
    await concatFile.writeAsString(concatContent.toString());

    final outputPath = '$tempPath/output_video.mp4';

    // FFmpeg command for generating the video
final ffmpegCommand = '-y '
    '-f concat -safe 0 -i "$tempPath/concat.txt" '
    '-i "${widget.audio.path}" '
    '-filter_complex "zoompan=z=\'if(lte(zoom,1.5),zoom+0.002,1.0)\':d=24*6:s=1280x720,format=yuv420p" '
    '-c:v mpeg4 '
    '-pix_fmt yuv420p '
    '-c:a aac '
    '-shortest '
    '"$outputPath"';



    print('Executing FFmpeg command: $ffmpegCommand');

    final session = await FFmpegKit.execute(ffmpegCommand);
    final returnCode = await session.getReturnCode();
    final logs = await session.getLogs();

    // Print logs for debugging
    print('FFmpeg return code: $returnCode');
    print('FFmpeg logs:');
    for (var log in logs) {
      print('${log.getMessage()}');
    }

    if (ReturnCode.isSuccess(returnCode)) {
      setState(() {
        outputVideoPath = outputPath;
        isProcessing = false;
      });
      print('Video created successfully at: $outputPath');

      // Initialize video player
      _initializeVideoPlayer();
    } else {
      setState(() {
        isProcessing = false;
      });
      throw Exception('Failed to create video');
    }
  } catch (e) {
    setState(() {
      isProcessing = false;
    });
    print('Error creating video: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error creating video: $e')),
    );
  } finally {
    setState(() {
      isProcessing = false;
    });
  }
}



  void _initializeVideoPlayer() {
    if (_videoController != null) {
      _videoController!.dispose();
    }
    
    _videoController = VideoPlayerController.file(File(outputVideoPath))
      ..initialize().then((_) {
        setState(() {});
        _videoController!.play();
      });
  }

Future<void> saveToDownloads() async {
  if (await Permission.manageExternalStorage.request().isGranted) {
    try {
      final externalDir = Directory('/storage/emulated/0/Download');
      if (!externalDir.existsSync()) {
        await externalDir.create(recursive: true);
      }

      final videoFile = File(outputVideoPath);
      final destinationPath = '${externalDir.path}/output_video.mp4';

      await videoFile.copy(destinationPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video saved to Downloads!')),
      );
    } catch (e) {
      print('Error saving file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save video: $e')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Storage permission denied. Please enable it in settings.')),
    );
  }
}


  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Generated Video')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isProcessing)
            Center(child: CircularProgressIndicator())
          else if (_videoController != null && _videoController!.value.isInitialized)
            Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
                IconButton(
                  icon: Icon(
                    _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _videoController!.value.isPlaying
                          ? _videoController!.pause()
                          : _videoController!.play();
                    });
                  },
                ),
              ],
            ),
          SizedBox(height: 20),
          if (!isProcessing && outputVideoPath.isNotEmpty)
            ElevatedButton(
              onPressed: saveToDownloads,
              child: Text('Save Video to Downloads'),
            ),

            SizedBox(height: 20),
            SizedBox(height: 20),
       
            
        ],
      ),
    );
  }
}
