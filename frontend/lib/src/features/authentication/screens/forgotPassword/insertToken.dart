//packages
import 'package:clubedaareia/src/common_widgets/bottomMenu/topNavBar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../constants/constants.dart';

import '../../controllers/authController.dart';

class insertToken extends StatefulWidget {
  const insertToken({Key? key}) : super(key: key);

  @override
  State<insertToken> createState() => _insertTokenState();
}

class _insertTokenState extends State<insertToken> {
  //controllers
  final authController = Get.put(AuthController());

  //variáveis
  TextEditingController codeController = TextEditingController();
  final codeKey = GlobalKey<FormState>();
  late String token;
  var urlBase = constants.urlApi;
  bool hoverVoltar = false;

  //inicia dados
  @override
  void initState() {
    super.initState();
    token = Get.arguments ?? '';
  }

  //libera memória de controller
  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
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
                    //logo
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
                        "Verifique seu email",
                        style: GoogleFonts.indieFlower(
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 40,
                              color: Colors.white),
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
                              child: Text("Insira o código recebido no email",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                          ),
                          Form(
                            key: codeKey,
                            child: TextFormField(
                              controller: codeController,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Insira o código';
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
                          authController.isCodeWrong
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
                                            "O código inserido não está correto",
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
                                      if (codeKey.currentState?.validate() ??
                                          false)
                                        {
                                          authController.verifyCode(
                                              codeController.text, token)
                                        }
                                    },
                                    child: const Text(
                                      "Enviar",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
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
