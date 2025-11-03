import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../../constants/colors.dart';
import '../../../controllers/bookingController.dart';

class PaymentModal extends StatefulWidget {
  final dynamic pix;
  final int idCompra;
  final String idClient;
  final String cellphone;

  const PaymentModal({
      required this.pix,
      required this.idCompra,
      required this.idClient,
      required this.cellphone,
      Key? key
    })
      : super(key: key);

  @override
  _PaymentModalState createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  late int seconds;
  Timer? countdownTimer;
  Timer? checkTimer;
  final bookingController = Get.put(BookingController());

  @override
  void initState() {
    super.initState();
    seconds = (widget.pix['expiracao_minutos'] ?? 1) * 60;
    _startCountdown();
    _startPixCheck();
  }

  void _startCountdown() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (seconds > 0) {
        setState(() => seconds--);
      } else {
        _closeDialog();
      }
    });
  }

  void _startPixCheck() {
    checkTimer = Timer.periodic(const Duration(seconds: 10), (t) async {
      
      final response = await bookingController.checkPix(widget.idCompra);
      if (response['valor_pago'] != null) {
        try {
          await bookingController.sendPaymentConfirmationWhatsApp(
            widget.idClient,
            widget.cellphone,
            widget.idCompra,
          );
        } catch (e) {
          print('Erro ao enviar confirmação: $e');
        } finally {
          _closeDialog(navigateTo: '/myAgenda');
        }
      }
      

      //bloco de mock/testes
      //await bookingController.mockConfirmPay();
      //_closeDialog(navigateTo: '/myAgenda');
    });
  }

  void _closeDialog({String? navigateTo}) {
    countdownTimer?.cancel();
    checkTimer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pop();
    if (navigateTo != null) {
      Get.toNamed(navigateTo);
    }
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    checkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              'Escaneie ou copie o código',
              style: GoogleFonts.indieFlower(
                textStyle:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            QrImageView(
              data: widget.pix['texto_qr_code'] ?? '',
              version: QrVersions.auto,
              size: 200,
            ),
            const SizedBox(height: 16),
            SelectableText(widget.pix['texto_qr_code'] ?? '',
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: widget.pix['texto_qr_code']));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado!')));
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar código'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: globalPrimaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              'Expira em: ${_formatTime(seconds)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.redAccent),
            ),
          ]),
        ),
      ),
    );
  }
}
