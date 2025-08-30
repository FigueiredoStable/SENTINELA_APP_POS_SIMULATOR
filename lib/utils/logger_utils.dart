import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class LongLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    const chunkSize = 800;
    for (var line in event.lines) {
      for (var i = 0; i < line.length; i += chunkSize) {
        debugPrint(line.substring(i, (i + chunkSize).clamp(0, line.length)));
      }
    }
  }
}
