import 'package:clubedaareia/src/utils/loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common_widgets/bottomMenu/bottomNavBar.dart';
import '../../../../common_widgets/bottomMenu/topNavBar.dart';
import '../../../../constants/bottomNavBarMenuEnum.dart';
import '../../../../constants/constants.dart';
import '../../controllers/clientController.dart';
import 'widgets/clientBody.dart';
import 'widgets/clientHeader.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  //controller
  final clientController = Get.put(ClientController());

  //variables
  dynamic clientData = [];
  late dynamic id_client;
  bool isInitialized = false;

  @override
  initState() {
    super.initState();
    initialize();
  }

  Future<dynamic> fetchClientData() async {
    return clientController.fetchClientData(int.parse(id_client));
  }

  Future<void> initialize() async {
    id_client = Get.parameters['id'];
    
    try {
      var dataClient = await fetchClientData();

      print('dataClient: $dataClient');
      if (dataClient.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed('/home');
        });
        return; 
      }

      setState(() {
        clientData = dataClient;
        isInitialized = true;
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/home');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isInitialized ? SafeArea(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/background.jpeg"),
              fit: BoxFit.fill,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                !constants.isClientExclusive? const TopNavBar(route: '/home', backButtonText: 'Voltar'):Container(),
                ClientHeader(clientData: clientData),
                ClientBody(clientData: clientData),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const BottomNavBar(selectedMenu: MenuState.home),
      ),
    ): const Loading();
  }
}
