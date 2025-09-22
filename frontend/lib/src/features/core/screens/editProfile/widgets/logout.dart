import 'package:clubedaareia/src/utils/logout.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Logout extends StatefulWidget {
  const Logout({super.key});

  @override
  State<Logout> createState() => _LogoutState();
}

class _LogoutState extends State<Logout> {
  bool hoverLogout = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 35, right: 15),
      child: Align(
        alignment: Alignment.centerRight,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (h) {
            setState(() {
              hoverLogout = true;
            });
          },
          onExit: (h) {
            setState(() {
              hoverLogout = false;
            });
          },
          child: GestureDetector(
              onTap: () => logout(),
              child: Row(
                children: [
                  Icon(Icons.logout,
                      color: hoverLogout ? Colors.black : Colors.white),
                  const SizedBox(width: 5),
                  Text("Sair",
                      style: GoogleFonts.indieFlower(
                          fontSize: 22,
                          textStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: hoverLogout ? Colors.black : Colors.white
                          )
                      )
                  )
              ]
            )
          ),
        ),
      ),
    );
  }
}
