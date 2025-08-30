// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

class Constants {
  static const String AES_KEY_DECRYPT = 'ti7sahshei5zae2Xapah6Thei9soo4wo'; //* Chave de criptografia para descriptografar
  static const String AES_KEY_ENCRYPT = 'eitjig3Jo7Wee8eip4phe9atho7si-uc'; //* Chave de criptografia para criptografar

  static BoxDecoration buttonDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Color(0xFF46DFB1)),
    gradient: const LinearGradient(colors: [Color(0xFF213A58), Color(0xFF0C6478)], begin: Alignment(0.2, 1), end: Alignment(-0.2, -1)),
  );

  static LinearGradient darkGradient = LinearGradient(colors: [Color(0xFF213A58), Color(0xFF0C6478)], begin: Alignment(0.2, 1), end: Alignment(-0.2, -1));

  static LinearGradient lightGradient = LinearGradient(colors: [Color(0xFF158992), Color(0xFF09D1C7)], begin: Alignment(0.2, 1), end: Alignment(-0.2, -1));

  static LinearGradient buttonWhiteGradient = LinearGradient(colors: [Color(0xFF000000), Color(0xFFC2C5C0)], begin: Alignment(0.2, 1), end: Alignment(-0.2, -1));

  static LinearGradient kbackgroundGradient = LinearGradient(
    colors: [Color(0xFF80EE98), Color(0xFF47DDB0), Color(0xFF09D1C7), Color(0xFF15919B), Color(0xFF008080), Color(0xFF0C6478), Color(0xFF213A58)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration kIconCircleHolder = BoxDecoration(
    borderRadius: BorderRadius.circular(100),
    border: Border.all(color: Color(0xFF213A58), width: 6),
    color: Color(0xFFC8F5FF),
  );

  static LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFB71C1C), Color(0xFFE53935)], // vermelho escuro → vermelho médio
    begin: Alignment(0.2, 1),
    end: Alignment(-0.2, -1),
  );

  static LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)], // vermelho intenso ao escuro
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFF7043), Color(0xFFFF7043)], // laranja claro ao forte
    begin: Alignment(0.2, 1),
    end: Alignment(-0.2, -1),
  );

  static LinearGradient offlineGradient = LinearGradient(
    colors: [Color(0xFFFFD54F), Color(0xFFFFB300)], // amarelo suave ao forte
    begin: Alignment(0.2, 1),
    end: Alignment(-0.2, -1),
  );

  static LinearGradient offGradient = LinearGradient(
    colors: [Color(0xFF757575), Color(0xFF212121)], // cinza claro ao escuro
    begin: Alignment(0.2, 1),
    end: Alignment(-0.2, -1),
  );

  static const Color spolusDarkTeal = Color(0xFF008080); // Azul Esverdeado (Teal)
}
