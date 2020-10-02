import 'package:get_server/get_server.dart';

import 'pageable_repository.dart';

class PageableController extends GetxController {
  final PageableRepository repo = PageableRepository();

  List get lista => repo.list;
}
