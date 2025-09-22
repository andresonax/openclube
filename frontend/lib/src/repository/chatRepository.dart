import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:validators/sanitizers.dart';

import '../constants/constants.dart';

class ChatRepository extends GetxController {
  static ChatRepository get instance => Get.find();
  var urlBase = constants.urlApi;

  Future<void> changeView(int id_client, int id_user) async {
    final response = await http.post(Uri.parse('${urlBase}messages/changeView'),
        headers: {
          'Content-type': 'application/json',
        },
        body: jsonEncode({
          'id_cliente': id_client,
          'id_usuario': id_user,
        }));
  }

  Future<List<dynamic>> fetchCities(String city_name) async {
    final response = await http.get(Uri.parse('${urlBase}cities/$city_name'));
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> fetchClients(int ibge) async {
    final response = await http.get(Uri.parse('${urlBase}clients/$ibge'));
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> fetchSpecificClient(int id_client) async {
    final response = await http.get(Uri.parse('${urlBase}client/$id_client'));
    return jsonDecode(response.body);
  }

  Future<dynamic> fetchMessages(int id_client, int id_user) async {
    final response = await http.post(Uri.parse('${urlBase}messages'),
        headers: {
          'Content-type': 'application/json',
        },
        body: jsonEncode({
          'id_client': id_client,
          'id_user': id_user,
        }));
    print(response.body);
    return jsonDecode(response.body);
  }

  Future<bool> sendMessage(Map<String, Object> msgData) async{
    final response = await http.post(Uri.parse('${urlBase}messages/send'),
        headers: {
          'Content-type': 'application/json',
        },
        body: jsonEncode({
          'id_cliente': msgData['id_cliente'],
          'id_usuario': msgData['id_usuario'],
          'mensagem': msgData['mensagem'],
          'remetente': msgData['remetente'],
          'data_envio': msgData['data_envio'],
        }));
        if(response.statusCode == 200){
          return true;
        } else {
          return false;
        }
  }

   Future<dynamic> fetchMessagesViewed(int id_user) async {
    final response = await http.get(
        Uri.parse('${urlBase}messages/isViewed/$id_user'));
    return jsonDecode(response.body);
  }


  
}
