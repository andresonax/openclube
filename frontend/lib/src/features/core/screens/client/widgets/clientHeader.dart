import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../../../../constants/constants.dart';
import '../../../../../utils/getIdUser.dart';
import '../../../controllers/clientController.dart';

class ClientHeader extends StatefulWidget {
  final List<dynamic>? clientData;
  const ClientHeader({
    this.clientData,
    super.key,
  });

  @override
  State<ClientHeader> createState() => _ClientHeaderState();
}

class _ClientHeaderState extends State<ClientHeader> {


  //controllers
  final clientController = Get.put(ClientController());
  
  String urlBase = constants.urlApi;
  int idClient = 0;
  String clientName = '';
  String description = '';
  bool isLoggedIn = true;
  dynamic userData = [];


  @override
  void initState() {
    super.initState();

    if(constants.isClientExclusive) {
      fetchUserData();
    }

    setState(() {
      clientName = widget.clientData![0]['fantasia'] ?? '';
      idClient = widget.clientData![0]['id_cliente'] ?? '';
      description = widget.clientData![0]['descricao'] ?? '';
    });

    
  }

  void fetchUserData() async {
    String id = await getIdUser();

    if (id == '') {
      setState(() {
        isLoggedIn = false;
      });
    } else {
      setState(() {
        isLoggedIn = true;
      });
      var data = await clientController.fetchUserData(id);
      setState(() {
        userData = data;
      });
    }

    print('User data fetched: $userData');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.network(
            '${urlBase}clients/getLogo/$idClient',
            width: 250,
            height: 200,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/logo-placeholder.png',
                width: 250,
                height: 200,
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  clientName,
                  textAlign: TextAlign.left,
                  style: GoogleFonts.indieFlower(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if(constants.isClientExclusive)
                if (isLoggedIn && userData.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Olá, ${userData[0]['nome_completo'].toString().split(' ')[0]}",
                        style: GoogleFonts.indieFlower(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Get.toNamed('/editProfile', arguments: userData);
                        },
                        child: const Icon(Icons.settings),
                      ),
                    ],
                  )
                else
                  TextButton(
                    onPressed: () => Get.toNamed('/login'),
                    child: Row(
                      children: [
                        Text(
                          'Login',
                          style: GoogleFonts.indieFlower(
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.login_sharp, color: Colors.white),
                      ],
                    ),
                  ),

            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              description,
              textAlign: TextAlign.left,
              style: GoogleFonts.indieFlower(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
