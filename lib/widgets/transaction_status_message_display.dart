import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

Widget transactionStatusMessageDisplay({required BuildContext context, required MediaQueryData mediaSize, required String message}) {
  return Container(
    width: mediaSize.size.width * 0.90,
    //height: 120,
    padding: EdgeInsets.symmetric(horizontal: 24),
    margin: EdgeInsets.only(bottom: 24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Color(0xFF213A58), width: 6),
      color: Color(0xFFC8F5FF),
    ),
    child: Center(
      child: AutoSizeText(
        message.toString().toUpperCase(),
        style: TextStyle(color: Color(0xFF213A58), fontSize: 18, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        softWrap: true,
        minFontSize: 14,
        maxFontSize: 18,
      ),
    ),
  );
}
