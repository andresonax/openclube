//packages
import 'package:clubedaareia/src/common_widgets/bottomMenu/topNavBar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:validators/validators.dart';

import 'package:get/get.dart';

import '../../../../constants/constants.dart';
import '../../controllers/authController.dart';

class loginScreen extends StatefulWidget {
  const loginScreen({Key? key}) : super(key: key);

  @override
  State<loginScreen> createState() => _loginScreenState();
}

class _loginScreenState extends State<loginScreen> {
  // controllers
  final authController = Get.put(AuthController());
  //variáveis
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final passwordKey = GlobalKey<FormState>();
  bool isEmailCorrect = false;
  bool checkbox = false;
  bool isInitialized = false;
  bool hoverVoltar = false;
  bool isBookingPending = false;

  @override
  void initState() {
    super.initState();
    verifyServer();
    verifyPendingBooking();
    initialize();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> initialize() async {
    await authController.initialize();
    setState(() {
      isInitialized = true;
    });
  }

  Future<void> verifyServer() async {
    await authController.checkServerStatus();
    setState(() {});
  }

  Future<void> verifyPendingBooking() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString('pendingBooking');

    if (pending != null) {
      isBookingPending = true;
    } else {
      isBookingPending = false;
    }

    print('isBookingPending: $isBookingPending');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(230, 230, 230, 1.0),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.jpeg"),
            fit: BoxFit.fill,
          ),
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            child: SafeArea(
              child: Center(
                child: Column(children: [
                  const TopNavBar(route: '/', backButtonText: 'Voltar'),
                  const SizedBox(height: 30),
                  Container(
                    child: isInitialized
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              //logo
                              constants.isClientExclusive
                                  ? Image.asset(
                                      'assets/images/logo-client.png',
                                      height: 220,
                                      width: 220,
                                    )
                                  : Image.asset(
                                      'assets/images/logo-placeholder.png',
                                      height: 220,
                                      width: 220,
                                    ),

                              const SizedBox(
                                height: 20,
                              ),

                              !authController.isServerOnline
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Center(
                                            child: Text(
                                          'Servidor em Manutenção',
                                          style: GoogleFonts.indieFlower(
                                              textStyle: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 40,
                                                  color: Colors.white)),
                                          textAlign: TextAlign.center,
                                        )),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        Text(
                                          'Realizar Login Agora',
                                          style: GoogleFonts.indieFlower(
                                            textStyle: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 40,
                                                color: Colors.white),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 30,
                                        ),
                                        authController.isErrorInLogin
                                            ? Container(
                                                color: Colors.red,
                                                child: SizedBox(
                                                    height: 45,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            1.2,
                                                    child: const Center(
                                                        child: Text(
                                                      "Dados incorretos, tente novamente",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16),
                                                    ))),
                                              )
                                            : Container(),
                                        SizedBox(
                                          height: isEmailCorrect ? 280 : 200,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              1.2,
                                          child: Column(
                                            children: [
                                              const Padding(
                                                  padding: EdgeInsets.only(
                                                      bottom: 5, top: 10),
                                                  child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text("Email",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .white)))),
                                              TextFormField(
                                                controller: emailController,
                                                onChanged: (val) {
                                                  setState(() {
                                                    isEmailCorrect =
                                                        isEmail(val);
                                                  });
                                                },
                                                decoration:
                                                    const InputDecoration(
                                                  hintText: "seuemail@mail.com",
                                                  fillColor: Colors.white,
                                                  filled: true,
                                                  enabledBorder:
                                                      UnderlineInputBorder(
                                                          borderSide:
                                                              BorderSide.none,
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          10))),
                                                ),
                                              ),
                                              const Padding(
                                                  padding: EdgeInsets.only(
                                                      bottom: 5, top: 10),
                                                  child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text("Senha",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .white)))),
                                              Form(
                                                key: passwordKey,
                                                child: TextFormField(
                                                  controller:
                                                      passwordController,
                                                  obscuringCharacter: '*',
                                                  obscureText: true,
                                                  decoration:
                                                      const InputDecoration(
                                                    hintText: "******",
                                                    fillColor: Colors.white,
                                                    filled: true,
                                                    enabledBorder:
                                                        UnderlineInputBorder(
                                                            borderSide:
                                                                BorderSide.none,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            10))),
                                                  ),
                                                  validator: (value) {
                                                    if (value!.isEmpty) {
                                                      return 'Informe uma senha';
                                                    }
                                                  },
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 14,
                                              ),
                                              isEmailCorrect
                                                  ? SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              1.2,
                                                      child: Column(
                                                        children: [
                                                          ElevatedButton(
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                minimumSize: const Size(
                                                                    double
                                                                        .infinity,
                                                                    50), // altura total
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        16,
                                                                    vertical:
                                                                        10), // menor vertical
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10.0),
                                                                ),

                                                                backgroundColor:
                                                                    isEmailCorrect ==
                                                                            false
                                                                        ? Colors
                                                                            .red
                                                                        : Colors
                                                                            .blue,
                                                              ),
                                                              onPressed:
                                                                  () async {
                                                                if (passwordKey
                                                                        .currentState
                                                                        ?.validate() ??
                                                                    false) {
                                                                  await authController.login(
                                                                      emailController
                                                                          .text,
                                                                      passwordController
                                                                          .text,
                                                                      checkbox, isBookingPending);
                                                                  setState(
                                                                      () {});
                                                                }
                                                              },
                                                              child: const Text(
                                                                'Entrar',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        17,
                                                                    color: Colors
                                                                        .white),
                                                              )),
                                                          Row(
                                                            children: [
                                                              Checkbox(
                                                                value: checkbox,
                                                                onChanged: (bool?
                                                                    newValue) {
                                                                  setState(() {
                                                                    checkbox =
                                                                        newValue!;
                                                                  });
                                                                },
                                                                fillColor: MaterialStateProperty.resolveWith((states) {
                                                                    if (states.contains(MaterialState.selected)) {
                                                                      return Colors.blue; 
                                                                    }
                                                                    return Colors.transparent; 
                                                                  }),   
                                                                side: WidgetStateBorderSide
                                                                    .resolveWith((states) =>
                                                                        const BorderSide(
                                                                            color:
                                                                                Colors.white)),
                                                              ),
                                                              const Text(
                                                                  "Lembrar meus dados",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white)),
                                                            ],
                                                          ),
                                                        ],
                                                      ))
                                                  : Container(),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                Get.toNamed("/forgotPassword");
                                              },
                                              child: Container(
                                                //margin: EdgeInsets.only(right: MediaQuery.of(context).size.width / 7),
                                                child: const Text(
                                                  'Esqueceu a senha?',
                                                  style: TextStyle(
                                                      color: Colors.blue,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Get.toNamed("/signUp");
                                              },
                                              child: Container(
                                                //margin: EdgeInsets.only(left: MediaQuery.of(context).size.width / 7),
                                                child: const Text(
                                                  'Cadastrar',
                                                  style: TextStyle(
                                                      color: Colors.blue,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ],
                                    )
                            ],
                          )
                        : const Center(
                            child: CircularProgressIndicator(),
                          ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
