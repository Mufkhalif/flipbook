// ignore_for_file: depend_on_referenced_packages

import 'dart:developer';
import 'package:stack_trace/stack_trace.dart';

class Log {
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _reset = '\x1B[0m';

  static void info(dynamic val) {
    // if (!Config.isLogEnable) return;
    log(_printFormat('i', val));
  }

  static void error(dynamic val) {
    // if (!Config.isLogEnable) return;
    log('$_red${_printFormat('e', val)}$_reset');
  }

  static void colorGreen(dynamic val) {
    // if (!Config.isLogEnable) return;
    log('$_green${_printFormat('i', val)}$_reset');
  }

  static void errorTrace(dynamic val, Function(String traceLocation) action) {
    String? location = Trace.current().frames[1].location;
    String msg = 'iT [$location] => $val';
    log('$_red $msg $_reset');
    action(location);
  }

  static String _printFormat(String type, dynamic val) {
    // DateTime d = DateTime.now();
    // String dt = '${d.hour}:${d.minute}:${d.second}:${d.millisecond}';
    // String? caller = Trace.current().frames[2].member;
    String? location = Trace.current().frames[2].location;
    return '$type [$location] => $val';
  }
}
