//packages
import 'package:clubedaareia/src/common_widgets/bottomMenu/topNavBar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:validators/validators.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../constants/constants.dart';

import '../../controllers/authController.dart';


class forgotPassword extends StatefulWidget {
  const forgotPassword({Key? key}) : super(key: key);

  @override
  _forgotPasswordState createState() => _forgotPasswordState();
}

class _forgotPasswordState extends State<forgotPassword> {

  //controllers
  final authController = Get.put(AuthController());

  //variáveis
  TextEditingController emailController = TextEditingController();
  final emailKey = GlobalKey<FormState>();
  bool emailNotFound = false;
  var urlBase = constants.urlApi;
  bool hoverVoltar = false;

  //libera memória de controller
  @override
  void dispose() {
    emailController.dispose();
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
                        "Recuperar senha",
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
                          //form email
                          const Padding(
                            padding: EdgeInsets.only(bottom: 5, top: 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Email",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                          ),

                          Form(
                            key: emailKey,
                            child: TextFormField(
                              controller: emailController,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Insira o email';
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
                                      BorderRadius.all(Radius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    authController.isEmailNotFound
                        ? Column(
                            children: [
                              const SizedBox(
                                height: 20,
                              ),
                              Container(
                                color: Colors.red,
                                child: SizedBox(
                                    height: 45,
                                    width:
                                        MediaQuery.of(context).size.width / 1.2,
                                    child: const Center(
                                        child: Text(
                                      "Email não cadastrado, tente novamente",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ))),
                              ),
                            ],
                          )
                        : Container(),

                    Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Container(
                          width: MediaQuery.of(context).size.width / 1.2,
                          decoration: BoxDecoration(
                            color:
                                Colors.blue, // Defina a cor de fundo desejada
                            borderRadius: BorderRadius.circular(
                                8.0), // Opcional: arredondamento das bordas
                          ),
                          child: SizedBox(
                            height: 45,
                            child: TextButton(
                              onPressed: () => {
                                if (emailKey.currentState?.validate() ?? false)
                                  {authController.sendEmail(emailController.text)}
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
      ),
    );
  }
}
