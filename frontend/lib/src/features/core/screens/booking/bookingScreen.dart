import 'dart:math';
import 'package:clubedaareia/src/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'dart:ui' as ui;
import 'dart:ui' as ui
    show
        FontLoader,
        instantiateImageCodec,
        PictureRecorder,
        Canvas,
        ImageByteFormat;
import 'package:flutter/services.dart' show rootBundle;

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../constants/constants.dart';
import '../../../../utils/dateInverter.dart';
import '../../../../utils/share/shareError.dart'
    if (dart.library.html) '../../../../utils/share/shareWeb.dart'
    if (dart.library.io) '../../../../utils/share/shareMobile.dart';

import 'widgets/bookingBody.dart';
import 'widgets/bookingFooter.dart';
import 'widgets/bookingHeader.dart';

class BookingScreen extends StatefulWidget {
  BookingScreen({super.key});

  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final GlobalKey _shareKey = GlobalKey();
  bool _captureMode = false;

  dynamic courtData = [];
  List<String> selectedSlots = [];
  DateTime date = DateTime.now();
  double totalPrice = 0;
  late int idPlace;
  late int idModalityPlace;
  late dynamic allModalitiesIds;
  final String urlBase = constants.urlApi;
  List<String> freeSlotsShare = [];
  late int idClient;

  @override
  void initState() {
    super.initState();
    // Verifica se Get.arguments é null e redireciona para a página /home
    if (Get.arguments == null) {
      Future.microtask(() => Get.offNamed('/home'));
    } else {
      setState(() {
        courtData = Get.arguments;
        idPlace = courtData['courtId'];
        idModalityPlace = courtData['courtsModalityId'];
        allModalitiesIds = courtData['allModalitiesIds'];
        idClient = courtData['idClient'];
      });
    }
  }

  void toggleCurrentDate(DateTime currentDate) {
    setState(() {
      date = currentDate;
    });
    newTotalPrice();
  }

  void toggleSlotSelection(String slot, double slotPrice) {
    setState(() {
      if (selectedSlots.contains(slot)) {
        selectedSlots.remove(slot);
        decreaseTotalPrice(slotPrice);
      } else {
        selectedSlots.add(slot);
        increaseTotalPrice(slotPrice);
      }
    });
  }

  void increaseTotalPrice(double price) {
    setState(() {
      totalPrice += price;
    });
  }

  void decreaseTotalPrice(double price) {
    setState(() {
      totalPrice -= price;
    });
  }

  void newTotalPrice() {
    setState(() {
      totalPrice = 0;
    });
  }

  void resetSelectedSlots() {
    setState(() {
      selectedSlots.clear();
    });
  }

  Future<void> createImageAndShare() async {
    final logoUrl = '${urlBase}clients/getLogo/$idClient';
    final response = await http.get(Uri.parse(logoUrl));
    final Uint8List logoBytes = response.bodyBytes;

    final imageBytes = await createCustomImage(
      courtName: courtData['courtName'],
      freeSlots: freeSlotsShare,
      date: dateReverter(date.toString().split(' ')[0]),
      courtImageBytes: logoBytes,
      logoBytes: await rootBundle
          .load('assets/images/logo-placeholder.png')
          .then((b) => b.buffer.asUint8List()),
    );
    shareImplementation(imageBytes);
  }

  Future<Uint8List> createCustomImage({
    int width = 1080,
    int height = 1920,
    required String courtName,
    required List<String> freeSlots,
    required String date,
    required Uint8List courtImageBytes,
    required Uint8List logoBytes,
  }) async {
    // Formata a data
    final inputFormat = DateFormat('dd/MM/yyyy');
    final outputFormat = DateFormat("EEEE, dd 'de' MMMM 'de' yyyy", 'pt_BR');
    final parsedDate = inputFormat.parse(date);
    final formattedDate = outputFormat.format(parsedDate);

    // Escalas
    final iconSize = height * 0.035;
    final chipH = height * 0.045;
    final imageSize = width * 0.28;
    final logoSize = width * 0.2;

    // Imagens
    final codec = await ui.instantiateImageCodec(courtImageBytes,
        targetWidth: imageSize.toInt());
    final courtImage = (await codec.getNextFrame()).image;

    final logoCodec = await ui.instantiateImageCodec(logoBytes,
        targetWidth: logoSize.toInt());
    final logoImage = (await logoCodec.getNextFrame()).image;

    // Canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
        recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = Colors.white);

    final titleStyle = GoogleFonts.poppins(
      fontSize: height * 0.045,
      fontWeight: FontWeight.bold,
      color: globalPrimaryColor,
    );
    final dateStyle = GoogleFonts.poppins(
      fontSize: height * 0.035,
      fontWeight: FontWeight.w500,
      color: Colors.grey[800],
    );
    final labelStyle = GoogleFonts.poppins(
      fontSize: height * 0.032,
      color: Colors.grey[800],
    );
    final chipStyle = GoogleFonts.poppins(
      fontSize: height * 0.027,
      color: Colors.white,
    );
    final iconStyle = TextStyle(
      fontFamily: 'MaterialIcons',
      fontSize: iconSize,
      color: Colors.grey[800],
    );

    double y = height * 0.06;

    // Título da quadra
    final tpIcon = TextPainter(
      text: TextSpan(
          text: String.fromCharCode(Icons.sports_tennis.codePoint),
          style: iconStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tpIcon.paint(canvas, Offset(30, y));

    final tpTitle = TextPainter(
      text: TextSpan(text: '  $courtName', style: titleStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: width - imageSize - 60);
    tpTitle.paint(canvas,
        Offset(30 + tpIcon.width, y + (tpIcon.height - tpTitle.height) / 2));

    // Imagem da quadra no canto superior direito
    canvas.drawImage(courtImage, Offset(width - imageSize - 30, y), Paint());

    y += tpTitle.height + height * 0.04;

    // Data com ícone
    final dateIcon = TextPainter(
      text: TextSpan(
          text: String.fromCharCode(Icons.calendar_today.codePoint),
          style: iconStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    dateIcon.paint(canvas, Offset(30, y + 6));

    final tpDate = TextPainter(
      text: TextSpan(text: '  $formattedDate', style: dateStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: width - imageSize - 60);
    tpDate.paint(canvas, Offset(30 + dateIcon.width, y));

    y += tpDate.height + height * 0.05;

    // Título "Horários Livres"
    final tpSlotsTitle = TextPainter(
      text: TextSpan(
          text: 'Horários Livres',
          style: labelStyle.copyWith(fontSize: height * 0.04)),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tpSlotsTitle.paint(canvas, Offset(30, y));

    y += tpSlotsTitle.height + height * 0.025;

    // Chips
    double cx = 30;
    for (var slot in freeSlots) {
      final tpMeasure = TextPainter(
        text: TextSpan(text: slot, style: chipStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final chipW = tpMeasure.width + iconSize + 36;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx, y, chipW, chipH),
        Radius.circular(20),
      );
      canvas.drawRRect(rrect, Paint()..color = globalPrimaryColor!);

      final tpChipIcon = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.schedule.codePoint),
          style: iconStyle.copyWith(
              color: Colors.white, fontSize: iconSize * 0.75),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tpChipIcon.paint(
          canvas, Offset(cx + 12, y + (chipH - tpChipIcon.height) / 2));

      final tpChipText = TextPainter(
        text: TextSpan(text: '  $slot', style: chipStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: chipW - 24);
      tpChipText.paint(
          canvas,
          Offset(
              cx + 12 + tpChipIcon.width, y + (chipH - tpChipText.height) / 2));

      cx += chipW + 16;
      if (cx + chipW > width - 30) {
        cx = 30;
        y += chipH + 16;
      }
    }

    // Logo no canto inferior direito
    canvas.drawImage(
        logoImage,
        Offset(
            width - logoSize - 30, height - logoImage.height.toDouble() - 30),
        Paint());

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void onUpdateSlots(List<String> freeSlots) {
    freeSlotsShare = Set<String>.from(freeSlots).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Verifica novamente durante a construção para garantir a consistência
    if (courtData == null) {
      return Container(); // Retorna um widget vazio enquanto redireciona
    }

    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BookingHeader(
              courtData: courtData,
              onSharePressed: createImageAndShare, //_captureAndSharePng,
            ),
            RepaintBoundary(
              key: _shareKey,
              child: Container(
                color: _captureMode ? Colors.white : Colors.transparent,
                child: Stack(
                  children: [
                    BookingBody(
                      onUpdateSlots: onUpdateSlots,
                      toggleCurrentDate: toggleCurrentDate,
                      toggleSlotSelection: toggleSlotSelection,
                      selectedSlots: selectedSlots,
                      resetSelectedSlots: resetSelectedSlots,
                      courtData: courtData,
                    ),
                    if (_captureMode)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Image.network(
                          '${urlBase}clients/getLogo/1',
                          width: 150,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'images/logo-placeholder.png',
                              width: 150,
                              height: 100,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BookingFooter(
          selectedSlots: selectedSlots,
          courtData: courtData,
          date: date,
          totalPrice: totalPrice,
          idPlace: idPlace,
          idModalityPlace: idModalityPlace,
          allModalitiesIds: allModalitiesIds,
        ),
      ),
    );
  }
}
