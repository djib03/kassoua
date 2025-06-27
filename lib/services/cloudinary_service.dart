import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<String?> uploadImageToCloudinary(File imageFile) async {
  const cloudName = 'TON_CLOUD_NAME';
  const uploadPreset = 'TON_UPLOAD_PRESET';

  final url = Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
  );
  final request =
      http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

  final response = await request.send();
  if (response.statusCode == 200) {
    final respStr = await response.stream.bytesToString();
    final data = json.decode(respStr);
    return data['secure_url'];
  } else {
    return null;
  }
}
