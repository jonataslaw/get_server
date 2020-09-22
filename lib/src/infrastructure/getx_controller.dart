import 'dart:async';
import 'package:get_instance/get_instance.dart';
import 'package:get_server/src/context/context_response.dart';
import '../../get_server.dart';

class GetxController extends DisposableInterface {
  BuildContext _context;
  void setContext(BuildContext c) {
    _context = c;
  }

  ContextResponse get response => _context.response;
  ContextRequest get request => _context.request;
  Map<String, dynamic> get params => request.params;
}

/// Unlike GetxController, which serves to control events on each of its pages,
/// GetxService is not automatically disposed (nor can be removed with
/// Get.delete()).
/// It is ideal for situations where, once started, that service will
/// remain in memory, such as Auth control for example. Only way to remove
/// it is Get.reset().
abstract class GetxService extends DisposableInterface with GetxServiceMixin {}

abstract class DisposableInterface extends GetLifeCycle {
  bool _initialized = false;

  /// Checks whether the controller has already been initialized.
  bool get initialized => _initialized;

  DisposableInterface() {
    onStart.callback = _onStart;
  }

  // Internal callback that starts the cycle of this controller.
  void _onStart() {
    onInit();
    _initialized = true;
    Future.delayed(Duration.zero, () => onReady());
  }

  /// Called immediately after the widget is allocated in memory.
  /// You might use this to initialize something for the controller.
  @override
  void onInit() {}

  /// Called 1 frame after onInit(). It is the perfect place to enter
  /// navigation events, like snackbar, dialogs, or a new route, or
  /// async request.
  @override
  void onReady() async {}

  /// Called before [onDelete] method. [onClose] might be used to
  /// dispose resources used by the controller. Like closing events,
  /// or streams before the controller is destroyed.
  /// Or dispose objects that can potentially create some memory leaks,
  /// like TextEditingControllers, AnimationControllers.
  /// Might be useful as well to persist some data on disk.
  @override
  FutureOr onClose() async {}
}
