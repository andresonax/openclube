import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../repository/bookingRepository.dart';

class BookingController extends GetxController {
  static BookingController get instance => Get.find();

  final BookingRepository bookingRepo = Get.put(BookingRepository());

  //valida cupom de desconto
  Future<dynamic> validateCoupon(String coupon, int id_client) async {
    return await bookingRepo.validateCoupon(coupon, id_client);
  }

  //busca timeslots
  Future<List<dynamic>> fetchTimeslots(int idPlace) async {
    return await bookingRepo.fetchTimeSlots(idPlace);
  }

  //busca timeslots agendados
  Future<dynamic> fetchBooked(int idPlace) async {
    return await bookingRepo.fetchBooked(idPlace);
  }

  //busca timeslots bloqueados
  Future<dynamic> fetchBlocked(int idPlace) async {
    return await bookingRepo.fetchBlocked(idPlace);
  }

  Future<List<dynamic>> fetchMaterials(int idModality) async {
    return await bookingRepo.fetchMaterials(idModality);
  }

  Future<List<dynamic>> fetchPaymentMethods(int id_client) async {
    return await bookingRepo.fetchPaymentMethods(id_client);
  }

  Future<List<dynamic>> fetchPaymentConditions(int id_client) async {
    return await bookingRepo.fetchPaymentConditions(id_client);
  }

  Future<bool> isCpfRegistered(String idUser) async {
    return await bookingRepo.isCpfRegistered(idUser);
  }

  Future<bool> registerCpf(String idUser, String cpf) async {
    return await bookingRepo.registerCpf(idUser, cpf);
  }

  Future<bool> registerAgenda(
    int idUser,
    int idSpace,
    String userType,
    DateTime date,
    String timeSlots,
    String hourValue,
    String observation,
    int repetition,
    DateTime endDate,
    int idModalitySpace,
    List<Map<String, dynamic>> materials,
    int idPaymentMethod,
    int idPaymentCondition,
  ) async {
    return await bookingRepo.registerAgenda(
      idUser,
      idSpace,
      userType,
      date,
      timeSlots,
      hourValue,
      observation,
      repetition,
      endDate,
      idModalitySpace,
      materials,
      idPaymentMethod,
      idPaymentCondition,
    );
  }

  Future<Map<String, dynamic>> registerCompra(
      int idUser,
      String userType,
      String totalValue,
      List<dynamic> horarioList,
      int idCliente,
      int tipo_pagamento) async {
    print('cheguei no controller');
    return await bookingRepo.registerCompra(
        idUser, userType, totalValue, horarioList, idCliente, tipo_pagamento);
  }

  //vê informações de pagamento
  Future<dynamic> viewPix(int idCompra) async {
    return await bookingRepo.viewPix(idCompra);
  }

  //verifica se pix expirou/foi pago
  Future<dynamic> checkPix(int idCompra) async {
    return await bookingRepo.checkPix(idCompra);
  }

  Future<void> mockConfirmPay() async {
    return await bookingRepo.mockConfirmPay();
  }

  //envia código pix por whatsapp
  Future<void> sendPixCodeWhatsApp(
      String clientId, String phoneNumber, String pixCode) async {
    return await bookingRepo.sendPixCodeWhatsapp(
        clientId, phoneNumber, pixCode);
  }

  //envia confirmação de pagamento por whatsapp
  Future<void> sendPaymentConfirmationWhatsApp(
      String clientId, String phoneNumber) async {
    return await bookingRepo.sendPaymentConfirmationWhatsApp(
        clientId, phoneNumber);
  }

  Future<List<dynamic>> fetchUserData(String userID) async {
    return await bookingRepo.fetchUserData(userID);
  }
}
