import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'audio_generation_screen.dart'; 

class TextGenerationScreen extends StatefulWidget {
  @override
  _TextGenerationScreenState createState() => _TextGenerationScreenState();
}

class _TextGenerationScreenState extends State<TextGenerationScreen> {
  final TextEditingController _promptController = TextEditingController();
  String? _generatedText;
  bool _isLoading = false;

  Future<void> _onGenerateText() async {
    final prompt = _promptController.text;
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a prompt.')),
      );
      return;
    }

    // Hide the keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _generatedText = null; 
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://api-inference.huggingface.co/models/meta-llama/Llama-3.2-3B-Instruct'),
        headers: {
          'Authorization': 'Bearer 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',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': prompt,
          'parameters': {
            'max_new_tokens': 500,
            'temperature': 0.7,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extract generated text
        if (data is List && data.isNotEmpty) {
          String rawGeneratedText = data[0]['generated_text'];

          // Remove the prompt from the generated text
          String cleanedText = rawGeneratedText.replaceFirst(prompt, '').trim();

          setState(() {
            _generatedText = cleanedText;
          });
        } else {
          throw Exception('Unexpected response format: $data');
        }
      } else {
        throw Exception('Failed to generate text. ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onNext() {
    if (_generatedText != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioGenerationScreen(
              generatedText:
                  _generatedText!), // Navigate to AudioGenerationScreen
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step 1: Text Generation'),
        actions: [
          IconButton(
            icon: Icon(Icons.folder),
            onPressed: () => Navigator.pushNamed(context, '/saved_content'),
          ),
        ],
      ),
      resizeToAvoidBottomInset: true, // Adjust screen height for keyboard
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _promptController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your prompt...',
                ),
                maxLines: 2,
              ),
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _onGenerateText,
                      child: Text('Generate Text'),
                    ),
              if (_generatedText != null) ...[
                SizedBox(height: 20),
                Text(
                  'Generated Text:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: TextEditingController(text: _generatedText),
                  maxLines: 5,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (text) => _generatedText = text,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _onNext,
                  child: Text('Accept and Continue'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

