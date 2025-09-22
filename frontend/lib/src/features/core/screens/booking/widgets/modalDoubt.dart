import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModalDoubt extends StatefulWidget {
  const ModalDoubt({super.key});

  @override
  State<ModalDoubt> createState() => _ModalDoubtState();
}

class _ModalDoubtState extends State<ModalDoubt> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Siga os passos para agendar:',
        textAlign: TextAlign.center,
        style: GoogleFonts.indieFlower(
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 23,
          ),
        ),
      ),
      content: SizedBox(
        height: 220, // Defina a altura desejada aqui
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selecione um ou mais horários em certo dia',
              textAlign: TextAlign.center,
              
            ),
            Image.asset('assets/images/example-slot.png'),
            const SizedBox(height: 10), // Espaçamento entre os textos
            const Text(
              'Clique no botão para ir para o pagamento',
              textAlign: TextAlign.center,
            ),
            Image.asset('assets/images/example-selected-slot.png'),
          ],
        ),
      ),
    );
  }
}
