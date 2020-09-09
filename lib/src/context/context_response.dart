import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';

class ContextResponse {
  final HttpResponse _response;

  ContextResponse(this._response);

  dynamic header(String name, [Object value]) {
    if (value == null) {
      return _response.headers[name];
    }
    _response.headers.set(name, value);
    return this;
  }

  ContextResponse get(String name) => header(name);

  ContextResponse set(String name, String value) => header(name, value);

  ContextResponse type(String contentType) => set('Content-Type', contentType);

  ContextResponse cache(String cacheType, [Map<String, String> options]) {
    if (options == null) {
      options = {};
    }
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

  ContextResponse attachment(String filename) {
    if (filename != null) {
      return set('Content-Disposition', 'attachment; filename="$filename"');
    }
    return this;
  }

  ContextResponse mime(String path) {
    var mimeType = lookupMimeType(path);
    if (mimeType != null) {
      return type(mimeType);
    }
    return this;
  }

  Future send(Object string) {
    _response.write(string);
    return _response.close();
  }

  Future sendJson(Object data) {
    // if (data is Map || data is List) {
    //   data = jsonEncode(data);
    // }

    // if (get('Content-Type') == null) {
    //   type('application/json');
    // }
    _response.write(jsonEncode(data));
    return _response.close();
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
        .then((_) => _response.close())
        .catchError((_) {
      _response.statusCode = HttpStatus.notFound;
      return _response.close();
    }, test: (e) => e == 404);
  }

  Future close() {
    return _response.close();
  }

  Future redirect(String url, [int code = 302]) {
    _response.statusCode = code;
    header('Location', url);
    return _response.close();
  }
}
