import 'dart:io';
import 'dart:typed_data';

import 'package:clubedaareia/src/constants/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdfx/pdfx.dart'; 
import 'package:http/http.dart' as http;

import '../../../../common_widgets/bottomMenu/bottomNavBar.dart';
import '../../../../common_widgets/bottomMenu/topNavBar.dart';
import '../../../../constants/bottomNavBarMenuEnum.dart';
import '../../../../constants/constants.dart';
import '../../../../utils/getIdUser.dart';
import '../../../../utils/loading.dart';
import '../../controllers/myAgendaController.dart';
import 'package:intl/intl.dart'; // para formatar a data


import 'package:dio/dio.dart';

import '../../../../utils/savePDF/savePDFError.dart'
    if (dart.library.html) '../../../../utils/savePDF/savePDFWeb.dart'
    if (dart.library.io) '../../../../utils/savePDF/savePDFMobile.dart';




class MyAgenda extends StatefulWidget {
  const MyAgenda({super.key});

  @override
  State<MyAgenda> createState() => _MyAgendaState();
}

class _MyAgendaState extends State<MyAgenda> {
  //controllers
  final myAgendaController = Get.put(MyAgendaController());

  //variáveis
  bool hoverVoltar = false;
  bool isLogged = false;
  String idUser = '';
  List<dynamic> agenda = [];
  List<dynamic> filteredAgenda = [];
  bool isInitialized = false;
  var urlBase = constants.urlApi;

  DateTime? selectedDate;
  final dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    idUser = await getIdUser();
    if (idUser != '') {
      setState(() {
        isLogged = true;
      });
    }

    final response = await myAgendaController.fetchAgenda(idUser);

    setState(() {
      agenda = response;
      filteredAgenda = response;
      isInitialized = true;
    });
  }

  void filterAgendaByDate(DateTime date) {
    final formatted = dateFormat.format(date);
    setState(() {
      selectedDate = date;
      filteredAgenda = agenda.where((item) {
        final itemDate = dateFormat.format(DateTime.parse(item['data_agenda']));
        return itemDate == formatted;
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      filterAgendaByDate(picked);
    }
  }

  void openComprovante(int idAgenda, int idCliente) async {
    //busca dados de compra desse agendamento
    dynamic compra = await getDataCompra(idAgenda);
    dynamic comprovante = await getComprovante(compra['id_compra'], idCliente);
    String url =
        '${urlBase}locacao/compra/comprovante/open/${compra['id_compra']}';

    String situacao = compra['situacao'];
    if (comprovante != null && comprovante['path'] != null) {
      final pdfController = PdfController(
        document: PdfDocument.openData(
          await _loadPdfFromNetwork(
            url,
          ),
        ),
      );

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return ClipRect(
                        child: OverflowBox(
                          minWidth: 0,
                          maxWidth: MediaQuery.of(context).size.width * 2,
                          child: Center(
                            child: InteractiveViewer(
                              child: PdfView(
                                controller: pdfController,
                                scrollDirection: Axis.vertical,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Linha preta separadora
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  height: 1,
                  color: Colors.black,
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // Botão de Download
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.download, color: Colors.black),
                          label: const Text(
                            "Baixar Comprovante",
                            style: TextStyle(color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            side: const BorderSide(
                                color: Colors.black12, width: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 4,
                            shadowColor: Colors.black26,
                          ),
                          onPressed: () =>
                              downloadPdf(url, 'comprovante', context),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: situacao == 'ng'
                                ? Colors.red[100]
                                : situacao == 'pp'
                                    ? Colors.yellow[100]
                                    : Colors.green[100],
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            situacao == 'ng' || situacao == 'ge'
                                ? 'Não pago'
                                : situacao == 'pp'
                                    ? 'Metade paga'
                                    : 'Pago',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: situacao == 'ng' || situacao == 'ge'
                                  ? Colors.red[800]
                                  : situacao == 'pp'
                                      ? Colors.orange[800]
                                      : Colors.green[800],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    } else {
      print('Erro: Caminho do comprovante não encontrado.');
    }
  }

  Future<void> downloadPdf(String url, String fileName, BuildContext context) async {
    final response = await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    //usado pra diferenciar save do pdf no web e mobile
    savePDFImplementation(response.data!, fileName);
  }

  Future<Uint8List> _loadPdfFromNetwork(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Erro ao carregar PDF: ${response.statusCode}');
    }
  }

  Future<dynamic> getDataCompra(int idAgenda) async {
    dynamic response = await myAgendaController.getDataCompra(idAgenda);
    return response;
  }

  Future<dynamic> getComprovante(int idCompra, int idCliente) async {
    dynamic response =
        await myAgendaController.getComprovante(idCompra, idCliente);
    return response;
  }

  void showLegendaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 8, 0),
        contentPadding: const EdgeInsets.all(24),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Legenda das Cores',
                style: GoogleFonts.indieFlower(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendaItem(
              color: Colors.green.shade200,
              text: 'Pagamento 100% feito no App',
            ),
            const SizedBox(height: 10),
            _buildLegendaItem(
              color: Colors.yellow.shade200,
              text: 'Pagamento parcial no App',
            ),
            const SizedBox(height: 10),
            _buildLegendaItem(
              color: Colors.red.shade200,
              text: 'Pagamento será feito no local',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendaItem({required Color color, required String text}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isInitialized
          ? Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/background.jpeg"),
                  fit: BoxFit.fill,
                ),
              ),
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  Row(
                    children: [
                      const TopNavBar(route: '/home', backButtonText: 'Voltar'),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(top: 35, right: 10),
                        child: IconButton(
                          icon: const Icon(Icons.help_outline,
                              color: Colors.black),
                          hoverColor: globalPrimaryColor,
                          onPressed: () {
                            showLegendaDialog(context);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Expanded(
                    child: Center(
                      child: isLogged
                          ? Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: globalPrimaryColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        spreadRadius: 2,
                                        blurRadius: 8,
                                        offset: const Offset(
                                            0, 4), // deslocamento da sombra
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          DateTime? pickedDate =
                                              await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime(2100),
                                            builder: (BuildContext context,
                                                Widget? child) {
                                              return Theme(
                                                data:
                                                    Theme.of(context).copyWith(
                                                  colorScheme:
                                                      const ColorScheme.light(
                                                    primary: globalPrimaryColor,
                                                    onPrimary: Colors.white,
                                                    onSurface: Colors.black,
                                                  ),
                                                  textButtonTheme:
                                                      TextButtonThemeData(
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          globalPrimaryColor,
                                                    ),
                                                  ),
                                                ),
                                                child: child!,
                                              );
                                            },
                                          );

                                          if (pickedDate != null) {
                                            setState(() {
                                              selectedDate = pickedDate;
                                            });
                                          }
                                        },
                                        icon: const Icon(Icons.calendar_today,
                                            color: Colors.black),
                                        label: const Text(
                                          "Filtrar por data",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          elevation: 5,
                                          shadowColor: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            selectedDate = null;
                                          });
                                        },
                                        icon: const Icon(Icons.clear,
                                            color: Colors.black),
                                        label: const Text(
                                          "Resetar filtro",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          elevation: 5,
                                          shadowColor: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: filteredAgenda.isEmpty
                                      ? Card(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 10),
                                          elevation: 3,
                                          child: Stack(
                                            children: [
                                              Center(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Image.asset(
                                                      'assets/images/vazio.png',
                                                      width: 100,
                                                      fit: BoxFit.cover,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    const Text(
                                                      'Nenhum agendamento encontrado.',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.black54,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 20,
                                                right: 20,
                                                child: FloatingActionButton(
                                                  backgroundColor: Colors.green,
                                                  onPressed: () {
                                                    Get.toNamed('/home');
                                                  },
                                                  child: const Icon(Icons.add,
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Stack(
                                          children: [
                                            ListView.builder(
                                              itemCount: filteredAgenda.length,
                                              itemBuilder: (context, index) {
                                                final item =
                                                    filteredAgenda[index];
                                                final DateTime dataAgenda =
                                                    DateTime.parse(
                                                        item['data_agenda']);
                                                final DateTime dataFim =
                                                    DateTime.parse(
                                                        item['data_fim']);

                                                if (selectedDate != null &&
                                                    (dataAgenda.year !=
                                                            selectedDate!
                                                                .year ||
                                                        dataAgenda.month !=
                                                            selectedDate!
                                                                .month ||
                                                        dataAgenda.day !=
                                                            selectedDate!
                                                                .day)) {
                                                  return const SizedBox
                                                      .shrink();
                                                }

                                                return Card(
                                                  color: item['descricao_condicao_pagamento'] ==
                                                          '100% do valor no App'
                                                      ? Colors.green[200]
                                                      : item['descricao_condicao_pagamento'] ==
                                                              '50% do valor no App e 50% no estabelecimento'
                                                          ? Colors.yellow[200]
                                                          : item['descricao_condicao_pagamento'] ==
                                                                  '100% do valor no estabelecimento'
                                                              ? Colors.red[200]
                                                              : Colors.white,
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20,
                                                      vertical: 10),
                                                  elevation: 3,
                                                  child: Stack(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(16),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                    Icons
                                                                        .person,
                                                                    color: Colors
                                                                        .black),
                                                                const SizedBox(
                                                                    width: 4),
                                                                Expanded(
                                                                  child: Text(
                                                                    'Responsável: ${item['nome_responsavel']}',
                                                                    style:
                                                                        const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                                height: 8),
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                    Icons
                                                                        .calendar_today,
                                                                    color: Colors
                                                                        .black),
                                                                const SizedBox(
                                                                    width: 4),
                                                                Text(
                                                                  'Data: ${dataAgenda.day}/${dataAgenda.month}/${dataAgenda.year}',
                                                                  style: const TextStyle(
                                                                      color: Colors
                                                                          .black),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                                height: 8),
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                    Icons
                                                                        .access_time,
                                                                    color: Colors
                                                                        .black),
                                                                const SizedBox(
                                                                    width: 4),
                                                                Text(
                                                                  'Horário: ${item['horario']} - ${item['horario_final']}',
                                                                  style: const TextStyle(
                                                                      color: Colors
                                                                          .black),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                                height: 8),
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                    Icons.store,
                                                                    color: Colors
                                                                        .black),
                                                                const SizedBox(
                                                                    width: 4),
                                                                Expanded(
                                                                  child: Text(
                                                                    'Local: ${item['fantasia']}, ${item['nome']}',
                                                                    style: const TextStyle(
                                                                        color: Colors
                                                                            .black),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                                height: 8),
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                    Icons
                                                                        .location_city,
                                                                    color: Colors
                                                                        .black),
                                                                const SizedBox(
                                                                    width: 4),
                                                                Expanded(
                                                                  child: Text(
                                                                    'Endereço: ${item['endereco']}, ${item['cidade']}, ${item['uf']}',
                                                                    style: const TextStyle(
                                                                        color: Colors
                                                                            .black),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                                height: 8),
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                    Icons
                                                                        .attach_money,
                                                                    color: Colors
                                                                        .black),
                                                                const SizedBox(
                                                                    width: 4),
                                                                Text(
                                                                  'Valor: R\$ ${item['valor']}',
                                                                  style: const TextStyle(
                                                                      color: Colors
                                                                          .black),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                                height: 8),
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                    Icons
                                                                        .payment,
                                                                    color: Colors
                                                                        .black),
                                                                const SizedBox(
                                                                    width: 4),
                                                                Expanded(
                                                                  child: Text(
                                                                    'Forma de Pagamento: ${item['descricao_forma_pagamento']}',
                                                                    style: const TextStyle(
                                                                        color: Colors
                                                                            .black),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                                height: 8),
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                    Icons
                                                                        .event_note,
                                                                    color: Colors
                                                                        .black),
                                                                const SizedBox(
                                                                    width: 4),
                                                                Expanded(
                                                                  child: Text(
                                                                    'Condição de Pagamento: ${item['descricao_condicao_pagamento']}',
                                                                    style: const TextStyle(
                                                                        color: Colors
                                                                            .black),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            if (item['observacao'] !=
                                                                    null &&
                                                                item['observacao']
                                                                    .toString()
                                                                    .isNotEmpty) ...[
                                                              const SizedBox(
                                                                  height: 8),
                                                              Row(
                                                                children: [
                                                                  const Icon(
                                                                      Icons
                                                                          .note,
                                                                      color: Colors
                                                                          .black),
                                                                  const SizedBox(
                                                                      width: 4),
                                                                  Expanded(
                                                                    child: Text(
                                                                      'Obs: ${item['observacao']}',
                                                                      style: const TextStyle(
                                                                          color:
                                                                              Colors.black),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                            if (item[
                                                                    'repeticao'] ==
                                                                1) ...[
                                                              const SizedBox(
                                                                  height: 8),
                                                              Row(
                                                                children: [
                                                                  const Icon(
                                                                      Icons
                                                                          .calendar_month,
                                                                      color: Colors
                                                                          .black),
                                                                  const SizedBox(
                                                                      width: 4),
                                                                  Expanded(
                                                                    child: Text(
                                                                      'Repete até o dia: ${dataFim.day}/${dataFim.month}/${dataFim.year}',
                                                                      style: const TextStyle(
                                                                          color:
                                                                              Colors.black),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ]
                                                          ],
                                                        ),
                                                      ),
                                                      //alterar pra conferir se foi pago ou não
                                                      if (true)
                                                        Positioned(
                                                          top: 8,
                                                          right: 8,
                                                          child: IconButton(
                                                            icon: const Icon(
                                                              Icons.description,
                                                              color:
                                                                  Colors.black,
                                                              size: 28,
                                                            ),
                                                            onPressed: () {
                                                              openComprovante(
                                                                  item[
                                                                      'id_agenda'],
                                                                  item[
                                                                      'id_cliente']);
                                                            },
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                            Positioned(
                                              bottom: 20,
                                              right: 20,
                                              child: FloatingActionButton(
                                                backgroundColor: Colors.green,
                                                onPressed: () {
                                                  Get.toNamed('/home');
                                                },
                                                child: const Icon(Icons.add,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            )
                          : Container(
                              width: MediaQuery.of(context).size.width / 1.5,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: globalPrimaryColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(360),
                                    ),
                                    child: Image.asset(
                                      'assets/images/logo-placeholder.png',
                                      width: 200,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "Realize login para acessar sua agenda do clube da areia",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.indieFlower(
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextButton(
                                      onPressed: () => Get.toNamed('/login'),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Login',
                                            style: GoogleFonts.indieFlower(
                                              textStyle: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Icon(Icons.login_sharp,
                                              color: Colors.black),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            )
          : const Loading(),
      bottomNavigationBar: const BottomNavBar(selectedMenu: MenuState.myAgenda),
    );
  }
}
