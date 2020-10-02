import 'dart:convert';
import 'dart:io';

import 'package:get_server/get_server.dart';

// this this widget to make pagination simple and easy
class Pageable extends GetWidget {
  List<dynamic> list;
  int page;
  int size;
  Pageable(this.list, {this.page = 1, this.size = 10});

  @override
  Widget build(BuildContext context) {
    String pageparam = context.param('page');
    if (pageparam != null) {
      int _page = int.parse(pageparam, onError: (_) => null);
      if (_page == null) {
        context.response.status(HttpStatus.badRequest).sendJson(_Erro(
            errocode: HttpStatus.badRequest,
            description:
                'The page parameter must receive an int: $pageparam it\'s not an int'));
        return null;
      }
      page = _page;
    }

    String sizeparam = context.param('size');
    if (sizeparam != null) {
      int _size = int.parse(sizeparam, onError: (_) => null);
      if (_size == null) {
        context.response.status(HttpStatus.badRequest).sendJson(_Erro(
            errocode: HttpStatus.badRequest,
            description:
                'The size parameter must receive an int: $sizeparam it\'s not an int'));
        return null;
      }
      size = _size;
    }

    final fistElement = (page - 1) * size;
    final lastElement = page * size;

    int totalPages = (list.length / size).ceil();
    totalPages = totalPages == 0 ? 1 : totalPages;

    if (totalPages < page) {
      context.response.status(HttpStatus.badRequest).sendJson(_Erro(
          errocode: HttpStatus.badRequest,
          description:
              'The reported page is larger than the maximum page: report something between 1 and $totalPages'));
      return null;
    }

    final result = list.sublist(
        fistElement, lastElement > list.length ? list.length : lastElement);

    final pageable = _Pageable(
        content: result,
        currentPage: page,
        size: size,
        totalElements: list.length,
        totalPages: totalPages);

    return Json(pageable);
  }
}

class _Pageable {
  List<dynamic> content;
  int size;
  int totalElements;
  int totalPages;
  int currentPage;

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
        data['content'] = content.map((v) => v.toJson()).toList();
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
  int errocode;
  String description;

  _Erro({this.errocode, this.description});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['errocode'] = this.errocode;
    data['description'] = this.description;
    return data;
  }
}
