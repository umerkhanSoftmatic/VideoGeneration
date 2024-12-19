// import 'dart:async';
// import 'dart:io';

// import 'package:cross_file/src/types/interface.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:path/path.dart' as path;
// import 'package:video_editor_2/video_editor.dart';

// class VideoEditingScreen extends StatefulWidget {
//   @override
//   _VideoEditingScreenState createState() => _VideoEditingScreenState();
// }

// class _VideoEditingScreenState extends State<VideoEditingScreen> {
//   String? _videoPath;

//   @override
//   void initState() {
//     super.initState();
//     _pickLatestVideo();
//   }

//   Future<void> _pickLatestVideo() async {
//     final directory = Directory('/storage/emulated/0/Download');
//     final List<FileSystemEntity> files = directory.listSync();
//     final List<File> mp4Files = files
//         .whereType<File>()
//         .where((file) => path.extension(file.path) == '.mp4')
//         .toList();

//     if (mp4Files.isNotEmpty) {
//       mp4Files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
//       setState(() {
//         _videoPath = mp4Files.first.path;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Video Editing')),
//       body: Center(
//         child: _videoPath == null
//             ? CircularProgressIndicator()
//             : Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text('Selected Video: $_videoPath'),
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute<void>(
//                           builder: (BuildContext context) => VideoEditorScreen(filePath: _videoPath!),
//                         ),
//                       );
//                     },
//                     child: const Text('Edit Video'),
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }
// }

// //-------------------//
// //VIDEO EDITOR SCREEN//
// //-------------------//
// class VideoEditorScreen extends StatefulWidget {
//   const VideoEditorScreen({super.key, required this.filePath});

//   final String filePath;

//   @override
//   State<VideoEditorScreen> createState() => _VideoEditorScreenState();
// }

// class _VideoEditorScreenState extends State<VideoEditorScreen> {
//   late final VideoEditorController _controller;
//   final _exportingProgress = ValueNotifier<double>(0.0);
//   final _isExporting = ValueNotifier<bool>(false);
//   final double height = 60;

//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoEditorController.file(
//       File(widget.filePath) as XFile,
//       minDuration: const Duration(seconds: 1),
//       maxDuration: const Duration(seconds: 10),
//     );

//     _controller.initialize(aspectRatio: 9 / 16).then((_) {
//       if (mounted) {
//         setState(() {});
//       }
//     }).catchError((error) {
//       if (mounted) {
//         Navigator.pop(context);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _exportingProgress.dispose();
//     _isExporting.dispose();
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: _controller.initialized
//           ? SafeArea(
//               child: Stack(
//                 children: [
//                   Column(
//                     children: [
//                       _topNavBar(),
//                       Expanded(
//                         child: DefaultTabController(
//                           length: 2,
//                           child: Column(
//                             children: [
//                               Expanded(
//                                 child: TabBarView(
//                                   physics: const NeverScrollableScrollPhysics(),
//                                   children: [
//                                     //CropGridViewer(controller: _controller),
//                                     CropGridViewer.preview(controller: _controller),
//                                     CoverViewer(controller: _controller),
//                                   ],
//                                 ),
//                               ),
//                               Container(
//                                 height: 200,
//                                 margin: const EdgeInsets.only(top: 10),
//                                 child: Column(
//                                   children: [
//                                     const TabBar(
//                                       tabs: [
//                                         Tab(icon: Icon(Icons.content_cut), text: 'Trim'),
//                                         Tab(icon: Icon(Icons.video_label), text: 'Cover'),
//                                       ],
//                                     ),
//                                     Expanded(
//                                       child: TabBarView(
//                                         physics: const NeverScrollableScrollPhysics(),
//                                         children: [
//                                           _trimSlider(),
//                                           _coverSelection(),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               ValueListenableBuilder(
//                                 valueListenable: _isExporting,
//                                 builder: (_, bool export, __) => AnimatedOpacity(
//                                   opacity: export ? 1.0 : 0.0,
//                                   duration: const Duration(seconds: 1),
//                                   child: AlertDialog(
//                                     title: ValueListenableBuilder(
//                                       valueListenable: _exportingProgress,
//                                       builder: (_, double value, __) => Text(
//                                         "Exporting video ${(value * 100).ceil()}%",
//                                         style: const TextStyle(fontSize: 12),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               )
//                             ],
//                           ),
//                         ),
//                       )
//                     ],
//                   )
//                 ],
//               ),
//             )
//           : const Center(child: CircularProgressIndicator()),
//     );
//   }

//   Widget _topNavBar() {
//     return SafeArea(
//       child: Row(
//         children: [
//           IconButton(
//             onPressed: () => Navigator.of(context).pop(),
//             icon: const Icon(Icons.exit_to_app),
//             tooltip: 'Leave editor',
//           ),
//           const VerticalDivider(),
//           IconButton(
//             onPressed: () => _controller.rotate90Degrees(RotateDirection.left),
//             icon: const Icon(Icons.rotate_left),
//             tooltip: 'Rotate counterclockwise',
//           ),
//           IconButton(
//             onPressed: () => _controller.rotate90Degrees(RotateDirection.right),
//             icon: const Icon(Icons.rotate_right),
//             tooltip: 'Rotate clockwise',
//           ),
//           IconButton(
//             onPressed: () async {
//               // Open crop screen
//               await Navigator.push(
//                 context,
//                 MaterialPageRoute<void>(
//                   //builder: (context) => CropScreen(controller: _controller),
//                   builder: (context) => CropGridViewer.edit(controller: _controller),
//                 ),
//               );
//             },
//             icon: const Icon(Icons.crop),
//             tooltip: 'Open crop screen',
//           ),
//           const VerticalDivider(),
//           PopupMenuButton(
//             tooltip: 'Open export menu',
//             icon: const Icon(Icons.save),
//             itemBuilder: (context) => [
//               PopupMenuItem(
//                 onTap: () {},
//                 child: const Text('Export cover'),
//               ),
//               PopupMenuItem(
//                 onTap: () {},
//                 child: const Text('Export video'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _trimSlider() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         // Add your trim slider implementation here
//         Text("Trim Slider Placeholder"),
//       ],
//     );
//   }

//   Widget _coverSelection() {
//     return SingleChildScrollView(
//       child: Center(
//         child: Container(
//           margin: const EdgeInsets.all(15),
//           child: CoverSelection(
//             controller: _controller,
//             size: height + 10,
//             quantity: 8,
//             selectedCoverBuilder: (cover, size) {
//               return Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   cover,
//                   Icon(
//                     Icons.check_circle,
//                     color: const CoverSelectionStyle().selectedBorderColor,
//                   )
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
