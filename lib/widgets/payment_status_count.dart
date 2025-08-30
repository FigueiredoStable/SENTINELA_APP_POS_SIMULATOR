import 'package:flutter/material.dart';
import 'package:sentinela_app_pos_simulator/src/pages/payment/payment_controller.dart';
import 'package:sentinela_app_pos_simulator/widgets/payment_count_label.dart';
import 'package:sentinela_app_pos_simulator/widgets/payment_countdown_indicator.dart';

Widget paymentStatusCount({
  required BuildContext context,
  required MediaQueryData mediaSize,
  required PaymentViewController controller,
  required Gradient gradient,
  required int count,
}) {
  // controller.startCountDownToExecuteFunction(count, () {
  //   controller.backToHome();
  //   controller.cancelPayment();
  // });

  return Stack(
    alignment: AlignmentDirectional.center,
    children: [
      ValueListenableBuilder(
        valueListenable: controller.circleCount,
        builder: (context, value, child) {
          if (controller.cancelCount == false) {
            return paymentCountdownIndicator(context: context, mediaSize: mediaSize, circleCount: controller.circleCount, error: controller.viewStateError.value);
          } else {
            return SizedBox();
          }
        },
      ),
      ValueListenableBuilder(
        valueListenable: controller.countMessage,
        builder: (context, value, child) {
          if (controller.cancelCount == false) {
            return paymentCountLabel(context: context, mediaSize: mediaSize, countMessage: controller.countMessage, error: controller.viewStateError.value);
          } else {
            return SizedBox();
          }
        },
      ),
    ],
  );
}
