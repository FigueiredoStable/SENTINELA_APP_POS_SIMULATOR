import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:sentinela_app_pos_simulator/enums/payment_view_type.dart';
import 'package:sentinela_app_pos_simulator/src/pages/payment/payment_controller.dart';
import 'package:sentinela_app_pos_simulator/utils/constants.dart';

Widget paymentTopInfo({
  required BuildContext context,
  required MediaQueryData mediaSize,
  required PaymentViewTypeEnum selectedType,
  required String price,
  required String credits,
  required PaymentViewController controller,
}) {
  return Container(
    margin: EdgeInsets.only(top: 12),
    child: Stack(
      alignment: AlignmentDirectional.topCenter,
      children: [
        SizedBox(width: mediaSize.size.width * 0.9, height: 155),
        Positioned(
          top: 30,
          child: Container(
            height: 90,
            width: mediaSize.size.width * 0.9,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              gradient: Constants.lightGradient,
            ),
            padding: EdgeInsets.fromLTRB(42, 30, 42, 12),
            child: Center(
              child: Column(
                children: [
                  AutoSizeText(
                    price,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    minFontSize: 28,
                    maxFontSize: 32,
                  ),
                ],
              ),
            ),
          ),
        ),

        Container(
          //height: 70,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            gradient: Constants.darkGradient,
          ),
          child: Column(
            children: [
              AutoSizeText(
                credits.toString(),
                style: Theme.of(context).textTheme.headlineLarge!.copyWith(color: Colors.white, fontWeight: FontWeight.bold, height: 1),
                textAlign: TextAlign.center,
                maxLines: 1,
                minFontSize: 16,
                maxFontSize: 20,
              ),
              if (credits != "1")
                AutoSizeText(
                  "CRÉDITOS",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.white),
                  minFontSize: 14,
                  maxFontSize: 18,
                ),
              if (credits == "1")
                AutoSizeText(
                  "CRÉDITO",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.white),
                  maxLines: 1,
                  minFontSize: 14,
                  maxFontSize: 18,
                ),
            ],
          ),
        ),

        Visibility(
          visible: selectedType == PaymentViewTypeEnum.SELECT,
          child: Positioned(
            top: 125,
            child: AutoSizeText(
              PaymentViewTypeEnum.SELECT.description,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                height: 1,
                shadows: [Shadow(blurRadius: 8.0, color: Colors.black.withAlpha(100), offset: Offset(2, 2))],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              minFontSize: 16,
              maxFontSize: 18,
            ),
          ),
        ),

        Visibility(
          visible: selectedType != PaymentViewTypeEnum.SELECT,
          child: Positioned(
            top: 105,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                gradient: Constants.darkGradient,
              ),
              child: AutoSizeText(
                selectedType.description,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1,
                  shadows: [Shadow(blurRadius: 8.0, color: Colors.black.withAlpha(100), offset: Offset(2, 2))],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                minFontSize: 21,
                maxFontSize: 26,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
