import 'package:flutter/material.dart';
import 'package:sentinela_app_pos_simulator/utils/utils.dart';

Widget selectButtonValueToPay({
  required BuildContext context,
  required MediaQueryData mediaSize,
  required final Function()? onPressed,
  required String credits,
  required String price,
}) {
  return Material(
    color: Colors.transparent, // garante que o ripple funcione
    elevation: 10,
    shadowColor: Colors.black,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: () {
        Feedback.forTap(context); // reação tátil
        onPressed?.call();
      },
      borderRadius: BorderRadius.circular(20),
      // ignore: deprecated_member_use
      splashColor: Colors.white.withOpacity(0.2), // personaliza splash se quiser
      child: Ink(
        width: mediaSize.size.width * 0.90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF46DFB1)),
          gradient: LinearGradient(colors: [Color(0xFF213A58), Color(0xFF0C6478)], begin: Alignment(0.2, 1), end: Alignment(-0.2, -1)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Text(
                credits,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      credits == "1" ? 'CRÉDITO' : 'CRÉDITOS',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                      gradient: const LinearGradient(colors: [Color(0xFF158992), Color(0xFF09D1C7)], begin: Alignment(0.2, 1), end: Alignment(-0.2, -1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            Utils.formatBRLMoney(double.parse(price)),
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30),
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
