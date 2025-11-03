import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/routing/appRoutes.dart';
import 'src/features/authentication/screens/initialPage/initialPage.dart';

import 'package:upgrader/upgrader.dart';

void main() async {
  //utilizado para verificar se user está logado
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(sharedPreferences);
  runApp(const ClubeDaAreia());
}

class ClubeDaAreia extends StatelessWidget {
  const ClubeDaAreia({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert( 
      showIgnore: false,
      showLater: false,
      child: GetMaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
        ],
        supportedLocales: const [Locale("pt"), Locale("BR")],
        initialRoute: '/',
        getPages: appRoutes(),
        debugShowCheckedModeBanner: false,
      )
    );
  }
}
