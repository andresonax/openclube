import 'dart:convert';

import 'package:get/get.dart';
import '../constants/constants.dart';
import 'package:http/http.dart' as http;

class VerifyCityRepository extends GetxController {
  static VerifyCityRepository get instance => Get.find();
  var urlBase = constants.urlApi;

  Future<dynamic> searchCities(caracteresCity) async {
    final response = await http.get(Uri.parse('${urlBase}cities/$caracteresCity'));
    return jsonDecode(response.body);
  }
}
