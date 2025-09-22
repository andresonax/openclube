import 'dart:convert';
import 'dart:typed_data';

import 'package:clubedaareia/src/utils/dateInverter.dart';
import 'package:clubedaareia/src/utils/logout.dart';
import 'package:get/get.dart';
import '../constants/constants.dart';
import 'package:http/http.dart' as http;

class EditProfileRepository extends GetxController {
  static EditProfileRepository get instance => Get.find();
  var urlBase = constants.urlApi;

  bool hasProfilePicture = false;
  bool errorInDate = false;
  bool emailInUse = false;
  bool errorInOtherData = false;



  bool get isErrorInDate {
    return errorInDate;
  }

  bool get isEmailInUse {
    return emailInUse;
  }

  bool get isErrorInOtherData {
    return errorInOtherData;
  }

  Future<void> deleteAccount(String idUser) async {
    await http.delete(Uri.parse('${urlBase}profile/$idUser'));
    logout();
  }

  Future<void> updateProfile(
      String completeName,
      String birthDate,
      String email,
      String cellPhone,
      String idUser,
      Uint8List? imageBytes,
      String? imageName) async {
    if (dateInverter(birthDate) == 'invalid date') {
      emailInUse = false;
      errorInOtherData = false;
      errorInDate = true;
    }

    Map<String, dynamic> userData = {
      "nome_completo": completeName,
      "nascimento": dateInverter(birthDate),
      "email": email,
      "celular": cellPhone,
      "imagem": imageBytes == null ? '' : base64Encode(imageBytes),
      "nome_imagem": imageName
    };
    final response = await http.post(
      Uri.parse('${urlBase}profile/$idUser'),
      headers: {
        'Content-type': 'application/json',
      },
      body: jsonEncode(userData),
    );
    if (response.statusCode == 200) {
      Get.toNamed('/home');
    } else if (response.statusCode == 400) {
      emailInUse = true;
    } else {
      errorInOtherData = true;
    }
  }
}
