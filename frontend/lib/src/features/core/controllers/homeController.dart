import 'package:get/get.dart';

import '../../../repository/homeRepository.dart';

class HomeController extends GetxController {
  static HomeController get instance => Get.find();
  final HomeRepository homeRepo = Get.put(HomeRepository());

  Future<List<dynamic>> fetchUserData(String userID) async {
    return await homeRepo.fetchUserData(userID);
  }

  Future<List<dynamic>> fetchCities(String city_name) async {
    return await homeRepo.fetchCities(city_name);
  }

  Future<List<dynamic>> fetchClients(int ibge) async {
    return await homeRepo.fetchClients(ibge);
  }

  Future<List<dynamic>> fetchReviews(int ibge) async {
    return await homeRepo.fetchReviews(ibge);
  }

  Future<void> sendReview(double stars, int idClient, String idUser) async {
    homeRepo.sendReview(stars, idClient, idUser);
  }
}
