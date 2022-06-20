import '../../get_server.dart';
import '../context/context_response.dart';

export '../framework/get_instance/src/bindings_interface.dart';
export '../framework/get_instance/src/extension_instance.dart';
export '../framework/get_instance/src/get_instance.dart';

class GetxController extends DisposableInterface {
  late BuildContext _context;
  void setContext(BuildContext c) {
    _context = c;
  }

  ContextResponse? get response => _context.response;
  ContextRequest get request => _context.request;
  Map<String?, dynamic>? get params => request.params;
}

/// Unlike GetxController, which serves to control events on each of its pages,
/// GetxService is not automatically disposed (nor can be removed with
/// Get.delete()).
/// It is ideal for situations where, once started, that service will
/// remain in memory, such as Auth control for example. Only way to remove
/// it is Get.reset().
abstract class GetxService extends DisposableInterface with GetxServiceMixin {}

abstract class DisposableInterface extends GetLifeCycle {}
