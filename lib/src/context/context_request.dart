import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http_server/http_server.dart';
import 'package:mime/mime.dart';
import '../../get_server.dart';
import 'context_response.dart';
import 'dart:convert' show utf8;

class MultipartUpload {
  final String? name;
  final String? mimeType;
  final dynamic contentTransferEncoding;
  final dynamic data;
  const MultipartUpload(
    this.name,
    this.mimeType,
    this.contentTransferEncoding,
    this.data,
  );

  dynamic toJson() => {
        'name': name,
        'mimeType': mimeType,
        'fileBase64': data == null ? null : '${base64Encode(data)}',
        'transferEncoding': '$contentTransferEncoding'
      };

  @override
  String toString() => toJson().toString();
}

class ContextRequest {
  final HttpRequest _request;
  final Method requestMethod;
  ContextResponse? response;

  ContextRequest(this._request, this.requestMethod);

  List? header(String name) => _request.headers[name.toLowerCase()];

  bool accepts(String type) => _request.headers[HttpHeaders.acceptHeader]!
      .where((name) => name.split(',').indexOf(type) > 0)
      .isNotEmpty;

  bool isMime(String type, {bool loose = true}) =>
      _request.headers[HttpHeaders.contentTypeHeader]!
          .where((value) => loose ? value.contains(type) : value == type)
          .isNotEmpty;

  bool get hasContentType =>
      _request.headers[HttpHeaders.contentTypeHeader] != null;

  bool get isForwarded => _request.headers['x-forwarded-host'] != null;

  HttpRequest get input => _request;

  Map<String, String> get query => _request.uri.queryParameters;
  Map<String?, String?>? params;

  List<Cookie> get cookies => _request.cookies.map((cookie) {
        cookie.name = Uri.decodeQueryComponent(cookie.name);
        cookie.value = Uri.decodeQueryComponent(cookie.value);
        return cookie;
      }).toList();

  String get path => _request.uri.path;

  Uri get uri => _request.uri;

  HttpSession get session => _request.session;

  String get method => _request.method;

  X509Certificate? get certificate => _request.certificate;

  String? param(String name) {
    if (params!.containsKey(name) && params![name] != null) {
      return params![name];
    } else if (query[name] != null) {
      return query[name];
    }
    return null;
  }

  /// Get the payload (body)
  ///
  /// If don't have the contentType of payload will return null
  Future<Map?> payload({Encoding encoder = utf8}) async {
    var completer = Completer<Map>();

    if (!hasContentType) return null;

    if (isMime('application/x-www-form-urlencoded')) {
      const AsciiDecoder().bind(_request).listen((content) {
        final payload = {
          for (var kv in content.split('&').map((kvs) => kvs.split('=')))
            Uri.decodeQueryComponent(kv[0], encoding: encoder):
                Uri.decodeQueryComponent(kv[1], encoding: encoder)
        };
        completer.complete(payload);
      });
    } else if (isMime('multipart/form-data', loose: true)) {
      var boundary = _request.headers.contentType!.parameters['boundary']!;
      final payload = {};
      MimeMultipartTransformer(boundary)
          .bind(_request)
          .map(HttpMultipartFormData.parse)
          .listen((formData) {
        var parameters = formData.contentDisposition.parameters;
        formData.listen((data) {
          if (formData.contentType != null) {
            data = MultipartUpload(
                parameters['filename'],
                formData.contentType!.mimeType,
                formData.contentTransferEncoding,
                data);
          }
          payload[parameters['name']] = data;
        });
      }, onDone: () {
        completer.complete(payload);
      });
    } else if (isMime('application/json')) {
      final content = await utf8.decodeStream(_request);
      final payload = jsonDecode(content);
      completer.complete(payload);
    }

    return completer.future;
  }
}

// class ContextRequestResolver {
//   final HttpRequest _request;

//   ContextRequestResolver(this._request);

//   bool get hasContentType =>
//       _request.headers[HttpHeaders.contentTypeHeader] != null;

//   bool isMime(String type, {bool loose = true}) =>
//       _request.headers[HttpHeaders.contentTypeHeader]
//           .where((value) => loose ? value.contains(type) : value == type)
//           .isNotEmpty;

//   Future<ContextRequest> resolver({Encoding encoder = utf8}) async {
//     var completer = Completer<Map>();

//     if (!hasContentType) return null;

//     if (isMime('application/x-www-form-urlencoded')) {
//       const AsciiDecoder().bind(_request).listen((content) {
//         final payload = {
//           for (var kv in content.split('&').map((kvs) => kvs.split('=')))
//             Uri.decodeQueryComponent(kv[0], encoding: encoder):
//                 Uri.decodeQueryComponent(kv[1], encoding: encoder)
//         };
//         completer.complete(payload);
//       });
//     } else if (isMime('multipart/form-data', loose: true)) {
//       var boundary = _request.headers.contentType.parameters['boundary'];
//       final payload = {};
//       MimeMultipartTransformer(boundary)
//           .bind(_request)
//           .map(HttpMultipartFormData.parse)
//           .listen((formData) {
//         var parameters = formData.contentDisposition.parameters;
//         formData.listen((data) {
//           if (formData.contentType != null) {
//             data = MultipartUpload(
//                 parameters['filename'],
//                 formData.contentType.mimeType,
//                 formData.contentTransferEncoding,
//                 data);
//           }
//           payload[parameters['name']] = data;
//         });
//       }, onDone: () {
//         completer.complete(payload);
//       });
//     } else if (isMime('application/json')) {
//       const Utf8Decoder().bind(_request).listen((content) {
//         final payload = jsonDecode(content);
//         completer.complete(payload);
//       });
//     }
//     final payload = await completer.future;

//     return ContextRequest(_request, payload);
//   }
// }
