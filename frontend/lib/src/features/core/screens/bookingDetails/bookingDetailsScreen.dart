import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'widgets/bookingDetailsBody.dart';
import 'widgets/bookingDetailsHeader.dart';

class BookingDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;

    if (args == null) {
      Future.microtask(() => Get.offNamed('/home'));
      return Container();
    }

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BookingDetailsHeader(),
              BookingDetailsBody(
                date: args['date'],
                local: args['local'],
                basePrice: args['basePrice'],
                selectedSlots: args['selectedSlots'],
                courtData: args['courtData'],
                materials: args['materials'],
                materialsIds: args['materialsIds'],
                materialsPrices: args['materialsPrices'],
                materialsQuantities: args['materialsQuantities'],
                paymentMethods: args['paymentMethods'],
                paymentConditions: args['paymentConditions'],
                idPlace: args['idPlace'],
                idModalityPlace: args['idModalityPlace']
              ),
            ],
          ),
        ),
      ),
    );
  }
}
