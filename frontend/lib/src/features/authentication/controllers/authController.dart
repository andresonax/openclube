import 'package:get/get.dart';

import '../../../repository/authRepository.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();
  final AuthRepository authRepo = Get.put(AuthRepository());

  bool get isErrorInTerms {
    return authRepo.isErrorInTerms;
  }

  bool get isErrorInAuthenticateEmail {
    return authRepo.isErrorInAuthenticateEmail;
  }

  bool get isErrorInOtherData {
    return authRepo.isErrorInOtherData;
  }

  bool get isErrorInDate {
    return authRepo.isErrorInDate;
  }

  bool get isErrorInConfirmPassword {
    return authRepo.isErrorInConfirmPassword;
  }

  bool get isServerOnline {
    return authRepo.isServerOnline;
  }

  bool get isErrorInLogin {
    return authRepo.isErrorInLogin;
  }

  bool get isEmailNotFound {
    return authRepo.emailNotFound;
  }

  bool get isCodeWrong {
    return authRepo.isCodeWrong;
  }

  Future<void> initialize() async {
    await authRepo.pickDataFromLocalStorage();
  }

  Future<void> checkServerStatus() async {
    await authRepo.verifyServer();
  }

  Future<void> login(String email, String password, bool checkbox, bool isBookingPending) async {
    return await authRepo.login(email, password, checkbox, isBookingPending);
  }

  Future<void> sendEmail(String email) async {
    return await authRepo.sendEmail(email);
  }

  Future<void> verifyCode(String code, String token) async {
    return authRepo.verifyCode(code, token);
  }

  Future<void> changePassword(
      String password, String confirmPassword, int userID) async {
    return authRepo.changePassword(password, confirmPassword, userID);
  }

  Future<void> register(
      String completeName,
      String birthDate,
      String email,
      String cellphone,
      String password,
      String confirmPassword,
      bool checkbox) async {
    return await authRepo.register(completeName, birthDate, email, cellphone,
        password, confirmPassword, checkbox);
  }
}
