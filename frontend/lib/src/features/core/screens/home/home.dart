import 'dart:async';

import 'package:clubedaareia/src/common_widgets/bottomMenu/topNavBar.dart';
import 'package:clubedaareia/src/constants/colors.dart';
import 'package:clubedaareia/src/features/core/screens/home/widgets/sectionCard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../common_widgets/bottomMenu/bottomNavBar.dart';
import '../../../../constants/bottomNavBarMenuEnum.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../../../../utils/getIdUser.dart';
import '../../../../utils/loading.dart';
import '../../controllers/homeController.dart';
import 'widgets/homeHeader.dart';

import '../../../../constants/constants.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // controllers
  final homeController = Get.put(HomeController());

  //variáveis
  String urlBase = constants.urlApi;
  bool hoverVoltar = false;
  bool isLoggedIn = false;
  bool isInitialized = false;
  String currentCity = "";
  int currentIBGE = 0;
  List<dynamic> userData = [];
  String userID = '';
  String userName = "User";
  List<dynamic> arenas = [];
  List<dynamic> arenasAddress = [];
  List<dynamic> arenasCEPs = [];
  List<dynamic> arenasIds = [];
  List<dynamic> arenasDescriptions = [];
  List<dynamic> arenasInfos = [];
  List<dynamic> stars = [];
  List<dynamic> howManyReviews = [];
  Timer? _debounce;
  double currentStars = 5;

  final TextEditingController _typeAheadController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
  }

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
    setCity();

    String id = await getIdUser();
    
    var response = await homeController.fetchClients(currentIBGE);

    print("clientes");
    print(response);
    var responseReviews = await homeController.fetchReviews(currentIBGE);
    setState(() {
      stars = responseReviews
          .map((reviews) => reviews['estrelas'] ?? 'Sem Avaliações')
          .toList();

      howManyReviews = responseReviews
          .map((reviews) => reviews['quantidade_avaliacoes'] ?? '0')
          .toList();

      arenas = response.map((client) => client['fantasia']).toList();
      arenasIds = response.map((client) => client['id_cliente']).toList();
      arenasAddress = response.map((client) => client['endereco']).toList();
      arenasCEPs = response.map((client) => client['cep']).toList();
      arenasDescriptions =
          response.map((client) => client['description']).toList();
      arenasInfos = response.map((client) => client['info']).toList();
    });

    if (id == '') {
      setState(() {
        isLoggedIn = false;
        isInitialized = true;
      });
    } else {
      setState(() {
        userID = id;
        isLoggedIn = true;
      });
      userData = await homeController.fetchUserData(userID);
      setState(() {
        //userName = userData[0]['nome_completo'].toString().substring(0, 7);
        isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.jpeg"),
            fit: BoxFit.fill,
          ),
        ),
        child: SingleChildScrollView(
          child: isInitialized
              ? Column(
                  children: [
                    const TopNavBar(route: '/login', backButtonText: 'Voltar'),
                    HomeHeader(isLoggedIn: isLoggedIn, userData: userData),
                    _buildLocationCard(),
                    _buildArenasSection(),
                    //_buildCarousel(),
                    _buildArenaListCards(),

                    const SizedBox(height: 20),
                  ],
                )
              : Center(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: const Center(
                      child: Loading(),
                    ),
                  ),
                ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(selectedMenu: MenuState.home),
    );
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
                  debounceDuration: const Duration(milliseconds: 100),
                  hideWithKeyboard: false,
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Pesquise a cidade',
                      ),
                    );
                  },
                  suggestionsCallback: (pattern) async {
                    if (pattern.length < 3) return [];

                    List<dynamic> cities =
                        await homeController.fetchCities(pattern);

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
                    await prefs.setString('selected_city_ibge', currentIBGE.toString());


                    var response =
                        await homeController.fetchClients(currentIBGE);

                    if (response.isNotEmpty) {
                      // Fecha o modal antes de atualizar o estado principal
                      Navigator.pop(context);

                      fetchReviews();

                      setState(() {
                        arenas = response
                            .map((client) => client['fantasia'])
                            .toList();
                        arenasIds = response
                            .map((client) => client['id_cliente'])
                            .toList();
                        arenasDescriptions = response
                            .map((client) => client['description'])
                            .toList();
                        arenasInfos =
                            response.map((client) => client['info']).toList();
                      });
                    } else {
                      Navigator.pop(context);

                      setState(() {
                        arenas = [];
                        arenasIds = [];
                        arenasDescriptions = [];
                        arenasInfos = [];
                      });
                    }
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

  void fetchReviews() async {
    var responseReviews = await homeController.fetchReviews(currentIBGE);
    setState(() {
      stars = responseReviews
          .map((reviews) => reviews['estrelas'] ?? 'Sem Avaliações')
          .toList();
      howManyReviews = responseReviews
          .map((reviews) => reviews['quantidade_avaliacoes'] ?? '0')
          .toList();

      currentStars = 5;
    });
  }

  void openModalStars(
      BuildContext context, String arena, int idClient, String idUser) {
    if (idUser == '') {
      Get.toNamed('/login');
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Avalie a $arena',
            textAlign: TextAlign.center,
            style: GoogleFonts.indieFlower(
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 23,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RatingBar.builder(
                initialRating: 5,
                minRating: 1,
                itemBuilder: (context, _) =>
                    const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (double value) {
                  setState(() {
                    currentStars = value;
                  });
                },
              ),
              const SizedBox(
                height: 20,
              ),
              TextButton(
                onPressed: () async {
                  await homeController.sendReview(
                      currentStars, idClient, idUser);
                  await Future.delayed(const Duration(seconds: 1));

                  fetchReviews();

                  Navigator.pop(context);
                  Future.delayed(Duration.zero, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Obrigado por avaliar!"),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue, // Cor de fundo azul
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical:
                          12.0), // Ajuste de padding para melhorar o design
                ),
                child: Text(
                  'Enviar',
                  style: GoogleFonts.indieFlower(
                    textStyle: const TextStyle(
                      color: Colors.white, // Cor do texto branco
                      fontSize: 18, // Ajuste o tamanho da fonte se necessário
                      fontWeight: FontWeight.bold, // Peso da fonte, se desejado
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void openModalAllArenas(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Arenas de $currentCity',
            textAlign: TextAlign.center,
            style: GoogleFonts.indieFlower(
              textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 23,
                  color: Colors.white),
            ),
          ),
          content: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              width: MediaQuery.of(context).size.width * 0.8,
              child: ListView.builder(
                itemCount: arenas.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Get.toNamed(
                          '/client/${arenasIds[index]}' /*, arguments: {
                        arenas[index],
                        arenasIds[index],
                        arenasDescriptions[index],
                        arenasInfos[index],
                        arenasAddress[index],
                        arenasCEPs[index],
                      }*/
                          );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      height: 100,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Row(
                          children: [
                            const Padding(padding: EdgeInsets.only(left: 10)),
                            Image.network(
                              '${urlBase}clients/getLogo/${arenasIds[index]}',
                              width: 80,
                              height: 80,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/logo-placeholder.png',
                                  width: 80,
                                );
                              },
                            ),
                            const Padding(padding: EdgeInsets.only(left: 20)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                      padding: EdgeInsets.only(top: 23)),
                                  Text(
                                    arenas[index],
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: GoogleFonts.indieFlower(
                                      textStyle: const TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          color: Colors.amber, size: 30),
                                      const SizedBox(width: 10),
                                      Text(
                                        stars[index],
                                        style: GoogleFonts.indieFlower(
                                          textStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
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

  Widget _buildArenasSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Arenas",
                  style: GoogleFonts.indieFlower(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  "em $currentCity",
                  style: GoogleFonts.indieFlower(
                    textStyle:
                        const TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildArenaListTransparent() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: arenas.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: GestureDetector(
            onTap: () {
              Get.toNamed('/client/${arenasIds[index]}');
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo circular
                  ClipOval(
                    child: Image.network(
                      '${urlBase}clients/getLogo/${arenasIds[index]}',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/logo-placeholder.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Nome + avaliações
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          arenas[index],
                          style: GoogleFonts.indieFlower(
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white, // branco p/ fundo escuro
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            openModalStars(
                              context,
                              arenas[index],
                              arenasIds[index],
                              userID,
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 24),
                              const SizedBox(width: 6),
                              Text(
                                stars[index],
                                style: GoogleFonts.indieFlower(
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "(${howManyReviews[index]} avaliações)",
                                style: GoogleFonts.indieFlower(
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white70,
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
              ),
            ),
          ),
        );
      },
    );
  }
Widget _buildArenaListCards() {
  if (arenas.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 2.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            "Nenhuma arena disponível",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18, // menor um pouco
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: arenas.length,
    itemBuilder: (context, index) {
      bool isHovered = false;

      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: MouseRegion(
              onEnter: (_) => setState(() => isHovered = true),
              onExit: (_) => setState(() => isHovered = false),
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  Get.toNamed('/client/${arenasIds[index]}');
                },
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(
                    begin: 1.0,
                    end: isHovered ? 1.008 : 1.0, // scale contido
                  ),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      alignment: Alignment.center, // pivô no centro
                      child: child,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    clipBehavior: Clip.antiAlias, // mantêm conteúdo dentro do raio
                    decoration: BoxDecoration(
                      color: isHovered ? Colors.grey[800] : Colors.white,
                      border: Border.all(color: Colors.black, width: 2.5), // mais grossa
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isHovered ? 0.30 : 0.10),
                          blurRadius: isHovered ? 12 : 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          
                          child: Image.network(
                            '${urlBase}clients/getLogo/${arenasIds[index]}',
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/logo-placeholder.png',
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Nome + avaliações
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                arenas[index],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18, // menor que 20
                                  color: isHovered ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () {
                                  openModalStars(
                                    context,
                                    arenas[index],
                                    arenasIds[index],
                                    userID,
                                  );
                                },
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      stars[index],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16, // menor que 18
                                        color: isHovered ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "(${howManyReviews[index]} avaliações)",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14, // menor que 16
                                        color: isHovered ? Colors.white70 : Colors.black54,
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
                ),
              ),
            ),
          );
        },
      );
    },
  );
}


  Widget _buildArenaList() {
    return ListView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // se estiver dentro de outra scroll
      itemCount: arenas.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Get.toNamed('/client/${arenasIds[index]}');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo circular
                ClipOval(
                  child: Image.network(
                    '${urlBase}clients/getLogo/${arenasIds[index]}',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/logo-placeholder.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Nome da arena + avaliações
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        arenas[index],
                        style: GoogleFonts.indieFlower(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          openModalStars(
                            context,
                            arenas[index],
                            arenasIds[index],
                            userID,
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 24),
                            const SizedBox(width: 6),
                            Text(
                              stars[index],
                              style: GoogleFonts.indieFlower(
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "(${howManyReviews[index]} avaliações)",
                              style: GoogleFonts.indieFlower(
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildCarousel() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 300,
        enlargeCenterPage: true,
        autoPlay: true,
      ),
      items: arenas.map((arena) {
        int index = arenas.indexOf(arena);
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => {
                  Get.toNamed(
                      '/client/${arenasIds[index]}' /*, arguments: {
                    arenas[index],
                    arenasIds[index],
                    arenasDescriptions[index],
                    arenasInfos[index],
                    arenasAddress[index],
                    arenasCEPs[index],
                  }*/
                      )
                },
                child: Column(
                  children: [
                    Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.network(
                          '${urlBase}clients/getLogo/${arenasIds[index]}',
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/logo-placeholder.png',
                              width: 80,
                              height: 80,
                            );
                          },
                        )),
                    const SizedBox(height: 8),
                    Text(
                      arena,
                      style: GoogleFonts.indieFlower(
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => {
                  openModalStars(
                      context, arenas[index], arenasIds[index], userID)
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 30),
                    const SizedBox(width: 10),
                    Text(
                      stars[index],
                      style: GoogleFonts.indieFlower(
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "(${howManyReviews[index]} avaliações)",
                      style: GoogleFonts.indieFlower(
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
