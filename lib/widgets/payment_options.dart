import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sentinela_app_pos_simulator/src/pages/home/home_controller.dart';
import 'package:sentinela_app_pos_simulator/src/pages/payment/payment_controller.dart';
import 'package:sentinela_app_pos_simulator/widgets/pressable_gradient_button.dart';

Widget paymentOptions({required BuildContext context, required MediaQueryData mediaSize, required PaymentViewController controller, required Gradient gradient}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: mediaSize.size.width * 0.1),
    child: ListView.builder(
      shrinkWrap: true,
      itemCount: GetIt.I<HomeController>().paymentsTypesEnabled.types!.length,
      itemBuilder: (BuildContext context, index) {
        return Column(
          children: [
            if (GetIt.I<HomeController>().paymentsTypesEnabled.types![index].active!)
              PressableGradientButton(
                onPressed: () => controller.startPaymentSelected(GetIt.I<HomeController>().paymentsTypesEnabled.types![index].type!),
                type: GetIt.I<HomeController>().paymentsTypesEnabled.types![index].description!,
                gradient: gradient,
              ),
            SizedBox(height: 15),
          ],
        );
      },
    ),
  );
}
