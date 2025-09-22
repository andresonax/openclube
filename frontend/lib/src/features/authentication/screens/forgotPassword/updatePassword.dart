//packages
import 'package:clubedaareia/src/common_widgets/bottomMenu/topNavBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../../../../constants/constants.dart';

import '../../controllers/authController.dart';


//rota usada
import '../login/loginScreen.dart';

class updatePassword extends StatefulWidget {
  const updatePassword({Key? key}) : super(key: key);

  @override
  State<updatePassword> createState() => _updatePasswordState();
}

class _updatePasswordState extends State<updatePassword> {
  //controllers
  final authController = Get.put(AuthController());
  //variáveis
  late int userID;
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  final passwordKey = GlobalKey<FormState>();
  final confirmPasswordKey = GlobalKey<FormState>();
  bool errorInConfirmPassword = false;
  var urlBase = constants.urlApi;
  bool hoverVoltar = false;

  //inicia dados
  @override
  void initState() {
    super.initState();
    userID = Get.arguments ?? '';
    userID.toString();
  }

  //libera memória de controllers
  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  //verifica se senhas inseridas são iguais e altera
  void changePassword() async {
    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        errorInConfirmPassword = true;
      });
      return;
    } else {
      String url = '${urlBase}pwRecovery/changePw/$userID';
      Map<String, dynamic> userData = {
        "password": passwordController.text,
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
        if (context.mounted) {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => loginScreen()));
        }
      }
    }
  }

  //parte visual
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(230, 230, 230, 1.0),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.jpeg"),
            fit: BoxFit.fill,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const TopNavBar(route: '/', backButtonText: 'Voltar'),
              Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo-placeholder.png',
                      height: 220,
                      width: 220,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(),
                      child: Text(
                        "Pronto!",
                        style: GoogleFonts.indieFlower(
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 40,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(),
                      child: Text(
                        "Atualize sua senha",
                        style: GoogleFonts.indieFlower(
                          textStyle: const TextStyle(
                              fontSize: 20, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 1.2,
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 5, top: 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Insira a nova senha  ",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                          ),
                          Form(
                            key: passwordKey,
                            child: TextFormField(
                              controller: passwordController,
                              obscureText: true,
                              obscuringCharacter: '*',
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Insira a nova senha';
                                } else if (value!.length < 5) {
                                  return 'Senha muito pequena';
                                }
                              },
                              decoration: const InputDecoration(
                                fillColor: Colors.white,
                                filled: true,
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 5, top: 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Confirme a nova senha  ",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                          ),
                          Form(
                            key: confirmPasswordKey,
                            child: TextFormField(
                              controller: confirmPasswordController,
                              obscureText: true,
                              obscuringCharacter: '*',
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Confirme a nova senha';
                                } else if (value!.length < 5) {
                                  return 'Senha muito pequena';
                                }
                              },
                              decoration: const InputDecoration(
                                fillColor: Colors.white,
                                filled: true,
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                          errorInConfirmPassword
                              ? Column(
                                  children: [
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Container(
                                      color: Colors.red,
                                      child: SizedBox(
                                          height: 45,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              1.2,
                                          child: const Center(
                                              child: Text(
                                            "As senhas inseridas devem ser iguais",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16),
                                          ))),
                                    )
                                  ],
                                )
                              : Container(),
                          Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Container(
                                width: MediaQuery.of(context).size.width / 1.2,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: SizedBox(
                                  height: 45,
                                  child: TextButton(
                                    onPressed: () => {
                                      if (passwordKey.currentState
                                              ?.validate() ??
                                          false)
                                        {authController.changePassword(passwordController.text, confirmPasswordController.text, userID)}
                                    },
                                    child: const Text(
                                      "Alterar",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              )),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
