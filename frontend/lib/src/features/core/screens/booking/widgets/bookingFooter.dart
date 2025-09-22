import 'dart:convert';

import 'package:clubedaareia/src/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../utils/getIdUser.dart';
import '../../../controllers/bookingController.dart';

class BookingFooter extends StatefulWidget {
  final List<String> selectedSlots;
  final dynamic courtData;
  final DateTime date;
  final double totalPrice;
  final int idPlace;
  final int idModalityPlace;
  final dynamic allModalitiesIds;

  BookingFooter(
      {super.key,
      required this.selectedSlots,
      required this.courtData,
      required this.date,
      required this.totalPrice,
      required this.idPlace,
      required this.idModalityPlace,
      required this.allModalitiesIds});

  @override
  State<BookingFooter> createState() => _BookingFooterState();
}

class _BookingFooterState extends State<BookingFooter> {
  //controllers
  final bookingController = Get.put(BookingController());
  //variables
  List<dynamic> materialsNames = [];
  List<dynamic> materialsIds = [];
  List<dynamic> materialsPrices = [];
  List<dynamic> materialsQuantities = [];
  List<dynamic> paymentMethodsNames = [];
  List<dynamic> paymentConditionsNames = [];

  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    verifyLogged();
    fetchMaterials();
    fetchPaymentMethods();
    fetchPaymentConditions();
  }

  Future<void> verifyLogged() async {

    print('TO LOGADO? ');
    String id = await getIdUser();
    setState(() {
      isLoggedIn = id != '';
    });

    print(isLoggedIn);
  }

  Future<void> fetchMaterials() async {
    for (int i = 0; i < widget.allModalitiesIds.length; ++i) {
      final response =
          await bookingController.fetchMaterials(widget.allModalitiesIds[i]);
      setState(() {
        for (var i = 0; i < response.length; ++i) {
          materialsNames.add(response[i]['nome'].toString());
          materialsPrices.add(response[i]['valor']);
          materialsIds.add(response[i]['id_material']);
          materialsQuantities.add(response[i]['quantidade']);
        }
      });
    }
  }

  Future<void> fetchPaymentMethods() async {
    final response = await bookingController
        .fetchPaymentMethods(widget.courtData['idClient']);

    setState(() {
      paymentMethodsNames = response;
    });
  }

  Future<void> fetchPaymentConditions() async {
    final response = await bookingController
        .fetchPaymentConditions(widget.courtData['idClient']);

    setState(() {
      paymentConditionsNames = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    //final DateTime date = DateTime.now();
    final String local =
        '${widget.courtData['clientAddress']}\n${widget.courtData['clientCep']}';
    final List materials = materialsNames;
    final List paymentsMethods = paymentMethodsNames;
    final List paymentConditions = paymentConditionsNames;
    final double basePrice = widget.totalPrice;

    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        Container(
          color: globalPrimaryColor,
          padding: EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${widget.selectedSlots.length} HORÁRIO(S) SELECIONADO(S)",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () async {
                  if (widget.selectedSlots.isEmpty) {
                    Future.delayed(Duration.zero, () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Selecione os horários"),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    });
                  } else {
                    await verifyLogged();
                    if (!isLoggedIn)  {
                      // Salvar os dados no localStorage
                      final bookingData = {
                        'date': widget.date.toIso8601String(),
                        'local': local,
                        'materials': materials,
                        'materialsIds': materialsIds,
                        'materialsPrices': materialsPrices,
                        'materialsQuantities': materialsQuantities,
                        'basePrice': basePrice,
                        'selectedSlots': widget.selectedSlots,
                        'courtData': widget.courtData,
                        'paymentMethods': paymentsMethods,
                        'paymentConditions': paymentConditions,
                        'idPlace': widget.idPlace,
                        'idModalityPlace': widget.idModalityPlace,
                      };

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('pendingBooking', jsonEncode(bookingData));

                      // Vai pro login
                      Get.toNamed('/login');
                    } else {
                      // Já logado, segue pro pagamento
                      Get.toNamed('/bookingDetails', arguments: {
                        'date': widget.date,
                        'local': local,
                        'materials': materials,
                        'materialsIds': materialsIds,
                        'materialsPrices': materialsPrices,
                        'materialsQuantities': materialsQuantities,
                        'basePrice': basePrice,
                        'selectedSlots': widget.selectedSlots,
                        'courtData': widget.courtData,
                        'paymentMethods': paymentsMethods,
                        'paymentConditions': paymentConditions,
                        'idPlace': widget.idPlace,
                        'idModalityPlace': widget.idModalityPlace,
                      });
                    }
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8), 
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white, 
                      ),
                      child: SvgPicture.asset(
                        'assets/icons/agenda.svg',
                        width: 25,
                        colorFilter: const ColorFilter.mode(
                          Colors.black,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
