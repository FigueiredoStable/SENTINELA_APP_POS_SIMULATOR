import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:sentinela_app_pos_simulator/models/api_initialization_global_settings_model.dart';

Widget supportInfoCard(BuildContext context, SupportInformation data) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF213A58), Color(0xFF0C6478)], begin: Alignment(0.2, 1), end: Alignment(-0.2, -1)),
      borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), spreadRadius: 2, blurRadius: 20, offset: Offset(0, -3))],
    ),
    child: Column(
      children: [
        AutoSizeText(
          data.title!,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 1,
          minFontSize: 14,
          maxFontSize: 21,
        ),
        AutoSizeText(
          data.message!,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white, height: 1),
          textAlign: TextAlign.center,
          maxLines: 4,
          minFontSize: 12,
          maxFontSize: 16,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone, color: Colors.white),
            SizedBox(width: 8),
            AutoSizeText(data.contact!, style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.white), maxLines: 1, minFontSize: 12, maxFontSize: 18),
          ],
        ),
      ],
    ),
  );
}
