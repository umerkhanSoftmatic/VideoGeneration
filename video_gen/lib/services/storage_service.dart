import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _audioPathKey = 'audio_path';
  static const String _imagePathsKey = 'image_paths';

  static Future<void> saveAudioPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_audioPathKey, path);
  }

  static Future<String?> getAudioPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_audioPathKey);
  }

  static Future<void> saveImagePaths(List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_imagePathsKey, paths);
  }

  static Future<List<String>> getImagePaths() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_imagePathsKey) ?? [];
  }

  static Future<void> clearPaths() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_audioPathKey);
    await prefs.remove(_imagePathsKey);
  }
}
