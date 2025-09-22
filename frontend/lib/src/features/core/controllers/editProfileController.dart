import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../repository/editProfileRepository.dart';

class EditProfileController extends GetxController {
  static EditProfileController get instance => Get.find();
  final EditProfileRepository editProfileRepo =
      Get.put(EditProfileRepository());


  bool get isErrorInDate {
    return editProfileRepo.isErrorInDate;
  }

  bool get isEmailInUse {
    return editProfileRepo.isEmailInUse;
  }

  bool get isErrorInOtherData {
    return editProfileRepo.isErrorInOtherData;
  }

  Future<void> deleteAccount(String idUser) async {
    editProfileRepo.deleteAccount(idUser);
  }

  Future<void> updateProfile(
      String completeName,
      String birthDate,
      String email,
      String cellPhone,
      String idUser,
      Uint8List? imageBytes,
      String? imageName) async {
    await editProfileRepo.updateProfile(completeName, birthDate, email,
        cellPhone, idUser, imageBytes, imageName);
  }
}
