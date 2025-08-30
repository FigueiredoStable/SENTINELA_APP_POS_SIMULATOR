import 'package:flutter/material.dart';

Widget paymentCountdownIndicator({required BuildContext context, required MediaQueryData mediaSize, required ValueNotifier<double> circleCount, required bool error}) {
  return SizedBox(
    width: mediaSize.size.width * 0.32,
    height: mediaSize.size.width * 0.32,
    child: ValueListenableBuilder(
      valueListenable: circleCount,
      builder: (context, value, child) {
        return CircularProgressIndicator(color: error ? Colors.red : Color(0xFF46DFB1), value: value, strokeWidth: 8);
      },
    ),
  );
  // return ValueListenableBuilder(
  //   valueListenable: circleCount,
  //   builder: (context, value, child) {
  //     return SizedBox(
  //       width: mediaSize.size.width * 0.43,
  //       height: mediaSize.size.width * 0.43,
  //       child: CircularProgressIndicator(color: error ? Colors.red : Color(0xFF46DFB1), value: value, strokeWidth: 12),
  //     );
  //   },
  // );
}
