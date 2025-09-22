import 'dart:convert';

import 'package:get/get.dart';
import '../constants/constants.dart';
import 'package:http/http.dart' as http;

class MyAgendaRepository extends GetxController {
  static MyAgendaRepository get instance => Get.find();
  var urlBase = constants.urlApi;

  Future<dynamic> fetchAgenda(String idUser) async {
    final response =
        await http.post(Uri.parse('${urlBase}locacao/agenda/usuario'),
            headers: {
              'Content-type': 'application/json',
            },
            body: jsonEncode({
              'id_usuario': idUser,
              'tipo_usuario': 'u',
            }));

    print(response);

    return jsonDecode(response.body);
  }

  Future<dynamic> getDataCompra(int idAgenda) async {
    final response =
        await http.get(Uri.parse('${urlBase}locacao/compra/agenda/$idAgenda'));
    print(response.body);
    return jsonDecode(response.body);
  }

  Future<dynamic> getComprovante(int idCompra, int idCliente) async {
   final response =
        await http.get(Uri.parse('${urlBase}locacao/compra/comprovante/$idCompra/$idCliente'));
    print(response.body);
    return jsonDecode(response.body);
  }
}
