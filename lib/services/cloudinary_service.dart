import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Your Cloudinary credentials based on the setup
  final String cloudName = 'dnthfbpe7'; 
  final String uploadPreset = 'restuarant_management'; 

  // Function to upload image and return the secure URL
  Future<String?> uploadImage(XFile imageFile) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      var request = http.MultipartRequest('POST', url);
      
      // readAsBytes() works perfectly for both Flutter Web and Mobile
      final bytes = await imageFile.readAsBytes();
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: imageFile.name,
        ),
      );
      
      request.fields['upload_preset'] = uploadPreset;

      var response = await request.send();
      
      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var result = json.decode(String.fromCharCodes(responseData));
        return result['secure_url']; // The direct link to the uploaded image
      } else {
        print('Cloudinary Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception during Cloudinary upload: $e');
      return null;
    }
  }
}