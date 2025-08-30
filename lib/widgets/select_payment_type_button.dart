import 'package:flutter/material.dart';

// Widget selectPaymentTypeButton({required BuildContext context, required Function() onPressed, required String type, required Gradient gradient}) {
//   return InkWell(
//     onTap: onPressed,
//     child: Ink(
//       padding: EdgeInsets.symmetric(vertical: 20),
//       width: double.infinity,
//       decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Color(0xFF46DFB1)), gradient: gradient),
//       child: Text(type, style: Theme.of(context).textTheme.headlineLarge!.copyWith(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
//     ),
//   );
// }

Widget selectPaymentTypeButton({required BuildContext context, required Function() onPressed, required String type, required Gradient gradient}) {
  return Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onPressed,
      child: Ink(
        padding: EdgeInsets.symmetric(vertical: 20),
        width: double.infinity,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Color(0xFF46DFB1)), gradient: gradient),
        child: Text(type, style: Theme.of(context).textTheme.headlineLarge!.copyWith(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ),
    ),
  );
}
