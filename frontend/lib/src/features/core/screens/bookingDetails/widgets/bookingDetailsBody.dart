import 'dart:async';

import 'package:clubedaareia/src/constants/colors.dart';
import 'package:clubedaareia/src/utils/getIdUser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../controllers/bookingController.dart';
import 'paymentModal.dart';

class BookingDetailsBody extends StatefulWidget {
  final DateTime date;
  final String local;
  final double basePrice;
  final List<String> selectedSlots;
  final dynamic courtData;
  final List materials;
  final List materialsIds;
  final List materialsPrices;
  final List materialsQuantities;
  final List paymentMethods;
  final List paymentConditions;
  final int idPlace;
  final int idModalityPlace;

  BookingDetailsBody(
      {required this.date,
      required this.local,
      required this.basePrice,
      required this.selectedSlots,
      required this.courtData,
      required this.materials,
      required this.materialsIds,
      required this.materialsPrices,
      required this.materialsQuantities,
      required this.paymentMethods,
      required this.paymentConditions,
      required this.idPlace,
      required this.idModalityPlace});

  @override
  _BookingDetailsBodyState createState() => _BookingDetailsBodyState();
}

class _BookingDetailsBodyState extends State<BookingDetailsBody> {
  //controllers
  final bookingController = Get.put(BookingController());
  //variables
  int _selectedPaymentOption = 0; // 1: full, 2: half, 3: full at location
  String selectedPaymentOptionName = '';
  int _selectedPaymentMethod =
      0; // 0: PIX app, 1: credit app, 2: PIX location, 3: credit location
  String _selectedPaymentMethodName = '';
  List<dynamic> filteredMethods = [];
  List<dynamic> conditions = [];

  List<String> selectedMaterials = [];
  double discount = 0.0;
  double totalValue = 0.0;
  dynamic courtData;
  String courtName = '';
  String clientName = '';
  bool isInitialized = false;

  //dados dos inputs
  TextEditingController observationController = TextEditingController();
  TextEditingController couponController = TextEditingController();
  TextEditingController cpfController = TextEditingController();
  final cpfKey = GlobalKey<FormState>();

  bool isTappedObservation = false;
  double rotationAngleObservation = 0.0;
  bool isTappedRepetition = false;
  double rotationAngleRepetition = 0.0;
  bool isTappedCoupon = false;
  double rotationAngleCoupon = 0.0;
  bool isTappedMaterials = false;
  double rotationAngleMaterials = 0.0;

  bool repetition = false;
  DateTime endRepetitionDate = DateTime.now();

  List<int> selectedMaterialsIds = [];
  List<bool> isMaterialSelected = [];

  List<Map<String, dynamic>> selectedMaterialsData = [];

  //tipo de usuário
  String userType = 'u';

  dynamic userData;

  @override
  void initState() {
    super.initState();
    setState(() {
      conditions = widget.paymentConditions;
    });
    setInitialCondition();
    fetchUserData();

    changePaymentMethodsList();
    setState(() {
      isMaterialSelected =
          List.generate(widget.materials.length, (index) => false);
    });

    setState(() {
      courtData = widget.courtData;
    });

    if (courtData != null) {
      setState(() {
        clientName = courtData['clientName'];
        courtName = courtData['courtName'];
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/home');
      });
    }

    calculateTotal();

    setState(() {
      isInitialized = true;
    });
  }

  Future<void> fetchUserData() async {
    final userID = await getIdUser();
    final response = await bookingController.fetchUserData(userID);
    setState(() {
      userData = response;
    });
  }

  void setInitialCondition() {
    if (conditions.isNotEmpty) {
      setState(() {
        _selectedPaymentOption = conditions[0]['id_condicao_pagamento'];
        selectedPaymentOptionName = conditions[0]['descricao'];
      });
    }
  }

  void validateCoupon() async {
    if (couponController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Preencha o cupom primeiro!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final response = await bookingController.validateCoupon(
          couponController.text, courtData['idClient']);

      if (response.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Cupom inválido, tente novamente!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ));
      } else {
        setDiscount(double.parse(response[0]['valor']));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Cupom aplicado com sucesso!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ));
      }
    }
  }

  void registerAgenda() async {
    for (var i = 0; i < widget.selectedSlots.length; ++i) {
      bool result = await bookingController.registerAgenda(
        int.parse(await getIdUser()),
        widget.idPlace,
        userType,
        widget.date,
        widget.selectedSlots[i],
        (widget.basePrice / widget.selectedSlots.length)
            .toString(), //valor de um slot
        observationController.text,
        repetition == false ? 0 : 1,
        endRepetitionDate,
        widget.idModalityPlace,
        selectedMaterialsData,
        _selectedPaymentMethod,
        _selectedPaymentOption,
      );
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Agenda registrada com sucesso!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Get.toNamed('/myAgenda');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro ao registrar agenda"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  //aplica desconto de cupom
  void setDiscount(double discountValue) {
    setState(() {
      discount = discountValue;
      calculateTotal();
    });
  }

  //filtra métodos de pagamento
  void changePaymentMethodsList() {
    if (_selectedPaymentOption == 1 || _selectedPaymentOption == 2) {
      filteredMethods = widget.paymentMethods
          .where((method) => method['descricao'].contains("no App"))
          .toList();
    } else if (_selectedPaymentOption == 3) {
      filteredMethods = widget.paymentMethods
          .where((method) => method['descricao'].contains("na Arena"))
          .toList();
    }
    setState(() {
      _selectedPaymentMethod = 0;
      _selectedPaymentMethodName = '';
    });
  }

  void openModalRegisterCpf(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finalize o cadastro com o CPF para pagar',
                      style: GoogleFonts.indieFlower(
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: cpfKey,
                      child: TextFormField(
                        controller: cpfController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe o seu CPF';
                          }
                          if (value.length < 10) {
                            return 'CPF inválido';
                          }
                          return null;
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        ],
                        keyboardType: TextInputType.number,
                        maxLength: 11,
                        decoration: const InputDecoration(
                          hintText: "Insira seu CPF para continuar",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botão que preenche totalmente a parte de baixo do modal
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: globalPrimaryColor,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () async {
                    bool response = false;
                    if (cpfKey.currentState!.validate()) {
                      response = await registerCpf();
                      if (response) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("CPF cadastrado com sucesso!"),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        //Navigator.of(context).pop();
                        registerCompra();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Erro ao cadastrar CPF!"),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text(
                    'Cadastrar CPF',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> registerCpf() async {
    return await bookingController.registerCpf(
        await getIdUser(), cpfController.text);
  }

  //verifica se cpf está cadastrado para aquele usuario
  Future<bool> verifyCpf() async {
    return await bookingController.isCpfRegistered(await getIdUser());
  }

  void openModalRegisterCompra(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: Text(
            'Confirmar Compra',
            style: GoogleFonts.indieFlower(
              textStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Área de conteúdo com os dados do agendamento
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dados do agendamento:',
                      style: GoogleFonts.indieFlower(
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            color:
                                Colors.black), // Cor padrão para todo o texto
                        children: [
                          const TextSpan(
                            text: "Data: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: DateFormat(
                                    "EEEE, d 'de' MMMM 'de' yyyy", 'pt_BR')
                                .format(widget.date),
                            style:
                                const TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    if (widget.selectedSlots.isNotEmpty)
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black),
                          children: [
                            const TextSpan(
                              text: "Horários Selecionados: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: widget.selectedSlots.join(', '),
                              style: const TextStyle(
                                  fontWeight: FontWeight.normal),
                            ),
                          ],
                        ),
                      ),
                    if (widget.selectedSlots.isNotEmpty)
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black),
                          children: [
                            const TextSpan(
                              text: "Preço por Horário: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  "${(widget.basePrice / widget.selectedSlots.length).toStringAsFixed(2)}R\$",
                              style: const TextStyle(
                                  fontWeight: FontWeight.normal),
                            ),
                          ],
                        ),
                      ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black),
                        children: [
                          const TextSpan(
                            text: "Preço Total: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text:
                                "${calculateTotalPrice(totalValue).toStringAsFixed(2)}R\$",
                            style:
                                const TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    if (observationController.text.isNotEmpty)
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black),
                          children: [
                            const TextSpan(
                              text: "Observação: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: observationController.text,
                              style: const TextStyle(
                                  fontWeight: FontWeight.normal),
                            ),
                          ],
                        ),
                      ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black),
                        children: [
                          const TextSpan(
                            text: "Repetição: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: repetition ? 'Sim' : 'Não',
                            style:
                                const TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    if (selectedMaterialsIds.isNotEmpty)
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black),
                          children: [
                            const TextSpan(
                              text: "Materiais Selecionados: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: selectedMaterials.join(', '),
                              style: const TextStyle(
                                  fontWeight: FontWeight.normal),
                            ),
                          ],
                        ),
                      ),
                    if (_selectedPaymentMethodName.isNotEmpty)
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black),
                          children: [
                            const TextSpan(
                              text: "Forma de Pagamento: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: _selectedPaymentMethodName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.normal),
                            ),
                          ],
                        ),
                      ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black),
                        children: [
                          const TextSpan(
                            text: "Opção de Pagamento: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: selectedPaymentOptionName,
                            style:
                                const TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Botão que preenche toda a parte de baixo do modal
              Container(
                height: 60,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: globalPrimaryColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                  ),
                  onPressed: () async {
                    bool response = await verifyCpf();
                    if (response) {
                      Navigator.of(context).pop();

                      registerCompra();
                    } else {
                      Navigator.of(context).pop();
                      openModalRegisterCpf(context);
                    }
                  },
                  child: const Text(
                    'Gerar Cobrança',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //verifica pagamento/expiração do pix periodicamente
  void checkPix(int id_compra) async {
    var pix = await bookingController.checkPix(id_compra);
  }

  void openModalPayment(BuildContext context, dynamic pix, int idCompra) {
    showDialog(
      context: context,
      builder: (_) => PaymentModal(
        pix: pix,
        idCompra: idCompra,
        idClient: courtData['idClient'].toString(),
        cellphone: userData[0]['celular'].toString()
      ),
    );
  }

  void registerCompra() async {
    //método de pix
    if (_selectedPaymentMethod == 2) {
      var horarioList = [];
      for (var i = 0; i < widget.selectedSlots.length; ++i) {
        horarioList.add({
          'repeticao': repetition,
          'data_fim': endRepetitionDate.toString().substring(0, 10),
          'id_horario_carrinho': '',
          'id_horario': '',
          'id_espaco': widget.idPlace,
          'inicio': widget.selectedSlots[i].substring(0, 5),
          'final': widget.selectedSlots[i].substring(8, 13),
          'data': widget.date.toString().substring(0, 10),
          'valor': (widget.basePrice / widget.selectedSlots.length).toString(),
          'valor_base':
              (widget.basePrice / widget.selectedSlots.length).toString(),
          'observacao': observationController.text,
          'id_modalidade_espaco': widget.idModalityPlace,
          'material_list': selectedMaterialsData,
          'id_forma_pagamento': _selectedPaymentMethod,
          'id_condicao_pagamento': _selectedPaymentOption,
        });
      }

      dynamic result = await bookingController.registerCompra(
        int.parse(await getIdUser()),
        userType,
        totalValue.toString(),
        horarioList,
        courtData['idClient'],
        _selectedPaymentOption, //tipo pagamento, 1: full, 2: half
      );

      //print(result['msg']);

      if (result['err'] == null || result['err'] == false) {
        dynamic pix = await bookingController.viewPix(result['id_compra']);

        //envia pix por whatsapp
        await bookingController.sendPixCodeWhatsApp(
            courtData['idClient'].toString(),
            userData[0]['celular'].toString(),
            pix['texto_qr_code'].toString(),
            result['id_compra']
        );

        //abre modal de pagamento
        openModalPayment(context, pix, result['id_compra']);
      } else if (result['msg'] == 'Banco não existente!') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Arena não está aceitando pagamentos no momento"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Um ou mais horários já ocupados, tente novamente"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      //implementar demais métodos
    } else if (_selectedPaymentMethod == 1 || //PIX NA ARENA
            _selectedPaymentMethod == 3 || //CARTÃO NA ARENA
            _selectedPaymentMethod == 5 //DINHEIRO NA ARENA
        ) {
      registerAgenda();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Método de pagamento não implementado"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  double calculateTotalPrice(double totalValue) {
    // 1: full, 2: half, 3: full at location

    if (_selectedPaymentOption == 2) {
      return totalValue / 2;
    } else if (_selectedPaymentOption == 3) {
      return 0;
    }

    return totalValue;
  }

  //recalcula valor total a cada alteração
  void calculateTotal() {
    print('calculate total chamado');
    print(selectedMaterialsData);
    //calcula quantas semanas de repetição
    Duration diferenca = endRepetitionDate.difference(widget.date);
    int semanas = ((diferenca.inDays + 1) ~/ 7);
    semanas = semanas + 1;
    if (semanas <= 0) {
      semanas = 1;
    }

    double subtotal = widget.basePrice;
    double totalMaterialsValue = 0.0;

    //faz desconto de cupons
    subtotal -= discount;

    //faz adição materiais
    for (var i = 0; i < selectedMaterialsData.length; ++i) {
      totalMaterialsValue +=
          double.parse(selectedMaterialsData[i]['valor_unidade']) *
              selectedMaterialsData[i]['quantidade'];
    }

    subtotal += totalMaterialsValue;

    setState(() {
      totalValue = subtotal * semanas;
    });
  }

  void toggleMaterial(String material) {
    setState(() {
      if (selectedMaterials.contains(material)) {
        selectedMaterials.remove(material);
      } else {
        selectedMaterials.add(material);
      }
      calculateTotal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return isInitialized
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dados do Agendamento',
                      style: GoogleFonts.indieFlower(
                        textStyle: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Horário(s):',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(widget.selectedSlots.join("\n")),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: Colors.grey,
                margin: const EdgeInsets.symmetric(vertical: 10),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Data: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      DateFormat("EEEE, d 'de' MMMM 'de' yyyy", 'pt_BR')
                          .format(widget.date),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: Colors.grey,
                margin: const EdgeInsets.symmetric(vertical: 10),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Local: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$clientName'),
                        Text('$courtName'),
                        Text(
                          widget.local,
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isTappedObservation = !isTappedObservation;
                      rotationAngleObservation =
                          isTappedObservation ? 0.5 : 0.0;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 15),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isTappedObservation
                          ? [
                              const BoxShadow(
                                  color: Colors.black26, blurRadius: 4)
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Alguma observação?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: globalPrimaryColor,
                                ),
                              ),
                              if (isTappedObservation)
                                TextField(
                                  controller: observationController,
                                  decoration: const InputDecoration(
                                    hintText: 'Digite aqui...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns:
                              rotationAngleObservation, // A animação de rotação
                          duration: const Duration(
                              milliseconds: 300), // Duração da animação
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: globalPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isTappedRepetition = !isTappedRepetition;
                      rotationAngleRepetition = isTappedRepetition
                          ? 0.5
                          : 0.0; // 0.5 é equivalente a 180 graus
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 15),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isTappedRepetition
                          ? [
                              const BoxShadow(
                                  color: Colors.black26, blurRadius: 4)
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: isTappedRepetition
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Repetir Semanalmente',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: globalPrimaryColor,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: repetition,
                                          onChanged: (value) {
                                            setState(() {
                                              repetition = value ?? false;
                                              if (repetition == false) {
                                                endRepetitionDate =
                                                    DateTime.now();
                                              }
                                            });
                                          },
                                        ),
                                        const Text(
                                          'Sim, até',
                                          style: TextStyle(
                                            //fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextButton(
                                            onPressed: repetition
                                                ? () async {
                                                    final pickedDate =
                                                        await showDatePicker(
                                                      context: context,
                                                      initialDate:
                                                          endRepetitionDate,
                                                      firstDate: DateTime.now(),
                                                      lastDate: DateTime(2100),
                                                    );
                                                    if (pickedDate != null) {
                                                      setState(() {
                                                        endRepetitionDate =
                                                            pickedDate;
                                                      });
                                                    }
                                                    calculateTotal();
                                                  }
                                                : null,
                                            child: Text(
                                              '${endRepetitionDate.day}/${endRepetitionDate.month}/${endRepetitionDate.year}',
                                              style: TextStyle(
                                                color: repetition
                                                    ? globalPrimaryColor
                                                    : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Repetir Semanalmente',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: globalPrimaryColor,
                                  ),
                                ),
                        ),
                        AnimatedRotation(
                          turns: rotationAngleRepetition,
                          duration: const Duration(milliseconds: 300),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: globalPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isTappedCoupon = !isTappedCoupon;
                      rotationAngleCoupon = isTappedCoupon ? 0.5 : 0.0;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 15),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isTappedCoupon
                          ? [
                              const BoxShadow(
                                  color: Colors.black26, blurRadius: 4)
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Possui Cupom de Desconto?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: globalPrimaryColor,
                                ),
                              ),
                              if (isTappedCoupon)
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: couponController,
                                        decoration: const InputDecoration(
                                          hintText: 'Digite aqui...',
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: validateCoupon,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: globalPrimaryColor,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 16,
                                        ),
                                      ),
                                      child: const Text(
                                        'Validar',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    const Padding(
                                        padding: EdgeInsets.only(right: 20))
                                  ],
                                ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: rotationAngleCoupon,
                          duration: const Duration(milliseconds: 300),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: globalPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

/*
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isTappedMaterials = !isTappedMaterials;
                      rotationAngleMaterials = isTappedMaterials
                          ? 0.5
                          : 0.0; // 0.5 representa 180 graus
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 15),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: isTappedMaterials
                          ? Colors.grey[100]
                          : Colors.grey[100],
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isTappedMaterials
                          ? [
                              const BoxShadow(
                                  color: Colors.black26, blurRadius: 4)
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                "Adicionar materiais (raquete, bola..)?",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              turns: rotationAngleMaterials,
                              duration: const Duration(milliseconds: 300),
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        if (isTappedMaterials)
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: widget.materials.length,
                            itemBuilder: (context, index) {
                              return CheckboxListTile(
                                title: Text(widget.materials[index]),
                                value: isMaterialSelected[index],
                                onChanged: (bool? value) {
                                  setState(() {
                                    isMaterialSelected[index] = value ?? false;
                                    if (isMaterialSelected[index] == true) {
                                      selectedMaterialsIds
                                          .add(widget.materialsIds[index]);
                                      selectedMaterials
                                          .add(widget.materials[index]);
                                    } else {
                                      selectedMaterialsIds
                                          .remove(widget.materialsIds[index]);
                                      selectedMaterials
                                          .remove(widget.materials[index]);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
*/

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isTappedMaterials = !isTappedMaterials;
                      rotationAngleMaterials = isTappedMaterials
                          ? 0.5
                          : 0.0; // 0.5 representa 180 graus
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 15),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isTappedMaterials
                          ? [
                              const BoxShadow(
                                  color: Colors.black26, blurRadius: 4)
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                "Adicionar materiais (raquete, bola..)?",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: globalPrimaryColor,
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              turns: rotationAngleMaterials,
                              duration: const Duration(milliseconds: 300),
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: globalPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        if (isTappedMaterials)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.materials.length,
                            itemBuilder: (context, index) {
                              // Verifica se o material já foi adicionado, senão assume quantidade 1
                              int currentQuantity =
                                  selectedMaterialsData.firstWhere(
                                (element) =>
                                    element['id_material'] ==
                                    widget.materialsIds[index],
                                orElse: () => {'quantidade': 1}, // Começa com 1
                              )['quantidade'];

                              return ListTile(
                                leading: Checkbox(
                                  value: isMaterialSelected[index],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      isMaterialSelected[index] =
                                          value ?? false;
                                      if (isMaterialSelected[index]) {
                                        // Adiciona o material com quantidade inicial 1 se ainda não estiver na lista
                                        if (!selectedMaterialsData.any(
                                            (element) =>
                                                element['id_material'] ==
                                                widget.materialsIds[index])) {
                                          selectedMaterialsData.add({
                                            'id_material':
                                                widget.materialsIds[index],
                                            'quantidade': 1,
                                            'valor_unidade':
                                                widget.materialsPrices[index]
                                          });
                                        }
                                      } else {
                                        // Remove o material da lista ao desmarcar
                                        selectedMaterialsData.removeWhere(
                                            (element) =>
                                                element['id_material'] ==
                                                widget.materialsIds[index]);
                                      }
                                    });
                                    calculateTotal();
                                  },
                                ),
                                title: Text(widget.materials[index]),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      color: Colors.blue,
                                      onPressed: isMaterialSelected[index] &&
                                              currentQuantity > 1
                                          ? () {
                                              setState(() {
                                                final materialData =
                                                    selectedMaterialsData
                                                        .firstWhere(
                                                  (element) =>
                                                      element['id_material'] ==
                                                      widget
                                                          .materialsIds[index],
                                                );
                                                if (materialData['quantidade'] >
                                                    1) {
                                                  materialData['quantidade']--;
                                                }
                                              });
                                              calculateTotal();
                                            }
                                          : null,
                                    ),
                                    Text(currentQuantity.toString()),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      color: Colors.blue,
                                      onPressed: isMaterialSelected[index] &&
                                              currentQuantity <
                                                  widget.materialsQuantities[
                                                      index]
                                          ? () {
                                              setState(() {
                                                final materialData =
                                                    selectedMaterialsData
                                                        .firstWhere(
                                                  (element) =>
                                                      element['id_material'] ==
                                                      widget
                                                          .materialsIds[index],
                                                );
                                                materialData['quantidade']++;
                                              });
                                              calculateTotal();
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Como você quer pagar?',
                      style: GoogleFonts.indieFlower(
                        textStyle: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    conditions.isNotEmpty
                        ? Column(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                color: Colors.white,
                                child: Column(
                                  children: conditions.map<Widget>((condition) {
                                    return ListTile(
                                      title: Text(condition['descricao']),
                                      leading: _selectedPaymentOption ==
                                              condition['id_condicao_pagamento']
                                          ? const Icon(Icons.check,
                                              color: Colors.green)
                                          : Container(width: 24),
                                      onTap: () {
                                        setState(() {
                                          _selectedPaymentOption = condition[
                                              'id_condicao_pagamento'];
                                          selectedPaymentOptionName =
                                              condition['descricao'];
                                        });
                                        changePaymentMethodsList();
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          )
                        : Card(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 5),
                            elevation: 3,
                            child: Stack(
                              children: [
                                const SizedBox(
                                  height: 20,
                                ),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/images/vazio.png',
                                        width: 100,
                                        fit: BoxFit.cover,
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Nenhuma opção encontrada',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        conditions.isNotEmpty
                            ? Text(
                                'Qual a forma de pagamento?',
                                style: GoogleFonts.indieFlower(
                                  textStyle: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              )
                            : Container(),
                            const SizedBox(height: 10),
                            ...filteredMethods.map<Widget>((method) {
                              return filteredMethods.isNotEmpty
                                  ? Container(
                                      color: Colors.white,
                                      padding: const EdgeInsets.only(
                                          top: 5, bottom: 5, ),
                                      child: ListTile(
                                        title: Text(
                                          method['descricao'],
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        leading: _selectedPaymentMethod ==
                                        method['id_forma_pagamento']
                                              ? const Icon(Icons.check, color: Colors.green)
                                              : Container(width: 24),
                                          onTap: () {
                                            setState(() {
                                              _selectedPaymentMethodName = method['descricao'];
                                              _selectedPaymentMethod = method['id_forma_pagamento'];
                                            });
                                          },
                                      ),

                                  
                                  
                                  /*RadioListTile<int>(
                                    title: Text(
                                      method['descricao'],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    value: method['id_forma_pagamento'],
                                    groupValue: _selectedPaymentMethod,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPaymentMethodName =
                                            method['descricao'];
                                        _selectedPaymentMethod = value!;
                                      });
                                    },
                                    controlAffinity:
                                        ListTileControlAffinity.trailing,
                                  ),*/
                                )
                              : Card(
                                  color: Colors.white,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 5),
                                  elevation: 3,
                                  child: Stack(
                                    children: [
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Image.asset(
                                              'assets/images/vazio.png',
                                              width: 100,
                                              fit: BoxFit.cover,
                                            ),
                                            const SizedBox(height: 10),
                                            const Text(
                                              'Nenhuma opção encontrada',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                        }).toList(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Resumo dos valores',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Subtotal: R\$${widget.basePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      height: 1,
                      color: Colors.grey,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Você irá pagar',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'R\$ ${totalValue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Ao confirmar, você concorda as',
                      style: TextStyle(fontSize: 10),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        // Open terms and conditions
                      },
                      child: const Text(
                        ' regras de cancelamento.',
                        style: TextStyle(
                          color: globalPrimaryColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Confirm button
              Container(
                height: 60,
                padding: const EdgeInsets.all(0),
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: globalPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  onPressed: () {
                    if (_selectedPaymentMethod != 0) {
                      openModalRegisterCompra(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Escolha a forma de pagamento"),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'AGENDAR HORÁRIO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              //SizedBox(height: 5),
            ],
          )
        : Center(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
  }
}
