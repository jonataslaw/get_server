import 'dart:io';

import 'package:get_server/get_server.dart';

import '../../get_server.dart';

// this this widget to make pagination simple and easy
// ignore: must_be_immutable
class Pageable extends GetWidget {
  final List<dynamic> list;
  int page;
  int size;
  Pageable(this.list, {this.page = 1, this.size = 10});

  @override
  Widget build(BuildContext context) {
    var pageparam = context.param('page');
    if (pageparam != null) {
      var newPage = int.tryParse(pageparam);
      if (newPage == null) {
        context.response!.status(HttpStatus.badRequest).sendJson(_Erro(
            errocode: HttpStatus.badRequest,
            description:
                'The page parameter must receive an int: $pageparam it\'s not an int'));
        return WidgetEmpty();
      }
      page = newPage;
    }

    var sizeparam = context.param('size');
    if (sizeparam != null) {
      var newSize = int.tryParse(sizeparam);
      if (newSize == null) {
        context.response!.status(HttpStatus.badRequest).sendJson(_Erro(
            errocode: HttpStatus.badRequest,
            description:
                'The size parameter must receive an int: $sizeparam it\'s not an int'));
        return WidgetEmpty();
      }
      size = newSize;
    }

    final fistElement = (page - 1) * size;
    final lastElement = page * size;

    var totalPages = (list.length / size).ceil();
    totalPages = totalPages == 0 ? 1 : totalPages;

    if (totalPages < page) {
      context.response!.status(HttpStatus.badRequest).sendJson(_Erro(
          errocode: HttpStatus.badRequest,
          description:
              'The reported page is larger than the maximum page: report something between 1 and $totalPages'));
      return WidgetEmpty();
    }

    final result = list.sublist(
        fistElement, lastElement > list.length ? list.length : lastElement);

    dynamic pageable = _Pageable(
        content: result,
        currentPage: page,
        size: size,
        totalElements: list.length,
        totalPages: totalPages);

    return Json(pageable);
  }
}

class _Pageable {
  List<dynamic>? content;
  int? size;
  int? totalElements;
  int? totalPages;
  int? currentPage;

  _Pageable(
      {this.content,
      this.size,
      this.totalElements,
      this.totalPages,
      this.currentPage});

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (content != null) {
      if (content is List<String> ||
          content is List<num> ||
          content is List<bool> ||
          content is List<DateTime>) {
        data['content'] = content;
      } else {
        data['content'] = content!.map((v) => v).toList();
      }
    }
    data['size'] = size;
    data['totalElements'] = totalElements;
    data['totalPages'] = totalPages;
    data['currentPage'] = currentPage;
    return data;
  }
}

class _Erro {
  int? errocode;
  String? description;

  _Erro({this.errocode, this.description});

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['errocode'] = errocode;
    data['description'] = description;
    return data;
  }
}
