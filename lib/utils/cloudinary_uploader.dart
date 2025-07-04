import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

/// Utility class for uploading images to Cloudinary and saving the URL to Firestore.
class CloudinaryUploader {
  // ✅ Cloudinary config (safe to expose)
  static const String cloudName = 'drxvl7rzd';
  static const String uploadPreset = 'unsigned_album_upload'; // Your unsigned preset name

  /// Uploads a profile photo to Cloudinary and saves the `photoUrl` in Firestore
  /// under the `doctors` or `patients` collection based on the provided [role].
  static Future<String?> uploadAndSaveProfilePhoto({required String role}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ No user logged in.");
      return null;
    }

    // 📷 Step 1: Pick image from gallery
    final picker = ImagePicker();
    XFile? pickedFile;
    try {
      pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
    } catch (e) {
      print("❌ Failed to pick image: $e");
      return null;
    }
    if (pickedFile == null) {
      print("❌ No image selected.");
      return null;
    }

    final File imageFile = File(pickedFile.path);

    // Optional: Basic file type check
    final String extension = imageFile.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
      print("❌ Selected file is not a supported image type.");
      return null;
    }

    try {
      // 🌐 Step 2: Upload to Cloudinary using unsigned preset
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final imageUrl = data['secure_url'];

        // 🔥 Step 3: Save Cloudinary image URL to Firestore
        final collection = role.toLowerCase() == 'doctor' ? 'doctors' : 'patients';
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(user.uid)
            .update({'photoUrl': imageUrl});

        print('✅ Profile photo uploaded and saved.');
        return imageUrl;
      } else {
        print("❌ Cloudinary upload failed: $responseBody");
        throw Exception("Upload failed. Status code: ${response.statusCode} - $responseBody");
      }
    } catch (e) {
      print("❌ Cloudinary upload error: $e");
      return null;
    }
  }
}