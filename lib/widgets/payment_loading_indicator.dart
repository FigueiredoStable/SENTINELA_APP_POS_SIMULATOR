import 'package:flutter/material.dart';

Widget paymentLoadingIndicator({required BuildContext context, required MediaQueryData mediaSize, required bool error}) {
  return SizedBox(
    width: mediaSize.size.width * 0.43,
    height: mediaSize.size.width * 0.43,
    child: CircularProgressIndicator(color: Color(0xFF46DFB1), strokeWidth: 12),
  );
}
