import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/constants.dart';
import '../features/core/controllers/clientController.dart';
import '../utils/getIdUser.dart';

//evita usuário de acessar rotas sem estar logado
class AuthMiddleware extends GetMiddleware {
  final sharedPreferences = Get.find<SharedPreferences>();
  @override
  RouteSettings? redirect(String? route) {
    if (sharedPreferences.getString('token') == null) {
      return const RouteSettings(name: '/login');
    }
    return null;
  }
}

//redireciona e filtra rotas específicas para o cliente exclusivo
class ClientExclusiveMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    const isClientExclusive = constants.isClientExclusive;
    const clientId = constants.idClient;

    if (!isClientExclusive || route == null) return null;

    if (route == '/home') {
      return const RouteSettings(name: '/client/$clientId');
    } else if (route == '/chat') {
      return const RouteSettings(name: '/chatArena/$clientId');
    } else if (route == '/') {
      return const RouteSettings(name: '/client/$clientId');
    }

    return null;
  }
}

//redireciona pro id correto caso o usuário insira na url e seja cliente
class CorrectClientIdMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final idFromRoute = Get.parameters['id'];
    const isClientExclusive = constants.isClientExclusive;
    if (!isClientExclusive) {
      return null; // Se não for cliente exclusivo, não redireciona
    }
    const correctId = constants.idClient;

    if (idFromRoute != null && idFromRoute != correctId.toString()) {
      final newRoute = route!.replaceFirst('/$idFromRoute', '/$correctId');
      return RouteSettings(name: newRoute);
    }

    return null;
  }
}

class VerifyCityMiddleware extends GetMiddleware {
  final sharedPreferences = Get.find<SharedPreferences>();

  @override
  RouteSettings? redirect(String? route) {
    if (sharedPreferences.getString('selected_city_ibge') == null) {
      return const RouteSettings(name: '/verifyCity');
    }
    return null;
  }
}


//redireciona página de cliente pra página de horários 
//apenas quando é na web e quando é cliente único
class VerifyLoginMiddleware extends GetMiddleware {
  final String idClient;

  VerifyLoginMiddleware({required this.idClient});

  @override
  RouteSettings? redirect(String? route) {

    return null; 
  }

  @override
  Widget onPageBuilt(Widget page) {

    if(kIsWeb && constants.isClientExclusive){
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        String id = await getIdUser();

        if (id == '') {
          final clientController = Get.find<ClientController>();
          var quadras =
              await clientController.fetchCourts(int.parse(idClient)) ?? [];
          var clientData =
              await clientController.fetchClientData(int.parse(idClient)) ?? [];


          Map<int, Map<String, dynamic>> groupedCourts = {};

          for (var court in quadras) {
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


          quadras = groupedCourts.values.toList();

          if (quadras.isNotEmpty) {
            final courtName = quadras[0]['nome'];
            final courtId = quadras[0]['id'];
            final modalidades = quadras[0]['modalidades'] ?? [];
            final firstModality = modalidades.isNotEmpty ? modalidades[0] : null;
            final modalitiesIds = modalidades.map((m) => m['id']).toList();

            Get.offNamed('/booking', arguments: {
              'clientName': clientData[0]['fantasia'],
              'courtName': courtName,
              'courtId': courtId,
              'idClient': int.parse(idClient),
              'clientAddress': clientData[0]['endereco'],
              'clientCep': clientData[0]['cep'],
              'courtModality': firstModality?['nome'] ?? '',
              'courtsModalityId': firstModality?['id'] ?? -1,
              'allModalitiesIds': modalitiesIds,
            });
          } else {
            print('Nenhuma quadra encontrada');
          }
        }
      });
    }

    return page;
  }
}
