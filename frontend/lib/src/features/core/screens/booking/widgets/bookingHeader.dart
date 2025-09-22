import 'package:clubedaareia/src/constants/colors.dart';
import 'package:clubedaareia/src/features/core/screens/booking/widgets/modalDoubt.dart';
import 'package:clubedaareia/src/features/core/screens/booking/widgets/modalMoney.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../constants/colors.dart';
import '../../../../../utils/getIdUser.dart';
import '../../../controllers/clientController.dart';

class BookingHeader extends StatefulWidget {
  final dynamic courtData;
  final VoidCallback? onSharePressed;

  @override
  const BookingHeader({
    super.key,
    this.courtData,
    this.onSharePressed,
  });

  _BookingHeaderState createState() => _BookingHeaderState();
}

class _BookingHeaderState extends State<BookingHeader> {
  dynamic courtData = [];
  String courtName = '';
  bool isLoggedIn = false;
  List<Map<String, dynamic>> allCourtsData = [];
  int idClient = 0;
  dynamic clientData = [];

  //controllers
  final clientController = Get.put(ClientController());

  @override
  void initState() {
    super.initState();
    verifyLogged();
    setState(() {
      courtData = widget.courtData;
      idClient = courtData['idClient'];
    });
    //print(courtData);
    if (courtData != null) {
      setState(() {
        courtName = courtData['courtName'];
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/home');
      });
    }
    fetchCourtsData();
    fetchClientData();
  }

  Future<void> verifyLogged() async{
    String id = await getIdUser();
    setState(() {
      isLoggedIn = id != '';
    });
  }

  Future<void> fetchCourtsData() async {
    final response = await clientController.fetchCourts(idClient);

    setState(() {
      allCourtsData =
          (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  Future<void> fetchClientData() async {
    var response = await clientController.fetchClientData(idClient);
    setState(() {
      clientData =
          (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
    });

    //print('dados do cliente no header: $clientData');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 35, left: 15),
      child: Row(
        children: [
          isLoggedIn
              ? IconButton(
                  icon: Icon(Icons.arrow_circle_left_outlined),
                  hoverColor: globalPrimaryColor,
                  onPressed: () {
                    Get.back();
                  },
                )
              : IconButton(
                  icon: Icon(Icons.arrow_circle_left_outlined),
                  hoverColor: globalPrimaryColor,
                  onPressed: () {
                    Get.toNamed('/login');
                  },
                ),
          const SizedBox(width: 5),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _showCourtMenu(context, allCourtsData,
                      clientData), 
                  child: Text(
                    courtName,
                    style: GoogleFonts.indieFlower(
                      textStyle: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showCourtMenu(context, allCourtsData,
                      clientData), // Também abre ao clicar no ícone
                  child: const Icon(
                    Icons.arrow_drop_down,
                    size: 28,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            hoverColor: globalPrimaryColor,
            onPressed: widget.onSharePressed,
          ),
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.black),
            hoverColor: globalPrimaryColor,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ModalDoubt();
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.attach_money, color: Colors.black),
            hoverColor: globalPrimaryColor,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ModalMoney(idClient: courtData['idClient']);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

void _showCourtMenu(BuildContext context,
    List<Map<String, dynamic>> allCourtsData, dynamic clientData) {
  final uniqueCourts = {
    for (var court in allCourtsData) court['id_espaco']: court['nome']
  };

  //print('dados cliente: $clientData');

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text(
            "Selecione uma Quadra",
            style: GoogleFonts.indieFlower(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: uniqueCourts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final idEspaco = uniqueCourts.keys.elementAt(index);
                final nomeQuadra = uniqueCourts.values.elementAt(index);

                return ListTile(
                  leading: const Icon(Icons.stadium, color: globalPrimaryColor),
                  title: Text(
                    nomeQuadra,
                    style: GoogleFonts.indieFlower(
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    final selectedItems = allCourtsData
                        .where((court) => court['id_espaco'] == idEspaco)
                        .toList();

                    Navigator.pushReplacementNamed(
                      context,
                      '/booking',
                      arguments: {
                        'clientName': clientData[0]['fantasia'],
                        'courtName': selectedItems[0]['nome'],
                        'courtId': selectedItems[0]['id_espaco'],
                        'idClient': clientData[0]['id_cliente'],
                        'clientAddress': clientData[0]['endereco'],
                        'clientCep': clientData[0]['cep'],
                        'courtModality': selectedItems[0]['nome_modalidade'],
                        'courtsModalityId': selectedItems[0]
                            ['id_modalidade_espaco'],
                        'allModalitiesIds': selectedItems[0]
                            ['id_modalidade_espaco'],
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

