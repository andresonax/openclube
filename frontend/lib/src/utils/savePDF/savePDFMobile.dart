import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

Future<void> savePDFImplementation(List<int> response, String fileName) async {
  
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

    if(status == PermissionStatus.granted){
      Directory? dir;

    if (Platform.isAndroid) {
      // Tenta salvar na pasta Downloads
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        // fallback se não existir
        dir = await getExternalStorageDirectory();
      }
    } else {
      // iOS
      dir = await getApplicationDocumentsDirectory();
    }

    final path = '${dir!.path}/$fileName.pdf';
    final file = File(path);
    await file.writeAsBytes(Uint8List.fromList(response));

    print('PDF salvo em: $path');
  } 
    
    
}
