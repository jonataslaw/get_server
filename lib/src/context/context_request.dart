import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';

import '../../get_server.dart';
import 'context_response.dart';

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
        'fileBase64': data == null ? null : base64Encode(data),
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
                parameters?['filename'],
                formData.contentType!.mimeType,
                formData.contentTransferEncoding,
                data);
          }
          payload[parameters?['name']] = data;
        });
      }, onDone: () {
        completer.complete(payload);
      });
    } else if (isMime('application/json')) {
      try {
        final content = await utf8.decodeStream(_request);
        final payload = jsonDecode(content);
        completer.complete(payload);
      } catch (e) {
        rethrow;
      }
    }

    return completer.future;
  }

  static HttpMultipartFormData parse(MimeMultipart multipart,
      {Encoding defaultEncoding = utf8}) {
    ContentType? contentType;
    HeaderValue? encoding;
    HeaderValue? disposition;
    for (var key in multipart.headers.keys) {
      switch (key) {
        case 'content-type':
          contentType = ContentType.parse(multipart.headers[key]!);
          break;

        case 'content-transfer-encoding':
          encoding = HeaderValue.parse(multipart.headers[key]!);
          break;

        case 'content-disposition':
          disposition = HeaderValue.parse(multipart.headers[key]!,
              preserveBackslash: true);
          break;

        default:
          break;
      }
    }
    if (disposition == null) {
      throw const HttpException(
          "Mime Multipart doesn't contain a Content-Disposition header value");
    }
    if (encoding != null &&
        !_transparentEncodings.contains(encoding.value.toLowerCase())) {
      throw HttpException('Unsupported contentTransferEncoding: '
          '${encoding.value}');
    }

    Stream stream = multipart;
    var isText = contentType == null ||
        contentType.primaryType == 'text' ||
        contentType.mimeType == 'application/json';
    if (isText) {
      Encoding? encoding;
      if (contentType?.charset != null) {
        encoding = Encoding.getByName(contentType!.charset);
      }
      encoding ??= defaultEncoding;
      stream = stream.transform(encoding.decoder);
    }
    return HttpMultipartFormData._(
        contentType, disposition, encoding, multipart, stream, isText);
  }
}

const _transparentEncodings = ['7bit', '8bit', 'binary'];

class HttpMultipartFormData extends Stream {
  /// The parsed `Content-Type` header value.
  ///
  /// `null` if not present.
  final ContentType? contentType;

  /// The parsed `Content-Disposition` header value.
  ///
  /// This field is always present. Use this to extract e.g. name (form field
  /// name) and filename (client provided name of uploaded file) parameters.
  final HeaderValue contentDisposition;

  /// The parsed `Content-Transfer-Encoding` header value.
  ///
  /// This field is used to determine how to decode the data. Returns `null`
  /// if not present.
  final HeaderValue? contentTransferEncoding;

  /// Whether the data is decoded as [String].
  final bool isText;

  /// Whether the data is raw bytes.
  bool get isBinary => !isText;

  /// Parse a [MimeMultipart] and return a [HttpMultipartFormData].
  ///
  /// If the `Content-Disposition` header is missing or invalid, an
  /// [HttpException] is thrown.
  ///
  /// If the [MimeMultipart] is identified as text, and the `Content-Type`
  /// header is missing, the data is decoded using [defaultEncoding]. See more
  /// information in the
  /// [HTML5 spec](http://dev.w3.org/html5/spec-preview/
  /// constraints.html#multipart-form-data).
  static HttpMultipartFormData parse(MimeMultipart multipart,
      {Encoding defaultEncoding = utf8}) {
    ContentType? contentType;
    HeaderValue? encoding;
    HeaderValue? disposition;
    for (var key in multipart.headers.keys) {
      switch (key) {
        case 'content-type':
          contentType = ContentType.parse(multipart.headers[key]!);
          break;

        case 'content-transfer-encoding':
          encoding = HeaderValue.parse(multipart.headers[key]!);
          break;

        case 'content-disposition':
          disposition = HeaderValue.parse(multipart.headers[key]!,
              preserveBackslash: true);
          break;

        default:
          break;
      }
    }
    if (disposition == null) {
      throw const HttpException(
          "Mime Multipart doesn't contain a Content-Disposition header value");
    }
    if (encoding != null &&
        !_transparentEncodings.contains(encoding.value.toLowerCase())) {
      throw HttpException('Unsupported contentTransferEncoding: '
          '${encoding.value}');
    }

    Stream stream = multipart;
    var isText = contentType == null ||
        contentType.primaryType == 'text' ||
        contentType.mimeType == 'application/json';
    if (isText) {
      Encoding? encoding;
      if (contentType?.charset != null) {
        encoding = Encoding.getByName(contentType!.charset);
      }
      encoding ??= defaultEncoding;
      stream = stream.transform(encoding.decoder);
    }
    return HttpMultipartFormData._(
        contentType, disposition, encoding, multipart, stream, isText);
  }

  final MimeMultipart _mimeMultipart;

  final Stream _stream;

  HttpMultipartFormData._(
      this.contentType,
      this.contentDisposition,
      this.contentTransferEncoding,
      this._mimeMultipart,
      this._stream,
      this.isText);

  @override
  StreamSubscription listen(void Function(dynamic)? onData,
      {void Function()? onDone, Function? onError, bool? cancelOnError}) {
    return _stream.listen(onData,
        onDone: onDone, onError: onError, cancelOnError: cancelOnError);
  }

  /// Returns the value for the header named [name].
  ///
  /// If there is no header with the provided name, `null` will be returned.
  ///
  /// Use this method to index other headers available in the original
  /// [MimeMultipart].
  String? value(String name) {
    return _mimeMultipart.headers[name];
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
