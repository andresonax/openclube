//packages
import 'package:clubedaareia/src/common_widgets/bottomMenu/topNavBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:validators/validators.dart';
import '../../../../constants/constants.dart';

import '../../controllers/authController.dart';


class signUpScreen extends StatefulWidget {
  const signUpScreen({Key? key}) : super(key: key);

  @override
  State<signUpScreen> createState() => _signUpScreenState();
}

class _signUpScreenState extends State<signUpScreen> {
  //controllers
  final authController = Get.put(AuthController());

  //variáveis
  final completeNameKey = GlobalKey<FormState>();
  final birthDateKey = GlobalKey<FormState>();
  final emailKey = GlobalKey<FormState>();
  final cellphoneKey = GlobalKey<FormState>();
  final passwordKey = GlobalKey<FormState>();
  final confirmPasswordKey = GlobalKey<FormState>();
  TextEditingController completeNameController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController cellphoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  String previousBirthDate = '';
  bool hoverVoltar = false;
  var urlBase = constants.urlApi;
  bool checkbox = false;

  //libera memória de controllers
  @override
  void dispose() {
    completeNameController.dispose();
    birthDateController.dispose();
    emailController.dispose();
    cellphoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
  
  //define URL dos termos de uso
  void _launchURL() async {
    final Uri _url = Uri.parse('');
    await launchUrl(_url);
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
              const Padding(padding: EdgeInsets.only(top: 60)),
              Text("Realizar Cadastro",
                  style: GoogleFonts.indieFlower(
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 40,
                          color: Colors.white))),
              SizedBox(
                  width: MediaQuery.of(context).size.width / 1.2,
                  child: Column(
                    children: [
                      const Padding(
                          padding: EdgeInsets.only(bottom: 5, top: 10),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Nome Completo",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)))),
                      Form(
                        key: completeNameKey,
                        child: TextFormField(
                          controller: completeNameController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Informe o nome completo';
                            }
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s]')),
                          ],
                          decoration: const InputDecoration(
                            hintText: "Seu nome completo",
                            fillColor: Colors.white,
                            filled: true,
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                          ),
                        ),
                      ),
                      const Padding(
                          padding: EdgeInsets.only(bottom: 5, top: 10),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Data de Nascimento",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)))),
                      Form(
                        key: birthDateKey,
                        child: TextFormField(
                          controller: birthDateController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Informe a data de nascimento';
                            }
                          },
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(10),
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9/]')),
                          ],
                          onChanged: (value) {
                            //algo foi apagado
                            if (value.length < previousBirthDate.length) {
                              String deletedChar =
                                  previousBirthDate.replaceAll(value, '');
                              if (deletedChar == '/') {
                                birthDateController.text =
                                    value.substring(0, value.length - 1);
                                birthDateController.selection =
                                    TextSelection.fromPosition(
                                  TextPosition(
                                      offset: birthDateController.text.length),
                                );

                                return;
                              }
                            }
                            if (value.length == 2 && !value.endsWith('/')) {
                              birthDateController.text = "$value/";
                              birthDateController.selection =
                                  TextSelection.fromPosition(
                                TextPosition(
                                    offset: birthDateController.text.length),
                              );
                            } else if (value.length == 5 &&
                                !value.endsWith('/')) {
                              birthDateController.text =
                                  "${value.substring(0, 5)}/${value.substring(5)}";
                              birthDateController.selection =
                                  TextSelection.fromPosition(
                                TextPosition(
                                    offset: birthDateController.text.length),
                              );
                            }

                            setState(() {
                              previousBirthDate = birthDateController.text;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: "dd/mm/aaaa",
                            fillColor: Colors.white,
                            filled: true,
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                          ),
                        ),
                      ),
                      const Padding(
                          padding: EdgeInsets.only(bottom: 5, top: 10),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Email",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)))),
                      Form(
                        key: emailKey,
                        child: TextFormField(
                          controller: emailController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Informe o email';
                            } else if (!isEmail(value!)) {
                              return 'Informe um email válido';
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: "seuemail@mail.com",
                            fillColor: Colors.white,
                            filled: true,
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                          ),
                        ),
                      ),
                      const Padding(
                          padding: EdgeInsets.only(bottom: 5, top: 10),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Celular",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)))),
                      Form(
                        key: cellphoneKey,
                        child: TextFormField(
                          controller: cellphoneController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Informe o telefone';
                            } else if (value.length < 11) {
                              return 'Telefone muito pequeno';
                            }
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          decoration: const InputDecoration(
                            hintText: "(__)9________",
                            fillColor: Colors.white,
                            filled: true,
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                          ),
                        ),
                      ),
                      const Padding(
                          padding: EdgeInsets.only(bottom: 5, top: 10),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Senha",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)))),
                      Form(
                        key: passwordKey,
                        child: TextFormField(
                          obscureText: true,
                          obscuringCharacter: '*',
                          controller: passwordController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Informe uma senha';
                            } else if (value!.length < 5) {
                              return 'Senha muito pequena';
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: "*****",
                            fillColor: Colors.white,
                            filled: true,
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                          ),
                        ),
                      ),
                      const Padding(
                          padding: EdgeInsets.only(bottom: 5, top: 10),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Confirmar Senha",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)))),
                      Form(
                        key: confirmPasswordKey,
                        child: TextFormField(
                          obscureText: true,
                          obscuringCharacter: '*',
                          controller: confirmPasswordController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Confirme a senha';
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: "*****",
                            fillColor: Colors.white,
                            filled: true,
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: checkbox,
                            onChanged: (bool? newValue) {
                              setState(() {
                                checkbox = newValue!;
                              });
                            },
                            side: MaterialStateBorderSide.resolveWith(
                              (states) => BorderSide(color: Colors.white),
                            ),
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text:
                                        "Declaro que li e estou de acordo com os ",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  WidgetSpan(
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: _launchURL,
                                        child: const Text(
                                          "TERMOS",
                                          style: TextStyle(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: " de uso do site",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  )),
              authController.isErrorInTerms
                  ? Column(
                      children: [
                        const SizedBox(
                          height: 30,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: SizedBox(
                              height: 45,
                              width: MediaQuery.of(context).size.width / 1.2,
                              child: const Center(
                                  child: Text(
                                "É necessário concordar com os termos para cadastrar",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ))),
                        )
                      ],
                    )
                  : Container(),
              authController.isErrorInAuthenticateEmail
                  ? Column(
                      children: [
                        const SizedBox(
                          height: 30,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: SizedBox(
                              height: 45,
                              width: MediaQuery.of(context).size.width / 1.2,
                              child: const Center(
                                  child: Text(
                                "Email já cadastrado anteriormente",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ))),
                        )
                      ],
                    )
                  : Container(),
              authController.isErrorInConfirmPassword
                  ? Column(
                      children: [
                        const SizedBox(
                          height: 30,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: SizedBox(
                              height: 45,
                              width: MediaQuery.of(context).size.width / 1.2,
                              child: const Center(
                                  child: Text(
                                "Senhas devem coincidir",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ))),
                        )
                      ],
                    )
                  : Container(),
              authController.isErrorInDate
                  ? Column(
                      children: [
                        const SizedBox(
                          height: 30,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: SizedBox(
                              height: 45,
                              width: MediaQuery.of(context).size.width / 1.2,
                              child: const Center(
                                  child: Text(
                                "Data inválida, tente novamente",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ))),
                        )
                      ],
                    )
                  : Container(),
              authController.isErrorInOtherData
                  ? Column(
                      children: [
                        const SizedBox(
                          height: 30,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          //color: Colors.red,
                          child: SizedBox(
                              height: 45,
                              width: MediaQuery.of(context).size.width / 1.2,
                              child: const Center(
                                  child: Text(
                                "Erro no cadastro, tente novamente",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
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
                          if (completeNameKey.currentState!.validate() &&
                              birthDateKey.currentState!.validate() &&
                              emailKey.currentState!.validate() &&
                              cellphoneKey.currentState!.validate() &&
                              passwordKey.currentState!.validate() &&
                              confirmPasswordKey.currentState!.validate())
                            {authController.register(
                              completeNameController.text,
                              birthDateController.text,
                              emailController.text,
                              cellphoneController.text,
                              passwordController.text,
                              confirmPasswordController.text,
                              checkbox
                            ),
                            setState(() {})
                            }
                        },
                        child: const Text(
                          "Cadastrar",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  )),
              const SizedBox(
                height: 30,
              )
            ],
          ),
        ),
      ),
    );
  }
}
