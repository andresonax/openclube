import 'package:get/get.dart';

import '../../../repository/myAgendaRepository.dart';


class MyAgendaController extends GetxController {
  static MyAgendaController get instance => Get.find();

  final MyAgendaRepository myAgendaRepository = Get.put(MyAgendaRepository());

  Future<dynamic> fetchAgenda(String idUser) async {
    return await myAgendaRepository.fetchAgenda(idUser);
  }

  Future<dynamic> getDataCompra(int idAgenda) async {
    return await myAgendaRepository.getDataCompra(idAgenda);
  }

  Future<dynamic> getComprovante(int idCompra, int idCliente) async {
    return await myAgendaRepository.getComprovante(idCompra, idCliente);
  }
}