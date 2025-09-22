import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';


Future<FilePickerResult> pickFile() async {

  final status;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      print(androidInfo);
      if (androidInfo.version.sdkInt < 33) {
        status = await Permission.storage.request();
      } else {
        status = await Permission.videos.request();
      }

    } else {
      status = await Permission.videos.request();
    }

  if(status == PermissionStatus.granted) {
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
