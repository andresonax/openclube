import 'dart:convert';

import 'package:get/get.dart';
import '../constants/constants.dart';
import 'package:http/http.dart' as http;

class ClientRepository extends GetxController {
  static ClientRepository get instance => Get.find();
  var urlBase = constants.urlApi;

  Future<List<dynamic>> fetchUserData(String userID) async {
    final response = await http.get(Uri.parse('${urlBase}profile/$userID'));
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> fetchCourts(int idClient) async {
    final response =
        await http.get(Uri.parse('${urlBase}clients/courts/$idClient'));
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> fetchClientData(int idClient) async {

    final response = await http.get(Uri.parse('${urlBase}client/$idClient'));

    return jsonDecode(response.body);
  }

  //para quando tem que listar horários na página de cliente
  Future<dynamic> fetchBooked(int id_client) async {
    final response = await http.get(
        Uri.parse('${urlBase}booking/timeslots/booked/perClient/$id_client'));
    return jsonDecode(response.body);
  }

  Future<dynamic> fetchTimeslots(int id_client) async {
    final response = await http
        .get(Uri.parse('${urlBase}booking/timeslots/perClient/$id_client'));
    return jsonDecode(response.body);
  }

  Future<dynamic> fetchBlocked(int idClient) async {
    final response = await http
        .get(Uri.parse('${urlBase}locacao/bloqueio_grade/perClient/$idClient'));
    return jsonDecode(response.body);
  }
}
