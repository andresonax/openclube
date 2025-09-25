import 'dart:convert';

import 'package:get/get.dart';
import '../constants/constants.dart';
import 'package:http/http.dart' as http;

class BookingRepository extends GetxController {
  static BookingRepository get instance => Get.find();
  var urlBase = constants.urlApi;
  var urlBaseGestor = constants.urlApiGestor;

  Future<dynamic> validateCoupon(String coupon, int id_client) async {
    final response = await http.post(Uri.parse('${urlBase}coupon/validate'),
        headers: {
          'Content-type': 'application/json',
        },
        body: jsonEncode({
          'id_cliente': id_client,
          'cupom': coupon,
        }));
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> fetchTimeSlots(int idPlace) async {
    final response =
        await http.get(Uri.parse('${urlBase}booking/timeslots/$idPlace'));
    return jsonDecode(response.body);
  }

  Future<dynamic> fetchBooked(int idPlace) async {
    final response = await http
        .get(Uri.parse('${urlBase}booking/timeslots/booked/$idPlace'));
    return jsonDecode(response.body);
  }

  Future<dynamic> fetchBlocked(int idPlace) async {
    final response =
        await http.get(Uri.parse('${urlBase}locacao/bloqueio_grade/$idPlace'));
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> fetchMaterials(int idModality) async {
    final response =
        await http.get(Uri.parse('${urlBase}booking/material/$idModality'));
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> fetchPaymentMethods(int id_client) async {
    final response = await http
        .get(Uri.parse('${urlBase}pagamento/metodos/usados/$id_client'));
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> fetchPaymentConditions(int id_client) async {
    final response = await http
        .get(Uri.parse('${urlBase}pagamento/condicoes/usados/$id_client'));
    return jsonDecode(response.body);
  }

  Future<bool> isCpfRegistered(String idUser) async {
    final response =
        await http.get(Uri.parse('${urlBase}booking/userCpf/$idUser'));
    final cpf = json.decode(response.body)[0]['cpf'];

    if (cpf != null && cpf.toString().isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<bool> registerCpf(String idUser, String cpf) async {
    final response = await http.post(Uri.parse('${urlBase}auth/registerCpf'),
        headers: {
          'Content-type': 'application/json',
        },
        body: jsonEncode({
          'id_usuario': idUser,
          'cpf': cpf,
        }));
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> registerAgenda(
    int idUser,
    int idSpace,
    String userType,
    DateTime date,
    String timeSlot,
    String hourValue,
    String observation,
    int repetition,
    DateTime endDate,
    int idModalitySpace,
    List<Map<String, dynamic>> materials,
    int idPaymentMethod,
    int idPaymentCondition,
  ) async {
    Map<String, dynamic> agendaData = {
      'id_usuario': idUser,
      'tipo_usuario': userType,
      'id_espaco': idSpace,
      'data_agenda': date.toString().substring(0, 10),
      'horario': timeSlot.substring(0, 5),
      'horario_final': timeSlot.substring(8, 13),
      'valor': hourValue,
      'observacao': observation,
      'id_modalidade_espaco': idModalitySpace,
      'repeticao': repetition,
      'data_fim': endDate.toString().substring(0, 10),
      'nome_responsavel': '', //preenchido no backend
      'materiais': materials,
      'id_forma_pagamento': idPaymentMethod,
      'id_condicao_pagamento': idPaymentCondition,
    };

    final response = await http.post(
      Uri.parse('${urlBase}locacao/agenda'),
      headers: {
        'Content-type': 'application/json',
      },
      body: jsonEncode(agendaData),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<Map<String, dynamic>> registerCompra(int idUser, String userType,
      String totalValue, List<dynamic> horarioList, int idCliente, int tipo_pagamento) async {
    Map<String, dynamic> agendaData = {
      'id_usuario': idUser.toString(),
      'tipo_usuario': userType,
      'tipo_pagamento': tipo_pagamento,
      'valor_total': totalValue,
      'horarioList': horarioList,
      'id_cliente': idCliente
    };

    print('agendaData');
    print(agendaData);

    final response = await http.post(
      Uri.parse('${urlBase}locacao/compra'),
      headers: {
        'Content-type': 'application/json',
      },
      body: jsonEncode(agendaData),
    );

    return json.decode(response.body);
  }

  Future<dynamic> viewPix(int idCompra) async {
    final response =
        await http.get(Uri.parse('${urlBase}locacao/compra/pix/$idCompra'));
    return jsonDecode(response.body);
  }

  Future<dynamic> checkPix(int idCompra) async {
    final response =
        await http.get(Uri.parse('${urlBase}locacao/compra/pix/$idCompra'));

    return jsonDecode(response.body);
  }

  //apenas para simular chamada de webhook feita pelo banco
  Future<void> mockConfirmPay() async {
    final response = await http.post(Uri.parse('${urlBase}webhooks/inter/pix'),
        headers: {
          'Content-type': 'application/json',
        },
        body: jsonEncode({
          "pix": [
            {
              "valor_pago": 0.01,
              "e2eid": "1234567890",
              "txid": "11204444310000000000000000000000000"
            }
          ]
        }));
    print('mockPay');
    print(response.body);
  }

  //envia código pix por whatsapp
  Future<void> sendPixCodeWhatsapp(
    String clientId,
    String phoneNumber,
    String pixCode,
    int idCompra) async {
    Map<String, dynamic> whatsappData = {
      'session_name': clientId,
      'phone_number': phoneNumber,
      'pix_code': pixCode,
      'id_compra': idCompra
    };

    print('dados whatsapp');
    print(whatsappData);

    final response = await http.post(
      Uri.parse('${urlBaseGestor}whatsapp/send-pix-code'),
      headers: {
        'Content-type': 'application/json',
      },
      body: jsonEncode(whatsappData),
    );

    print('resposta whatsapp');
    print(response.body);
  }

  //envia confirmação de pagamento por whatsapp
  Future<void> sendPaymentConfirmationWhatsApp(
    String clientId,
    String phoneNumber,
    int idCompra
    ) async {
    Map<String, dynamic> whatsappData = {
      'session_name': clientId,
      'phone_number': phoneNumber,
      'id_compra': idCompra
    };

    final response = await http.post(
      Uri.parse('${urlBaseGestor}whatsapp/send-payment-confirmation'),
      headers: {
        'Content-type': 'application/json',
      },
      body: jsonEncode(whatsappData),
    );
  }

  Future<List<dynamic>> fetchUserData(String userID) async {
    final response = await http.get(Uri.parse('${urlBase}profile/$userID'));
    return jsonDecode(response.body);
  }
}
