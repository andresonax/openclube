import 'package:clubedaareia/src/features/core/controllers/editProfileController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class DeleteAccount extends StatefulWidget {
  String idUser;
  DeleteAccount({required this.idUser, super.key});

  @override
  State<DeleteAccount> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends State<DeleteAccount> {
  //controllers
  final editProfileController = Get.put(EditProfileController());

  //variáveis
  bool hoverDeleteAccount = false;

  void confirmDeleteAccount() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Tem certeza que deseja excluir sua conta?',
              textAlign: TextAlign.center,
              style: GoogleFonts.indieFlower(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            content: SingleChildScrollView(
              child: Container(),
            ),
            actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), 
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8), 
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), 
                        ),
                      ),
                      onPressed: () {
                        editProfileController.deleteAccount(widget.idUser);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Confirmar'),
                    ),
                  ],
                )

            ],
          );
        });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 35, right: 15),
      child: Align(
        alignment: Alignment.centerRight,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (h) {
            setState(() {
              hoverDeleteAccount = true;
            });
          },
          onExit: (h) {
            setState(() {
              hoverDeleteAccount = false;
            });
          },
          child: GestureDetector(
              onTap: () => confirmDeleteAccount(),
              child: Row(children: [
                Icon(Icons.delete,
                    color: hoverDeleteAccount ? Colors.black : Colors.white),
                const SizedBox(width: 5),
                Text("Excluir Conta",
                    style: GoogleFonts.indieFlower(
                      fontSize: 22,
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            hoverDeleteAccount ? Colors.black : Colors.white
                        )
                    )
                )
              ])),
        ),
      ),
    );
  }
}
