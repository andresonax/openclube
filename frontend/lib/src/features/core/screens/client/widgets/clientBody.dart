import 'package:carousel_slider/carousel_slider.dart';
import 'package:clubedaareia/src/constants/colors.dart';
import 'package:clubedaareia/src/utils/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../constants/constants.dart';
import '../../../controllers/clientController.dart';

class ClientBody extends StatefulWidget {
  final List<dynamic>? clientData;
  const ClientBody({this.clientData, super.key});

  @override
  State<ClientBody> createState() => _ClientBodyState();
}

class _ClientBodyState extends State<ClientBody> {
  //controllers
  final clientController = Get.put(ClientController());

  //variáveis
  String urlBase = constants.urlApi;
  String urlBaseGestor = constants.urlApiGestor;
  bool isInitialized = false;
  bool isCourtsEmpty = false;
  List<String> courts = [];
  List<String> courtsModality = [];
  List<int> courtsModalityIds = [];
  List<String> courtsInfo = [];
  List<int> courtsIds = [];
  int idClient = 0;
  String clientName = '';
  String clientAddress = '';
  String clientCep = '';
  int _current = 0;
  String info = '';
  String cancel = '';
  final CarouselSliderController _controller = CarouselSliderController();
  bool isLoggedIn = true;

  dynamic quadras = {};
  dynamic courtsAllData = [];

  dynamic timeslots = [];
  dynamic booked = [];
  dynamic blocked = [];
  dynamic daysTimeSlotsData = {};

  void setStateCallback(int index) {
    setState(() {
      _current = index;
    });
  }

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    setState(() {
      selectedDate = DateTime.now();
    });

    setState(() {
      clientName = widget.clientData![0]['fantasia'] ?? '';
      idClient = widget.clientData![0]['id_cliente'] ?? 0;
      info = widget.clientData!.toList()[0]['info'] ?? '';
      cancel = widget.clientData![0]['cancelamento'] ?? '';
      clientAddress = widget.clientData![0]['endereco'] ?? '';
      clientCep = widget.clientData![0]['cep'] ?? '';
    });

    initialize();
  }

  Future<void> initialize() async {
    final response = await clientController.fetchCourts(idClient);

    setState(() {
      courtsAllData = response;
      for (var i = 0; i < response.length; ++i) {
        courts.add(response[i]['nome']);
        courtsModality.add(response[i]['nome_modalidade']);
        courtsInfo.add(response[i]['description'] ?? '');
        courtsIds.add(response[i]['id_espaco']);
        courtsModalityIds.add(response[i]['id_modalidade_espaco']);
      }

      Map<int, Map<String, dynamic>> groupedCourts = {};

      for (var court in response) {
        int idEspaco = court['id_espaco'];
        if (!groupedCourts.containsKey(idEspaco)) {
          groupedCourts[idEspaco] = {
            'nome': court['nome'],
            'id': idEspaco,
            'modalidades': [],
          };
        }
        groupedCourts[idEspaco]!['modalidades'].add({
          'nome': court['nome_modalidade'],
          'id': court['id_modalidade_espaco'],
        });
      }

      setState(() {
        quadras = groupedCourts.values.toList();
        if (courts.isEmpty) {
          isCourtsEmpty = true;
        }
        isInitialized = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double carrouselHeight = 465;
    double imageHeight = 280.0;

    final List<Widget> imageSliders = isInitialized
        ? quadras
            .asMap()
            .entries
            .map((entry) {
              int index = entry.key;
              Map<String, dynamic> item = entry.value;

              String courtName = item['nome'];
              int courtId = item['id'];
              List modalidades = item['modalidades'];
              List modalitiesNames = [];
              List modalitiesIds = [];

              for (int i = 0; i < modalidades.length; ++i) {
                modalitiesNames.add(modalidades[i]['nome']);
                modalitiesIds.add(modalidades[i]['id']);
              }

              return Container(
                height: carrouselHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black,
                    width: 1.0,
                  ),
                ),
                child: isCourtsEmpty
                    ? Container()
                    : Column(
                        children: [
                          Text(
                            courtName,
                            style: GoogleFonts.indieFlower(
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isSmallScreen = constraints.maxWidth < 600;
                              final imageWidth = isSmallScreen
                                  ? constraints.maxWidth * 0.95
                                  : 500.0;

                              return Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    '${urlBaseGestor}locacao/espaco/getPic/$courtId',
                                    width: imageWidth,
                                    height: imageHeight,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/logo-placeholder.png',
                                        width: imageWidth,
                                        height: imageHeight,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          if (modalidades.isNotEmpty)
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Center(
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: modalidades.map<Widget>((mod) {
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Image.network(
                                              '${urlBaseGestor}locacao/modalidade_espaco/getPic/${mod['id']}/',
                                              height: 30,
                                              width: 30,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                    width: 30, height: 30);
                                              },
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              mod['nome'],
                                              style: GoogleFonts.indieFlower(
                                                textStyle: const TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                )),
                          const Spacer(),
                          SizedBox(
                            height: 40,
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                final firstModality = modalidades.isNotEmpty
                                    ? modalidades[0]
                                    : null;
                                Get.toNamed('/booking', arguments: {
                                  'clientName': clientName,
                                  'courtName': courtName,
                                  'courtId': courtId,
                                  'idClient': idClient,
                                  'clientAddress': clientAddress,
                                  'clientCep': clientCep,
                                  'courtModality': firstModality?['nome'] ?? '',
                                  'courtsModalityId':
                                      firstModality?['id'] ?? -1,
                                  'allModalitiesIds': modalitiesIds,
                                });
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: globalPrimaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(0),
                                ),
                              ),
                              child: Text(
                                'AGENDAR',
                                style: GoogleFonts.indieFlower(
                                  textStyle: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              );
            })
            .toList()
            .cast<Widget>()
        : [const Center(child: Loading())];
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildSendMessageCard(),
        _buildCarousel(
            context, setStateCallback, imageSliders, carrouselHeight),
        _buildCancellationCard(),
        _buildGeneralInfoCard(),
      ],
    );
  }

  Widget _buildSendMessageCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: globalPrimaryColor,
      height: 60,
      width: double.infinity,
      child: Row(
        children: [
          Text(
            "Enviar mensagem",
            style: GoogleFonts.indieFlower(
              textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black),
            ),
          ),
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                Get.toNamed('/chatArena/$idClient');
              },
              child: SvgPicture.asset(
                'assets/icons/chat.svg',
                width: 25,
                height: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel(BuildContext context, Function setStateCallback,
      List<Widget> imageSliders, double carrouselHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        courts.length == 1
            ? Text(
                '${courts.length} Quadra(s)',
                style: GoogleFonts.indieFlower(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: globalPrimaryColor,
                  ),
                ),
              )
            : quadras.length == 1
                ? Text(
                    '${quadras.length} Quadra',
                    style: GoogleFonts.indieFlower(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: globalPrimaryColor,
                      ),
                    ),
                  )
                : Text(
                    '${quadras.length} Quadras',
                    style: GoogleFonts.indieFlower(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: globalPrimaryColor,
                      ),
                    ),
                  ),
        SizedBox(
          height: carrouselHeight,
          child: CarouselSlider(
            items: imageSliders,
            carouselController: _controller,
            options: CarouselOptions(
              autoPlay: true,
              enlargeCenterPage: true,
              aspectRatio: 10,
              disableCenter: true,
              onPageChanged: (index, reason) {
                setStateCallback(index);
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: courts.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _controller.animateToPage(entry.key),
              child: Container(
                width: 12.0,
                height: 12.0,
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black)
                      .withOpacity(_current == entry.key ? 0.9 : 0.4),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCancellationCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      width: double.infinity,
      color: Colors.grey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/agenda.svg',
                width: 25,
                height: 25,
              ),
              const SizedBox(width: 10),
              Text(
                'REGRA PARA CANCELAMENTOS',
                style: GoogleFonts.indieFlower(
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black),
                ),
              ),
            ],
          ),
          Text(
            cancel,
            maxLines: 3,
            style: GoogleFonts.indieFlower(
              textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralInfoCard() {
    return Container(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: 30,
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'INFORMAÇÕES GERAIS',
                style: GoogleFonts.indieFlower(
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          Text(
            info,
            maxLines: 3,
            style: GoogleFonts.indieFlower(
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
