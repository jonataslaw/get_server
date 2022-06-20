import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';

typedef DisposeCallback = void Function();

class ContextResponse {
  final HttpResponse _response;

  ContextResponse(this._response);

  dynamic header(String name, [Object? value]) {
    if (value == null) {
      return _response.headers[name];
    }
    _response.headers.set(name, value);
    return this;
  }

  DisposeCallback? _dispose;

  void addDisposeCallback(DisposeCallback disposer) {
    _dispose = disposer;
  }

  ContextResponse? get(String name) => header(name);

  ContextResponse? set(String name, String value) => header(name, value);

  ContextResponse? type(String contentType) => set('Content-Type', contentType);

  ContextResponse? cache(String cacheType, [Map<String, String>? options]) {
    options ??= {};
    final value = StringBuffer(cacheType);
    options.forEach((key, val) {
      value.write(', $key=$val');
    });
    return set('Cache-Control', value.toString());
  }

  ContextResponse status(int code) {
    _response.statusCode = code;
    return this;
  }

  // ContextResponse cookie(String name, String val, [Map options]) {
  //   var cookie = Cookie(
  //         Uri.encodeQueryComponent(name),
  //         Uri.encodeQueryComponent(val),
  //       ),
  //       cookieMirror = reflect(cookie);

  //   if (options != null) {
  //     options.forEach((option, value) {
  //       cookieMirror.setField(Symbol(option), value);
  //     });
  //   }

  //   _response.cookies.add(cookie);
  //   return this;
  // }

  // ContextResponse deleteCookie(String name) {
  //   final options = {'expires': 'Thu, 01-Jan-70 00:00:01 GMT', 'path': '/'};
  //   return cookie(name, '', options);
  // }

  ContextResponse cookie(String name, String val) {
    var cookie = Cookie(
      Uri.encodeQueryComponent(name),
      Uri.encodeQueryComponent(val),
    );

    _response.cookies.add(cookie);
    return this;
  }

  ContextResponse deleteCookie(String name) {
    //  final options = {'expires': 'Thu, 01-Jan-70 00:00:01 GMT', 'path': '/'};
    return cookie(name, '');
  }

  ContextResponse add(String string) {
    _response.write(string);
    return this;
  }

  ContextResponse? attachment(String filename) {
    return set('Content-Disposition', 'attachment; filename="$filename"');
  }

  ContextResponse? mime(String path) {
    var mimeType = lookupMimeType(path);
    if (mimeType != null) {
      return type(mimeType);
    }
    return this;
  }

  Future send(Object string) async {
    _response.write(string);
    return close();
  }

  Future sendJson(Object? data) {
    // if (data is Map || data is List) {
    //   data = jsonEncode(data);
    // }

    // if (get('Content-Type') == null) {
    //   type('application/json');
    // }

    // create a temporary solution
    _response.headers.set('Content-Type', 'application/json; charset=UTF-8');
    _response.write(jsonEncode(data));
    return close();
  }

  Future sendHtmlText(Object data) {
    _response.headers.set('Content-Type', 'text/html; charset=UTF-8');
    _response.write(data);
    return close();
  }

  Future sendFile(String path) {
    var file = File(path);

    return file
        .exists()
        .then((found) => found ? found : throw 404)
        .then((_) => file.length())
        .then((length) => header('Content-Length', length))
        .then((_) => mime(file.path))
        .then((_) => file.openRead().pipe(_response))
        .then((_) => close())
        .catchError((_) {
      _response.statusCode = HttpStatus.notFound;
      return close();
    }, test: (e) => e == 404);
  }

  Future close() {
    final newClose = _response.close();
    _dispose?.call();
    return newClose;
  }

  Future redirect(String url, [int code = 302]) {
    _response.statusCode = code;
    header('Location', url);
    return close();
  }
}
