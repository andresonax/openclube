import 'package:clubedaareia/src/constants/colors.dart';
import 'package:clubedaareia/src/utils/getIdUser.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/constants.dart';
import '../../controllers/chatController.dart';

class ClientChat extends StatefulWidget {
  const ClientChat({super.key});

  @override
  State<ClientChat> createState() => _ClientChatState();
}

class _ClientChatState extends State<ClientChat> {
  //controller
  final chatController = Get.put(ChatController());

  //variables
  final TextEditingController _messageController = TextEditingController();
  List<String> mensagens = [];
  List<String> mensagensDatas = [];
  List<String> mensagensRecebidas = [];
  List<String> mensagensRecebidasDatas = [];
  List<dynamic> todasMensagens = [];
  dynamic clientData;
  final String id_client = Get.parameters['id']!;
  String idUser = '';
  final String urlBase = constants.urlApi;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    await chatController
        .fetchSpecificClient(int.parse(id_client))
        .then((response) {
      setState(() {
        clientData = response;
      });
    });

    idUser = await getIdUser();

    final response = await chatController.fetchMessages(
        int.parse(id_client), int.parse(idUser));



    for (var i = 0; i < response.length; i++) {
      setState(() {
        todasMensagens.add(response[i]);
        if (response[i]['remetente'] == 'usuario') {
          mensagens.add(response[i]['mensagem']);
          mensagensDatas.add(
              response[i]['data_envio'].toString().substring(0, 10) +
                  ' ' +
                  response[i]['data_envio'].toString().substring(11, 16));
        } else {
          mensagensRecebidas.add(response[i]['mensagem']);
          mensagensRecebidasDatas.add(
              response[i]['data_envio'].toString().substring(0, 10) +
                  ' ' +
                  response[i]['data_envio'].toString().substring(11, 16));
        }
      });
    }
    await chatController.changeView(
        int.parse(id_client), int.parse(idUser));
  }

  Future<void> sendMessage() async {
    String mensagem = _messageController.text.trim();
    DateTime now = DateTime.now();

    if (mensagem.isNotEmpty) {
      final msgData = {
        'id_cliente': int.parse(id_client),
        'id_usuario': await getIdUser(),
        'mensagem': mensagem,
        'remetente': 'usuario',
        'data_envio': now.toString(),
      };

      await chatController.sendMessage(msgData);

      setState(() {
        todasMensagens.add(msgData);
      });
    }
    _messageController.clear();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // TopBar
            Container(
              decoration: BoxDecoration(color: globalPrimaryColor[200], boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => constants.isClientExclusive? Get.toNamed('/home') : Get.toNamed('/chat'),
                  ),
                  if (clientData != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.network(
                        '${urlBase}clients/getLogo/$id_client',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/logo-placeholder.png',
                            width: 40,
                            height: 40,
                          );
                        },
                      ),
                    ),
                  const SizedBox(width: 10),
                  if (clientData != null)
                    Expanded(
                      child: Text(
                        clientData[0]['fantasia'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Corpo do chat
            Expanded(
              child: Container(
                color: Colors.grey[100],
                child: ListView.builder(
                  reverse: true,
                  itemCount: todasMensagens.length,
                  itemBuilder: (context, index) {
                    final msg =
                        todasMensagens[todasMensagens.length - 1 - index]
                            ['mensagem'];
                    final msgDate =
                        todasMensagens[todasMensagens.length - 1 - index]
                                    ['data_envio']
                                .toString()
                                .substring(0, 10) +
                            ' ' +
                            todasMensagens[todasMensagens.length - 1 - index]
                                    ['data_envio']
                                .toString()
                                .substring(11, 16);
                    if (todasMensagens[todasMensagens.length - 1 - index]
                            ['remetente'] ==
                        'usuario') {
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                msg,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                msgDate,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: globalPrimaryColor[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                msg,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                msgDate,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),

            // Campo de input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: "Digite uma mensagem...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: Colors.blue,
                    onPressed: () async {
                      await sendMessage();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
