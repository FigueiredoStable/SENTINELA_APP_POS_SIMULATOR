import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:sentinela_app_pos_simulator/models/sentinela_spolus_app_infos_model.dart';
import 'package:sentinela_app_pos_simulator/utils/constants.dart';

Widget statusBall(Color color, {double size = 12.0}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: Border.all(color: Colors.white, width: 1),
    ),
  );
}

Widget appInfoCard(BuildContext context, SentinelaSpolusAppInfosModel data, ValueNotifier<Color> sentinelaGlobalStatusColor) {
  return ValueListenableBuilder(
    valueListenable: sentinelaGlobalStatusColor,
    builder: (context, value, child) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          gradient: Constants.darkGradient,
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), spreadRadius: 2, blurRadius: 20, offset: Offset(0, -3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AutoSizeText(
                  "Spolus Soluções em Tecnologia - ",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  minFontSize: 10,
                  maxFontSize: 12,
                ),
                AutoSizeText(
                  "Versão: ",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  minFontSize: 10,
                  maxFontSize: 12,
                ),
                AutoSizeText(
                  "${data.version!}+${data.buildNumber!}",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  minFontSize: 10,
                  maxFontSize: 12,
                ),
              ],
            ),
            Visibility(
              visible: value != Colors.transparent,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [statusBall(value)]),
            ),
          ],
        ),
      );
    },
  );
}
