import 'package:flutter/material.dart';

class BlockedView extends StatelessWidget {
  const BlockedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Column(
        children: [
          Text('Sentinela Bloqueada'),
          Text('Entre em contato com a Spolus'),
        ],
      )),
    );
  }
}
