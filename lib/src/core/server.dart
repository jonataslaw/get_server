library server;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:get_instance/get_instance.dart';
import 'package:get_server/src/context/context_request.dart';
import 'package:get_server/src/context/context_response.dart';
import 'package:http_server/http_server.dart';
import 'package:isolate/isolate.dart';

import 'package:meta/meta.dart';
import '../socket/socket.dart';
import '../routes/route.dart';
import '../routes/get_page.dart';
import 'src/utils/token_util.dart';

part 'src/server_main.dart';
part 'src/server_config.dart';
part 'src/node_mode_mixin.dart';
part 'widgets/widget.dart';
part 'widgets/custom.dart';

final _listRoutes = <Route>[];

Route _findRoute(HttpRequest req) {
  // print('_listRoutes id: ${_listRoutes.hashCode}');
  final route = _listRoutes.firstWhere(
    (route) => route.match(req),
    orElse: () => null,
  );
  if (route == null) {
    Get.log('Route length: ${_listRoutes.length}');
  }
  return route;
}

void _addRoute(Route route) {
  _listRoutes.add(route);
}
