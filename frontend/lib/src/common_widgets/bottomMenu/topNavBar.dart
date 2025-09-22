import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class TopNavBar extends StatefulWidget {
  final String route;
  final String backButtonText;

  const TopNavBar({
    Key? key,
    required this.route,
    required this.backButtonText,
  }) : super(key: key);

  @override
  _TopNavBarState createState() => _TopNavBarState();
}
  
class _TopNavBarState extends State<TopNavBar> {
  bool hoverBack = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 35, left: 15),
      child: Align(
        alignment: Alignment.centerLeft,
        child: MouseRegion(
          onEnter: (_) => setState(() => hoverBack = true),
          onExit: (_) => setState(() => hoverBack = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Get.toNamed(widget.route),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_circle_left_outlined,
                  color: hoverBack ? Colors.orange : Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  widget.backButtonText,
                  style: GoogleFonts.indieFlower(
                    textStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: hoverBack ? Colors.orange : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
