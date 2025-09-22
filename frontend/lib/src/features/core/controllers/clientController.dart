import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../repository/clientRepository.dart';

class ClientController extends GetxController {
  static ClientController get instance => Get.find();

  final ClientRepository clientRepo = Get.put(ClientRepository());

  Future<List<dynamic>> fetchUserData(String userID) async {
    return await clientRepo.fetchUserData(userID);
  }

  Future<List<dynamic>> fetchCourts(int idClient) async {
    return await clientRepo.fetchCourts(idClient);
  }

  Future<List<dynamic>> fetchClientData(int idClient) async{
    return await clientRepo.fetchClientData(idClient);
  }

  //para quando tem que listar horários na página de cliente
  
  Future<dynamic> fetchBooked(int id_client) async {
    return clientRepo.fetchBooked(id_client);
  }

  Future<dynamic> fetchTimeslots(int id_client) async {
    final response = await clientRepo.fetchTimeslots(id_client);
    return response;
  }

  Future<dynamic> fetchBlocked(int idClient) async {
    final response = await clientRepo.fetchBlocked(idClient);
    return response;
  }

}
