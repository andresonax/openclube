import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

Future<FilePickerResult> pickFile() async {
  final status = await Permission.storage.request();
  if (status.isGranted) {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
      withData: true
    );

    if (result != null) {
      return result; 
    } else {
      throw Exception("No file selected");
    }
  } else {
    throw Exception("Permission denied");
  }
}