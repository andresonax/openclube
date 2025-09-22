import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers/bookingController.dart';

class ModalMoney extends StatefulWidget {
  final int idClient;
  const ModalMoney({super.key, required this.idClient});

  @override
  State<ModalMoney> createState() => _ModalMoneyState();
}

class _ModalMoneyState extends State<ModalMoney> {
  final bookingController = Get.put(BookingController());

  List<dynamic> paymentMethodsNames = [];
  List<dynamic> paymentConditionsNames = [];

  @override
  void initState() {
    super.initState();
    fetchPaymentMethods();
    fetchPaymentConditions();
  }

  Future<void> fetchPaymentMethods() async {
    final response =
        await bookingController.fetchPaymentMethods(widget.idClient);
    setState(() {
      paymentMethodsNames = response;
    });
  }

  Future<void> fetchPaymentConditions() async {
    final response =
        await bookingController.fetchPaymentConditions(widget.idClient);
    setState(() {
      paymentConditionsNames = response;
    });
  }

  Widget _getPaymentIcon(String descricao) {
    if (descricao.contains('Pix')) {
      return Image.asset('assets/icons/pix.png', width: 20);
    } else if (descricao.contains('Dinheiro')) {
      return const Icon(Icons.attach_money, size: 20, color: Colors.green);
    } else if (descricao.contains('Cartão')) {
      return const Icon(Icons.credit_card, size: 20, color: Colors.blue);
    } else {
      return const CircleAvatar(
        radius: 12,
        backgroundColor: Color.fromARGB(255, 133, 112, 228),
        child: Text('P', style: TextStyle(color: Colors.white, fontSize: 16)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          
          'Formas e Condições de Pagamento',
          textAlign: TextAlign.center,
          style: GoogleFonts.indieFlower(
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 23,
            ),
          ),
        ),
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Formas de pagamento
              if (paymentMethodsNames.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Formas de Pagamento:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                ...paymentMethodsNames.map((item) {
                  return ListTile(
                    leading: _getPaymentIcon(item['descricao']),
                    title: Text(item['descricao']),
                  );
                }).toList(),
              ],

              const SizedBox(height: 20),

              // Condições de pagamento
              if (paymentConditionsNames.isNotEmpty) ...[   
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Condições de Pagamento:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                ...paymentConditionsNames.map((item) {
                  return ListTile(
                    title: Row(
                      children: [
                        const CircleAvatar(
                          radius: 12,
                          backgroundColor: Color.fromARGB(255, 133, 112, 228),
                          child: Text('P', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(item['descricao_long'])),
                      ],
                    ),
                  );
                }).toList(),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
