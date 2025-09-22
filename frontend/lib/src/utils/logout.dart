//desloga do sistema
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

void logout() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  Future.delayed(Duration.zero, () {
    Get.offAllNamed('/login');
  });
}
