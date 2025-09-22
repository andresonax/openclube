import 'dart:async';

import 'package:clubedaareia/src/common_widgets/bottomMenu/topNavBar.dart';
import 'package:clubedaareia/src/constants/colors.dart';
import 'package:clubedaareia/src/utils/getIdUser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../common_widgets/bottomMenu/bottomNavBar.dart';
import '../../../../constants/bottomNavBarMenuEnum.dart';
import '../../../../constants/constants.dart';
import '../../../../utils/loading.dart';
import '../../controllers/chatController.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  //controller
  final chatController = Get.put(ChatController());

  //variáveis
  String urlBase = constants.urlApi;
  bool hoverVoltar = false;
  bool isLogged = false;
  String idUser = '';
  String currentCity = "";
  int currentIBGE = 0;
  final TextEditingController _typeAheadController = TextEditingController();
  Timer? _debounce;
  List<dynamic> arenas = [];
  List<dynamic> arenasIds = [];
  List<dynamic> arenasDescriptions = [];
  List<dynamic> arenasInfos = [];
  List<dynamic> filteredArenas = [];
  List<dynamic> filteredArenasIds = [];
  List<dynamic> filteredArenasDescriptions = [];
  List<dynamic> filteredArenasInfos = [];

  List<dynamic> clientsMessagesViewed = [];

  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> setCity() async {
    final prefs = await SharedPreferences.getInstance();

    final String city = prefs.getString('selected_city_name') ?? '';
    final String ibgeRaw = prefs.getString('selected_city_ibge') ?? '';

    int ibge = 0;
    final cleaned = ibgeRaw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isNotEmpty) {
      try {
        ibge = int.parse(cleaned);
      } catch (e) {
        ibge = 0;
      }
    }
    if (!mounted) return;
    setState(() {
      currentCity = city;
      currentIBGE = ibge;
    });
  }

  Future<void> initialize() async {
    idUser = await getIdUser();
    await setCity();

    if (idUser != '') {
      setState(() {
        isLogged = true;
      });
    }

    await chatController.fetchClients(currentIBGE).then((response) {
      setState(() {
        arenas = response.map((client) => client['fantasia']).toList();
        arenasIds = response.map((client) => client['id_cliente']).toList();
        arenasDescriptions =
            response.map((client) => client['descricao']).toList();
        arenasInfos = response.map((client) => client['info']).toList();
        filterArenas('');
      });
    });

    await chatController
        .fetchMessagesViewed(int.parse(idUser))
        .then((response) => {
              setState(() {
                clientsMessagesViewed = response;
              })
            });

    setState(() {
      isInitialized = true;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  //filtro de busca
  void filterArenas(String query) {
    List<dynamic> tempArenas = [];
    List<dynamic> tempArenasIds = [];
    List<dynamic> tempArenasDescriptions = [];
    List<dynamic> tempArenasInfos = [];

    if (query.isNotEmpty) {
      for (var i = 0; i < arenas.length; i++) {
        if (arenas[i].toLowerCase().contains(query.toLowerCase())) {
          tempArenas.add(arenas[i]);
          tempArenasIds.add(arenasIds[i]);
          tempArenasDescriptions.add(arenasDescriptions[i]);
          tempArenasInfos.add(arenasInfos[i]);
        }
      }
    } else {
      tempArenas = List.from(arenas);
      tempArenasIds = List.from(arenasIds);
      tempArenasDescriptions = List.from(arenasDescriptions);
      tempArenasInfos = List.from(arenasInfos);
    }

    setState(() {
      filteredArenas = tempArenas;
      filteredArenasIds = tempArenasIds;
      filteredArenasDescriptions = tempArenasDescriptions;
      filteredArenasInfos = tempArenasInfos;
    });
  }

  void openModalAllCities() {
    _typeAheadController.clear();
    var options = [];
    var itens = [];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Busque sua cidade',
            textAlign: TextAlign.center,
            style: GoogleFonts.indieFlower(
              textStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 23),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TypeAheadField<Map<String, dynamic>>(
                  hideOnLoading: true,
                  debounceDuration: const Duration(
                      milliseconds: 100), // Handles your debounce logic
                  hideWithKeyboard:
                      false, // Matches your hideSuggestionsOnKeyboardHide: false
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller, // Use the provided controller
                      focusNode: focusNode, // Use the provided focusNode
                      decoration: const InputDecoration(
                        labelText: 'Pesquise a cidade',
                      ),
                    );
                  },
                  suggestionsCallback: (pattern) async {
                    if (pattern.length < 3) return [];

                    List<dynamic> cities =
                        await chatController.fetchCities(pattern);

                    // Process to unique options (using a Set to avoid duplicates)
                    Set<Map<String, dynamic>> uniqueOptions = {};
                    for (var item in cities) {
                      uniqueOptions.add(
                          {'cidade': item['cidade'], 'ibge': item['ibge']});
                    }
                    return uniqueOptions.toList();
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      title: Text(suggestion['cidade']),
                    );
                  },
                  onSelected: (suggestion) async {
                    setState(() {
                      currentCity = suggestion['cidade'];
                      currentIBGE = suggestion['ibge'];
                    });

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('selected_city_name', currentCity);
                    await prefs.setString(
                        'selected_city_ibge', currentIBGE.toString());

                    var response =
                        await chatController.fetchClients(currentIBGE);

                    setState(() {
                      arenas =
                          response.map((client) => client['fantasia']).toList();
                      arenasIds = response
                          .map((client) => client['id_cliente'])
                          .toList();
                      arenasDescriptions = response
                          .map((client) => client['descricao'])
                          .toList();
                      arenasInfos =
                          response.map((client) => client['info']).toList();
                      filterArenas('');
                    });
                    Navigator.pop(context);
                  },
                  emptyBuilder: (context) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Nenhuma cidade encontrada.',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  },
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: globalPrimaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      height: 60,
      width: double.infinity,
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.black),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              currentCity,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.indieFlower(
                textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black),
              ),
            ),
          ),
          const Spacer(),
          TextButton(
              onPressed: () {
                openModalAllCities();
              },
              child: Text(
                "Alterar",
                style: GoogleFonts.indieFlower(
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black),
                ),
              ))
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          filterArenas(value);
        },
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Colors.black),
          hintText: "Buscar arena...",
          hintStyle: GoogleFonts.indieFlower(
            textStyle: const TextStyle(
              fontSize: 18,
              color: Colors.black54,
            ),
          ),
          border: InputBorder.none,
        ),
        style: GoogleFonts.indieFlower(
          textStyle: const TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ),
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
                  const TopNavBar(route: '/home', backButtonText: 'Voltar'),
                  Expanded(
                    child: Center(
                      child: isLogged
                          ? Container(
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  _buildLocationCard(),
                                  _buildSearchBar(),
                                  filteredArenas.isEmpty
                                      ? Expanded(
                                          child: Card(
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
                                                      const SizedBox(
                                                          height: 10),
                                                      const Text(
                                                        'Nenhuma arena encontrada',
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
                                              ],
                                            ),
                                          ),
                                        )
                                      : Expanded(
                                          child: ListView.builder(
                                            itemCount: filteredArenas.length,
                                            itemBuilder: (context, index) {
                                              final clientId =
                                                  filteredArenasIds[index];

                                              final unreadEntry =
                                                  clientsMessagesViewed
                                                      .firstWhere(
                                                (m) =>
                                                    m['id_cliente'] == clientId,
                                                orElse: () => {
                                                  'id_cliente': clientId,
                                                  'total': 0
                                                },
                                              );
                                              final unreadCount =
                                                  unreadEntry['total']!;
                                              return Card(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 10),
                                                elevation: 3,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  child: Row(
                                                    children: [
                                                      Image.network(
                                                        '${urlBase}clients/getLogo/${filteredArenasIds[index]}',
                                                        width: 60,
                                                        height: 60,
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          return Image.asset(
                                                            'assets/images/logo-placeholder.png',
                                                            width: 60,
                                                          );
                                                        },
                                                      ),
                                                      Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 10)),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            '${filteredArenas[index]}',
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${filteredArenasDescriptions[index]}',
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Spacer(),
                                                      if (unreadCount > 0)
                                                        CircleAvatar(
                                                          radius: 12,
                                                          backgroundColor:
                                                              Colors.red,
                                                          child: Text(
                                                            '$unreadCount',
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: IconButton(
                                                          icon: const Icon(
                                                              Icons.send),
                                                          color:
                                                              Colors.blueAccent,
                                                          onPressed: () {
                                                            Get.toNamed(
                                                                '/chatArena/${filteredArenasIds[index]}');
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                ],
                              ),
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
                                    "Realize login para acessar o chat do clube da areia",
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
      bottomNavigationBar: const BottomNavBar(selectedMenu: MenuState.chat),
    );
  }
}
