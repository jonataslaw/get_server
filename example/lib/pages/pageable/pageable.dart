import 'package:get_server/get_server.dart';

import 'pageable_controller.dart';

class PageablePage extends GetView {
  final ctl = PageableController();
  @override
  Widget build(BuildContext context) {
    return Pageable(ctl.lista, page: 2, size: 4);
  }
}
