import 'package:flutter/material.dart';
import 'screens/text_generation_screen.dart';
import 'screens/saved_content_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Content Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TextGenerationScreen(),
      routes: {
        '/saved_content': (context) => SavedContentScreen(),
      },
    );
  }
}
