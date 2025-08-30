import 'package:flutter/material.dart';

Widget paymentCountLabel({required BuildContext context, required MediaQueryData mediaSize, required ValueNotifier<int> countMessage, required bool error}) {
  return ValueListenableBuilder(
    valueListenable: countMessage,
    builder: (context, value, child) {
      return Positioned(
        top: 1,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            // color: Color(0xFF213A58),
            color: error ? Colors.red : Color(0xFF46DFB1),
          ),
          child: Center(child: Text(countMessage.value.toString(), style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
      );
    },
  );
}
