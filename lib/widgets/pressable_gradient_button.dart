import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class PressableGradientButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String type;
  final Gradient gradient;

  const PressableGradientButton({super.key, required this.onPressed, required this.type, required this.gradient});

  @override
  State<PressableGradientButton> createState() => _PressableGradientButtonState();
}

class _PressableGradientButtonState extends State<PressableGradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(20),
          color: Colors.transparent,
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF46DFB1)),
              gradient: widget.gradient,
            ),
            child: Center(
              child: AutoSizeText(
                widget.type,
                style: Theme.of(context).textTheme.headlineLarge!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                minFontSize: 16,
                maxFontSize: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
