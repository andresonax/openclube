import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:validators/sanitizers.dart';

import '../constants/constants.dart';

class HomeRepository extends GetxController {
  static HomeRepository get instance => Get.find();
  var urlBase = constants.urlApi;

  Future<List<dynamic>> fetchUserData(String userID) async {
    final response = await http.get(Uri.parse('${urlBase}profile/$userID'));
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> fetchCities(String city_name) async {
    final response = await http.get(Uri.parse('${urlBase}cities/$city_name'));
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> fetchClients(int ibge) async {
    final response = await http.get(Uri.parse('${urlBase}clients/$ibge'));
    print('do repo');
    print(response.body);
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> fetchReviews(int ibge) async {
    final response = await http.get(Uri.parse('${urlBase}reviews/$ibge'));
    return jsonDecode(response.body);
  }

  Future<void> sendReview(double stars, int idClient, String idUser) async {
    Map<String, dynamic> reviewData = {
      "stars": stars,
      "id_cliente": idClient,
      "id_usuario": toInt(idUser)
    };
    final response = await http.post(
      Uri.parse('${urlBase}reviews'),
      headers: {
        'Content-type': 'application/json',
      },
      body: jsonEncode(reviewData),
    );
  }
}
