import 'package:get/get.dart';

import '../../../repository/chatRepository.dart';

class ChatController extends GetxController {
  static ChatController get instance => Get.find();
  final ChatRepository chatRepo = Get.put(ChatRepository());

  Future<List<dynamic>> fetchCities(String city_name) async {
    return await chatRepo.fetchCities(city_name);
  }

  Future<List<dynamic>> fetchClients(int ibge) async {
    return await chatRepo.fetchClients(ibge);
  }

  Future<List<dynamic>> fetchSpecificClient(int id_client) async {
    return await chatRepo.fetchSpecificClient(id_client);
  }

  Future<void> changeView(int id_client, int id_user) async {
    await chatRepo.changeView(id_client, id_user);
  }

  Future<dynamic> fetchMessages(int id_client, int id_user) async {
    return await chatRepo.fetchMessages(id_client, id_user);
  }

  Future<void> sendMessage(Map<String, Object> msgData) async {
    await chatRepo.sendMessage(msgData);
  }

  Future<dynamic> fetchMessagesViewed(int id_user) async {
    return await chatRepo.fetchMessagesViewed(id_user);
  }

}
