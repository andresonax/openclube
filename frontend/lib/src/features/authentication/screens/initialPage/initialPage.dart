import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../constants/constants.dart';
import '../../controllers/authController.dart';

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  // controllers
  final authController = Get.put(AuthController());

  //variáveis
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(230, 230, 230, 1.0),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/background.jpeg"),
              fit: BoxFit.fill,
            ),
          ),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                !constants.isClientExclusive
                    ? Image.asset(
                        'assets/images/logo-placeholder.png',
                        height: 220,
                        width: 220,
                      )
                    : Image.asset(
                        'assets/images/logo-client.png',
                        height: 220,
                        width: 220,
                      ),
                Column(
                  children: [
                    Center(
                        child: !constants.isClientExclusive
                            ? Text(
                                'Clube da Areia',
                                style: GoogleFonts.indieFlower(
                                    textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 40,
                                        color: Colors.white)),
                                textAlign: TextAlign.center,
                              )
                            : Text(
                                constants.clientName,
                                style: GoogleFonts.indieFlower(
                                    textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 40,
                                        color: Colors.black)),
                                textAlign: TextAlign.center,
                              )),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      height: 45,
                      width: MediaQuery.of(context).size.width / 1.3,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0)),
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: () {
                          Get.toNamed("/login");
                        },
                        child: const Text("Acessar minha conta",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      height: 45,
                      width: MediaQuery.of(context).size.width / 1.3,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () {
                            Get.toNamed("/signUp");
                          },
                          child: const Text("Criar nova conta",
                              style: TextStyle(color: Colors.white))),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      height: 45,
                      width: MediaQuery.of(context).size.width / 1.3,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () async {
                            //limpa local storage pra entrar sem conta
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            await prefs.clear();
                            //alterar isso
                            //Get.toNamed("/home");
                            Get.toNamed("/home");
                          },
                          child: const Text("Criar conta depois",
                              style: TextStyle(color: Colors.white))),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Center(
                        child: TextButton(
                      onPressed: () {},
                      child: !constants.isClientExclusive
                          ? const Text(
                              'É dono de Quadra? Clique aqui',
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold),
                            )
                          : Container(),
                    ))
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
