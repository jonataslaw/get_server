library socket;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:get_server/src/framework/get_core/get_core.dart';

part 'socket_impl.dart';
part 'socket_interface.dart';
part 'socket_notifier.dart';

extension FirstWhereExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
