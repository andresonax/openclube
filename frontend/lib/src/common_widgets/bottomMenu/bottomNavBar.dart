import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/bottomNavBarMenuEnum.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.selectedMenu,
  });

  final MenuState selectedMenu;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Stack(
      alignment: AlignmentDirectional.bottomCenter,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          height: size.height * kSizeBottomNavBar,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem(
                iconPath: 'assets/icons/home.svg',
                label: 'Início',
                isActive: MenuState.home == selectedMenu,
                onTap: () => Get.offAndToNamed("/home"),
              ),
              _buildNavBarItem(
                iconPath: 'assets/icons/chat.svg',
                label: 'Chat',
                isActive: MenuState.chat == selectedMenu,
                onTap: () => Get.offAndToNamed("/chat"),
              ),
              _buildNavBarItem(
                iconPath: 'assets/icons/agenda.svg',
                label: 'Minha Agenda',
                isActive: MenuState.myAgenda == selectedMenu,
                onTap: () => Get.offAndToNamed("/myAgenda"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavBarItem({
    required String iconPath,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 25,
            colorFilter: ColorFilter.mode(
              isActive
                  ? kBottomNavBarActiveIconColor
                  : kBottomNavBarInactiveIconColor,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(
              height: 5), // Add some spacing between the icon and the label
          Text(
            label,
            style: GoogleFonts.indieFlower(
              textStyle: TextStyle(
                color: isActive
                    ? kBottomNavBarActiveIconColor
                    : kBottomNavBarInactiveIconColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
