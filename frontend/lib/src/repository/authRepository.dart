import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

import '../constants/constants.dart';
import '../utils/dateInverter.dart';

class AuthRepository extends GetxController {
  static AuthRepository get instance => Get.find();

  var urlBase = constants.urlApi;

  // user data
  String email = '';
  String password = '';
  //alterar quando verify server estiver ok
  bool serverOnline = true;
  //alterar quando email não for encontrado na base de dados
  bool emailNotFound = false;
  //alterar quando código inserido estiver errado
  bool wrongCode = false;
  //alterar quando der erro na troca de senha
  bool errorInConfirmPassword = false;
  //alterar quando login não for bem sucedido
  bool errorInAuthenticate = false;

  //registro
  bool errorInTerms = false;
  bool errorInAuthenticateEmail = false;
  bool errorInOtherData = false;
  bool errorInDate = false;

  bool get isErrorInTerms {
    return errorInTerms;
  }

  bool get isErrorInAuthenticateEmail {
    return errorInAuthenticateEmail;
  }

  bool get isErrorInOtherData {
    return errorInOtherData;
  }

  bool get isErrorInDate {
    return errorInDate;
  }

  bool get isErrorInLogin {
    return errorInAuthenticate;
  }

  bool get isEmailNotFound {
    return emailNotFound;
  }

  bool get isCodeWrong {
    return wrongCode;
  }

  bool get isServerOnline {
    return serverOnline;
  }

  bool get isErrorInConfirmPassword {
    return errorInConfirmPassword;
  }

  //registra user
  Future<void> register(
      String completeName,
      String birthDate,
      String email,
      String cellphone,
      String password,
      String confirmPassword,
      bool checkbox) async {
    if (checkbox == false) {
      errorInTerms = true;
      errorInConfirmPassword = false;
      errorInAuthenticateEmail = false;
      errorInOtherData = false;
      errorInDate = false;
      return;
    }

    if (password != confirmPassword) {
      errorInTerms = false;
      errorInConfirmPassword = true;
      errorInAuthenticateEmail = false;
      errorInOtherData = false;
      errorInDate = false;
      return;
    }

    if (dateInverter(birthDate) == "invalid date") {
      errorInTerms = false;
      errorInConfirmPassword = false;
      errorInAuthenticateEmail = false;
      errorInOtherData = false;
      errorInDate = true;
      return;
    }

    String url = '${urlBase}auth/register';
    Map<String, dynamic> userData = {
      "fullName": completeName,
      "birthdate": dateInverter(birthDate),
      "email": email,
      "phone": cellphone,
      "password": password,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
      },
      body: jsonEncode(userData),
    );

    if (jsonDecode(response.body)['status'] == "ok") {
      Get.toNamed("/login");
      errorInTerms = false;
      errorInAuthenticateEmail = false;
      errorInConfirmPassword = false;
      errorInOtherData = false;
      errorInDate = false;
    } else if (jsonDecode(response.body)['desc'] == "email already in use") {
      errorInTerms = false;
      errorInAuthenticateEmail = true;
      errorInConfirmPassword = false;
      errorInOtherData = false;
      errorInDate = false;
    } else {
      errorInTerms = false;
      errorInOtherData = true;
      errorInAuthenticateEmail = false;
      errorInConfirmPassword = false;
      errorInDate = false;
    }
  }

  //verifica se senhas inseridas são iguais e altera
  void changePassword(
      String password, String confirmPassword, int userID) async {
    if (password != confirmPassword) {
      errorInConfirmPassword = true;

      return;
    } else {
      String url = '${urlBase}pwRecovery/changePw/$userID';
      Map<String, dynamic> userData = {
        "password": password,
      };

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-type': 'application/json',
        },
        body: jsonEncode(userData),
      );

      if (jsonDecode(response.body)['status'] == "ok") {
        //go to login screen
        Get.toNamed('/login');
      }
    }
  }

  //verifica código inserido
  void verifyCode(String code, String token) async {
    String url = '${urlBase}pwRecovery/verifyCode';
    Map<String, dynamic> userData = {
      "code": code,
      "token": token,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
      },
      body: jsonEncode(userData),
    );

    if (jsonDecode(response.body)['status'] == "ok") {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      int userID = decodedToken['id'];
      Get.toNamed("/updatePassword", arguments: userID);
    } else {
      wrongCode = true;
    }
  }

  // Send email for password recovery
  Future<void> sendEmail(String email) async {
    String url = '${urlBase}pwRecovery/sendCode';
    Map<String, dynamic> userData = {
      "email": email,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
      },
      body: jsonEncode(userData),
    );

    if (jsonDecode(response.body)['status'] == "ok") {
      var token = jsonDecode(response.body)['token'];
      //vai pra página de inserir código

      Get.toNamed("/insertToken", arguments: token);
    } else {
      emailNotFound = true;
    }
  }

  // Verifies if the server is online
  Future<void> verifyServer() async {
    try {
      var response = await http.get(Uri.parse('${urlBase}verifyServer'));
      serverOnline = true;
      print('testando server');
      print(response.body);
    } catch (e) {
      serverOnline = false;
    }
  }

  // Picks data from local storage
  Future<void> pickDataFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? value = prefs.getString('token');
    String? stayLogged = prefs.getString('stayLogged');
    if (stayLogged == 'yes' && value != null && isServerOnline == true) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(value);
      email = decodedToken['email'];
      password = decodedToken['password'];
      Get.offAllNamed("/home");
    }
  }

  // Performs login API call
  Future<void> login(String email, String password, bool checkbox,
      bool isBookingPending) async {
    //verificação se app está vendido pra algum cliente
    //se estiver, vá direto para a página do cliente
    //bool isClient = true;
    int idClient = 1; //definir idClient com base no banco de dados

    String url = '${urlBase}auth/login';
    Map<String, dynamic> userData = {
      "email": email,
      "password": password,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
      },
      body: jsonEncode(userData),
    );

    print('resposta login');
    print(response.body);

    if (jsonDecode(response.body)['status'] == "ok") {
      //se login tiver certo, verifico se tem algum agendamento pendente
      if (isBookingPending) {}

      if (checkbox == true) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', jsonDecode(response.body)['token']);
        await prefs.setString('stayLogged', "yes");
      } else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', jsonDecode(response.body)['token']);
        await prefs.setString('stayLogged', "no");
      }
      if (jsonDecode(response.body)['status'] == "ok") {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', jsonDecode(response.body)['token']);
        await prefs.setString('stayLogged', checkbox == true ? "yes" : "no");

        if (isBookingPending) {
          final pending = prefs.getString('pendingBooking');
          if (pending != null) {
            final bookingData = jsonDecode(pending) as Map<String, dynamic>;

            bookingData['date'] = DateTime.parse(bookingData['date']);

            await prefs.remove('pendingBooking');

            print('os dados são:');
            print(bookingData);

            Get.offNamed('/bookingDetails', arguments: {
              'date': bookingData['date'],
              'local': bookingData['local'],
              'materials': List<dynamic>.from(bookingData['materials']),
              'materialsIds': List<dynamic>.from(bookingData['materialsIds']),
              'materialsPrices': List<dynamic>.from(bookingData['materialsPrices']),
              'materialsQuantities': List<dynamic>.from(bookingData['materialsQuantities']),
              'basePrice': bookingData['basePrice'],
              'selectedSlots': List<String>.from(bookingData['selectedSlots']),
              'courtData': bookingData['courtData'],
              'paymentMethods': List<dynamic>.from(bookingData['paymentMethods']),
              'paymentConditions': List<dynamic>.from(bookingData['paymentConditions']),
              'idPlace': bookingData['idPlace'],
              'idModalityPlace': bookingData['idModalityPlace'],
            });

            return;
          }
        }

        // fluxo normal
        Get.toNamed('/home');
      } else {
        errorInAuthenticate = true;
      }

      Get.toNamed('/home');
    } else {
      errorInAuthenticate = true;
    }
  }
}
