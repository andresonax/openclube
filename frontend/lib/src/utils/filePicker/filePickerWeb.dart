import 'package:file_picker/file_picker.dart';

Future<FilePickerResult?> pickFile() async {
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
}
