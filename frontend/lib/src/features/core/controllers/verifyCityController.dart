import 'package:get/get.dart';

import '../../../repository/verifyCityRepository.dart';

class VerifyCityController extends GetxController {
  static VerifyCityController get instance => Get.find();

  final VerifyCityRepository verifyCityRepository =
      Get.put(VerifyCityRepository());

  Future<dynamic> searchCities(String caracteresCity) async {
    return await verifyCityRepository.searchCities(caracteresCity);
  }
}
