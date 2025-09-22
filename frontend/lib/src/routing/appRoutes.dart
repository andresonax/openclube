import 'package:clubedaareia/src/constants/constants.dart';
import 'package:clubedaareia/src/features/core/screens/chat/clientChat.dart';
import 'package:clubedaareia/src/routing/routesMiddleware.dart';
import 'package:get/get.dart';

import '../features/core/screens/booking/bookingScreen.dart';
import '../features/core/screens/bookingDetails/bookingDetailsScreen.dart';
import '../features/core/screens/chat/chat.dart';
import '../features/core/screens/client/clientScreen.dart';
import '../features/core/screens/home/home.dart';
import '../features/core/screens/myAgenda/myAgenda.dart';
import '../features/authentication/screens/forgotPassword/forgotPassword.dart';
import '../features/authentication/screens/forgotPassword/insertToken.dart';
import '../features/authentication/screens/forgotPassword/updatePassword.dart';
import '../features/authentication/screens/initialPage/initialPage.dart';
import '../features/authentication/screens/login/loginScreen.dart';
import '../features/authentication/screens/signup/signUpScreen.dart';
import '../features/core/screens/editProfile/editProfile.dart';
import '../features/core/screens/verifyCity/verifyCity.dart';

List<GetPage> appRoutes() => [
      GetPage(
        name: '/',
        page: () => InitialPage(),
        middlewares: [ClientExclusiveMiddleware()],
        transition: Transition.noTransition,
        transitionDuration: const Duration(milliseconds: 300),
      ),
      GetPage(
        name: '/forgotPassword',
        page: () => forgotPassword(),
        transition: Transition.noTransition,
        transitionDuration: const Duration(milliseconds: 300),
      ),
      GetPage(
        name: '/insertToken',
        page: () => insertToken(),
        transition: Transition.noTransition,
        transitionDuration: const Duration(milliseconds: 300),
      ),
      GetPage(
        name: '/updatePassword',
        page: () => updatePassword(),
        transition: Transition.noTransition,
        transitionDuration: const Duration(milliseconds: 300),
      ),
      GetPage(
        name: '/signUp',
        page: () => signUpScreen(),
        transition: Transition.noTransition,
        transitionDuration: const Duration(milliseconds: 300),
      ),
      GetPage(
        name: '/login',
        page: () => loginScreen(),
        transition: Transition.noTransition,
        transitionDuration: const Duration(milliseconds: 300),
      ),
      GetPage(
        name: '/home',
        page: () => Home(),
        middlewares: [ClientExclusiveMiddleware(), VerifyCityMiddleware()],
        transition: Transition.noTransition,
        transitionDuration: const Duration(milliseconds: 300),
      ),
      GetPage(
        name: '/chat',
        page: () => Chat(),
        middlewares: [AuthMiddleware(), ClientExclusiveMiddleware()],
        transition: Transition.noTransition,
        transitionDuration: const Duration(milliseconds: 300),
      ),
      GetPage(
        name: '/chatArena/:id',
        page: () => ClientChat(),
        middlewares: [AuthMiddleware(), CorrectClientIdMiddleware()],
        transition: Transition.noTransition,
        transitionDuration: const Duration(milliseconds: 300),
      ),
      GetPage(
        name: '/myAgenda',
        page: () => MyAgenda(),
        middlewares: [AuthMiddleware()],
        transition: Transition.noTransition,
        transitionDuration: const Duration(milliseconds: 300),
      ),
      GetPage(
        name: '/client/:id',
        page: () => ClientScreen(),
        middlewares: [CorrectClientIdMiddleware(), VerifyLoginMiddleware(idClient: constants.idClient.toString())],
        transition: Transition.noTransition,
        transitionDuration: const Duration(milliseconds: 300),
      ),
      GetPage(
        name: '/editProfile',
        page: () => EditProfile(),
        middlewares: [AuthMiddleware()],
        transition: Transition.noTransition,
        transitionDuration: const Duration(milliseconds: 300),
      ),
      GetPage(
        name: '/booking',
        page: () => BookingScreen(),
        middlewares: [],
        transition: Transition.noTransition,
        transitionDuration: const Duration(milliseconds: 300),
      ),
      GetPage(
        name: '/bookingDetails',
        page: () => BookingDetailsScreen(),
        middlewares: [AuthMiddleware()],
        transition: Transition.noTransition,
        transitionDuration: const Duration(milliseconds: 300),
      ),
      GetPage(
        name: '/verifyCity',
        page: () => VerifyCity(),
        middlewares: [],
        transition: Transition.noTransition,
        transitionDuration: const Duration(milliseconds: 300),
      )
    ];

class MyMiddelware extends GetMiddleware {
  @override
  GetPage? onPageCalled(GetPage? page) {
    // print(page?.name);
    return super.onPageCalled(page);
  }
}
