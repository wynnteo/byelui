import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Handles capturing a receipt/expense photo from the camera or gallery
/// and storing it in the app's local documents directory.
class PhotoService {
  static final ImagePicker _picker = ImagePicker();

  /// Opens the camera. Returns the saved local file path, or null if cancelled.
  static Future<String?> captureFromCamera() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (xfile == null) return null;
    return _persist(xfile);
  }

  /// Opens the gallery picker. Returns the saved local file path, or null if cancelled.
  static Future<String?> pickFromGallery() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (xfile == null) return null;
    return _persist(xfile);
  }

  static Future<String> _persist(XFile xfile) async {
    final dir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${dir.path}/receipts');
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
    final ext = xfile.path.split('.').last;
    final fileName = '${const Uuid().v4()}.$ext';
    final savedPath = '${receiptsDir.path}/$fileName';
    await File(xfile.path).copy(savedPath);
    return savedPath;
  }

  static Future<void> deletePhoto(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
