import 'package:clubedaareia/src/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookingDetailsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 35, left: 15),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_circle_left_outlined),
            hoverColor: globalPrimaryColor,
            onPressed: () {
              Get.back();
            },
          ),
        ],
      ),
    );
  }
}
