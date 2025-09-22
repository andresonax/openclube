import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';

Future<void> savePDFImplementation(List<int> response, String fileName) async {
  await FileSaver.instance.saveFile(
    name: fileName,
    bytes: Uint8List.fromList(response),
    //ext: "pdf",
    mimeType: MimeType.pdf,
  );
}