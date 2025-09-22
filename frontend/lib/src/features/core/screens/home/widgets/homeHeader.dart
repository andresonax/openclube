import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeHeader extends StatefulWidget {
  final bool isLoggedIn;
  final List<dynamic> userData;

  const HomeHeader(
      {super.key, required this.isLoggedIn, required this.userData});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
  padding: const EdgeInsets.only(top: 20, bottom: 20),
  child: Row(
    children: [
      Image.asset(
        'assets/images/logo-placeholder.png',
        height: 80,
        width: 80,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          'Clube da Areia',
          style: GoogleFonts.indieFlower(
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
      if (widget.isLoggedIn)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Olá, ${widget.userData[0]['nome_completo'].toString().split(' ')[0]}",
              style: GoogleFonts.indieFlower(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                Get.toNamed('/editProfile', arguments: widget.userData);
              },
              child: const Icon(Icons.settings),
            ),
          ],
        )
      else
        TextButton(
          onPressed: () => Get.toNamed('/login'),
          child: Row(
            children: [
              Text(
                'Login',
                style: GoogleFonts.indieFlower(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.login_sharp, color: Colors.white),
            ],
          ),
        ),
    ],
  ),
);


  }
}
