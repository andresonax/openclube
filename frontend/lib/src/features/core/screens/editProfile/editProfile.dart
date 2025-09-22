import 'dart:typed_data';

import 'package:clubedaareia/src/common_widgets/bottomMenu/topNavBar.dart';
import 'package:clubedaareia/src/features/core/controllers/editProfileController.dart';
import 'package:clubedaareia/src/features/core/screens/editProfile/widgets/deleteAccount.dart';
import 'package:clubedaareia/src/features/core/screens/editProfile/widgets/logout.dart';
import 'package:clubedaareia/src/utils/dateInverter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:validators/validators.dart';
import '../../../../constants/constants.dart';
import '../../../../utils/getIdUser.dart';

import '../../../../utils/filePicker/filePickerError.dart'
    if (dart.library.io) '../../../../utils/filePicker/filePickerMobile.dart'
    if (dart.library.html) '../../../../utils/filePicker/filePickerWeb.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  //controllers
  final editProfileController = Get.put(EditProfileController());

  //variáveis
  final completeNameKey = GlobalKey<FormState>();
  final birthDateKey = GlobalKey<FormState>();
  final emailKey = GlobalKey<FormState>();
  final cellphoneKey = GlobalKey<FormState>();
  TextEditingController completeNameController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController cellphoneController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  String previousBirthDate = '';
  String urlBase = constants.urlApi;
  String idUser = '';
  List<dynamic> userData = [];

  //pega imagem do sistema
  Future<void> _pickImage() async {
    FilePickerResult? result = (await pickFile()) as FilePickerResult?;
    if (result != null) {
      setState(() {
        _imageBytes = result.files.first.bytes;
        _imageName = '$idUser.png';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    String id = await getIdUser();
    setState(() {
      idUser = id;
    });

    userData = Get.arguments ?? [];
    if (userData.isNotEmpty) {
      setState(() {
        completeNameController.text = userData[0]['nome_completo'];
        birthDateController.text =
            dateReverter(userData[0]['nascimento'].toString().substring(0, 10));
        emailController.text = userData[0]['email'];
        cellphoneController.text = userData[0]['celular'];
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/home');
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
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
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TopNavBar(route: '/home', backButtonText: 'Voltar'),
                  Logout(),
                ],
              ),
              const Padding(padding: EdgeInsets.only(top: 60)),
              Text("Meus dados",
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
                          alignment: Alignment.center,
                          child: Text(
                            "Clique na foto para alterar",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      _imageBytes == null
                          ? MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: Image.network(
                                          '${urlBase}profile/getPicture/$idUser?${DateTime.now().minute}',
                                          height: 100,
                                          width: 100,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Image.asset(
                                              'assets/images/profile.png',
                                              height: 100,
                                              width: 100,
                                            );
                                          },
                                        )
                                      
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: _pickImage,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: Image.memory(
                                  _imageBytes!,
                                  width:
                                      100, 
                                  height: 100,
                                ),
                              ),
                            ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 5, top: 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Nome Completo",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
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
                    ],
                  )),
              editProfileController.isErrorInDate
                  ? Column(
                      children: [
                        const SizedBox(
                          height: 30,
                        ),
                        Container(
                          color: Colors.red,
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
              editProfileController.isEmailInUse
                  ? Column(
                      children: [
                        const SizedBox(
                          height: 30,
                        ),
                        Container(
                          color: Colors.red,
                          child: SizedBox(
                              height: 45,
                              width: MediaQuery.of(context).size.width / 1.2,
                              child: const Center(
                                  child: Text(
                                "Email já cadastrado por outro usuário",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ))),
                        )
                      ],
                    )
                  : Container(),
              editProfileController.isErrorInOtherData
                  ? Column(
                      children: [
                        const SizedBox(
                          height: 30,
                        ),
                        Container(
                          color: Colors.red,
                          child: SizedBox(
                              height: 45,
                              width: MediaQuery.of(context).size.width / 1.2,
                              child: const Center(
                                  child: Text(
                                "Erro na atualização da imagem, tente novamente mais tarde",
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
                              cellphoneKey.currentState!.validate())
                            {
                              editProfileController.updateProfile(
                                  completeNameController.text,
                                  birthDateController.text,
                                  emailController.text,
                                  cellphoneController.text,
                                  idUser,
                                  _imageBytes,
                                  _imageName),
                              setState(() {})
                            }
                        },
                        child: const Text(
                          "Atualizar Dados",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  )),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  const Spacer(),
                  userData.isEmpty
                      ? Container()
                      : DeleteAccount(
                          idUser: userData[0]['id_usuario'].toString()),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
