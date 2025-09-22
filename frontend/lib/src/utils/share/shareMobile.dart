import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';


Future<void> shareImplementation(Uint8List pngBytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/captura.png').create();
    await file.writeAsBytes(pngBytes);

    await Share.shareXFiles([XFile(file.path)], text: 'Esses são os horários do dia!');
}
