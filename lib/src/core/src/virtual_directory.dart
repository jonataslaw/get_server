part of server;

class _DirectoryRedirect {
  const _DirectoryRedirect();
}

/// A [VirtualDirectory] can serve files and directory-listing from a root path,
/// to [HttpRequest]s.
///
/// The [VirtualDirectory] providing secure handling of request uris and
/// file-system links, correct mime-types and custom error pages.
class VirtualDirectory {
  final String root;

  /// Whether to allow listing files in a directories.
  ///
  /// When true the response to a request for a directory will be an HTML
  /// document with a table of links to all files within the directory, along
  /// with their size and last modified time. The default behavior can be
  /// overridden by setting a [directoryHandler].
  bool allowDirectoryListing = false;

  /// Whether to allow reading resources via a link.
  bool followLinks = true;

  /// Whether to prevent access outside of [root] via relative paths or links.
  bool jailRoot = true;

  final List<String> _pathPrefixSegments;

  final RegExp _invalidPathRegExp = RegExp('[\\/\x00]');

  void Function(HttpRequest)? _errorCallback;
  void Function(Directory, HttpRequest)? _dirCallback;

  static List<String> _parsePathPrefix(String? pathPrefix) {
    if (pathPrefix == null) return <String>[];
    return Uri(path: pathPrefix)
        .pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
  }

  /// Create a new [VirtualDirectory] for serving static file content of the
  /// path [root].
  ///
  /// The [root] is not required to exist. If the [root] doesn't exist at time of
  /// a request, a 404 response is generated.
  ///
  /// If [pathPrefix] is set, [pathPrefix] will indicate the expected path prefix
  /// of incoming requests. When locating the resource on disk, the prefix will
  /// be trimmed from the requests uri, before locating the actual resource.
  /// If the requests uri doesn't start with [pathPrefix], a 404 response is
  /// generated.
  VirtualDirectory(this.root, {String? pathPrefix})
      : _pathPrefixSegments = _parsePathPrefix(pathPrefix);

  /// Serve a [Stream] of [HttpRequest]s, in this [VirtualDirectory].
  StreamSubscription<HttpRequest> serve(Stream<HttpRequest> requests) =>
      requests.listen(serveRequest);

  /// Serve a single [HttpRequest], in this [VirtualDirectory].
  Future serveRequest(HttpRequest request) async {
    var iterator = HasCurrentIterator(request.uri.pathSegments.iterator);
    iterator.moveNext();
    for (var segment in _pathPrefixSegments) {
      if (!iterator.hasCurrent || iterator.current != segment) {
        _serveErrorPage(HttpStatus.notFound, request);
        return request.response.done;
      }
      iterator.moveNext();
    }

    var entity = await _locateResource('.', iterator);
    if (entity is File) {
      serveFile(entity, request);
    } else if (entity is Directory) {
      if (allowDirectoryListing) {
        _serveDirectory(entity, request);
      } else {
        _serveErrorPage(HttpStatus.notFound, request);
      }
    } else if (entity is _DirectoryRedirect) {
      _unawaited(request.response.redirect(Uri.parse('${request.uri}/'),
          status: HttpStatus.movedPermanently));
    } else {
      assert(entity == null);
      _serveErrorPage(HttpStatus.notFound, request);
    }
    return request.response.done;
  }

  /// Overrides the default directory listing.
  ///
  /// When invoked the [callback] should response through the [HttpRequest] with
  /// a directory listing.
  set directoryHandler(void Function(Directory, HttpRequest) callback) {
    _dirCallback = callback;
  }

  /// Overrides the default error handle.
  ///
  /// When [callback] is invoked, the `statusCode` property of the response is
  /// set.
  set errorPageHandler(void Function(HttpRequest) callback) {
    _errorCallback = callback;
  }

  Future<Object?> _locateResource(
      String path, HasCurrentIterator<String> segments) async {
    // Don't allow navigating up paths.
    if (segments.hasCurrent && segments.current == '..') {
      return Future.value(null);
    }
    path = normalize(path);
    // If we jail to root, the relative path can never go up.
    if (jailRoot && split(path).first == '..') return Future.value(null);
    String fullPath() => join(root, path);
    var type = await FileSystemEntity.type(fullPath(), followLinks: false);
    switch (type) {
      case FileSystemEntityType.file:
        if (!segments.hasCurrent) {
          return File(fullPath());
        }
        break;

      case FileSystemEntityType.directory:
        String dirFullPath() => '${fullPath()}$separator';
        if (!segments.hasCurrent) {
          if (path == '.') return Directory(dirFullPath());
          return const _DirectoryRedirect();
        }
        var current = segments.current;
        var hasNext = segments.moveNext();
        if (!hasNext && current == '') {
          return Directory(dirFullPath());
        } else {
          if (_invalidPathRegExp.hasMatch(current)) break;
          return _locateResource(join(path, current), segments);
        }

      case FileSystemEntityType.link:
        if (followLinks) {
          var target = await Link(fullPath()).target();
          var targetPath = normalize(target);
          if (isAbsolute(targetPath)) {
            // If we jail to root, the path can never be absolute.
            if (jailRoot) return null;
            return _locateResource(targetPath, segments);
          } else {
            targetPath = join(dirname(path), targetPath);
            return _locateResource(targetPath, segments);
          }
        }
        break;

      case FileSystemEntityType.notFound:
        break;
    }
    // Return `null` on fall-through, to indicate NOT_FOUND.
    return null;
  }

  /// Serve the content of [file] to [request].
  ///
  /// Can be used in overrides of [directoryHandler] to redirect to an index
  /// file.
  ///
  /// In the request contains the [HttpHeaders.ifModifiedSince] header,
  /// [serveFile] will send a [HttpStatus.notModified] response if the file
  /// was not changed.
  ///
  /// Note that if it was unable to read from [file], the [request]s response
  /// is closed with error-code [HttpStatus.notFound].
  void serveFile(File file, HttpRequest request) async {
    var response = request.response;
    try {
      var lastModified = await file.lastModified();
      if (request.headers.ifModifiedSince != null &&
          !lastModified.isAfter(request.headers.ifModifiedSince!)) {
        response.statusCode = HttpStatus.notModified;
        await response.close();
        return null;
      }

      response.headers.set(HttpHeaders.lastModifiedHeader, lastModified);
      response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');

      var length = await file.length();
      var range = request.headers.value(HttpHeaders.rangeHeader);
      if (range != null) {
        // We only support one range, where the standard support several.
        var matches = RegExp(r'^bytes=(\d*)\-(\d*)$').firstMatch(range);
        // If the range header have the right format, handle it.
        if (matches != null &&
            (matches[1]!.isNotEmpty || matches[2]!.isNotEmpty)) {
          // Serve sub-range.
          int start; // First byte position - inclusive.
          int end; // Last byte position - inclusive.
          if (matches[1]!.isEmpty) {
            start = length - int.parse(matches[2]!);
            if (start < 0) start = 0;
            end = length - 1;
          } else {
            start = int.parse(matches[1]!);
            end = matches[2]!.isEmpty ? length - 1 : int.parse(matches[2]!);
          }
          // If the range is syntactically invalid the Range header
          // MUST be ignored (RFC 2616 section 14.35.1).
          if (start <= end) {
            if (end >= length) {
              end = length - 1;
            }

            if (start >= length) {
              response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
              await response.close();
              return;
            }

            // Override Content-Length with the actual bytes sent.
            response.headers
                .set(HttpHeaders.contentLengthHeader, end - start + 1);

            // Set 'Partial Content' status code.
            response
              ..statusCode = HttpStatus.partialContent
              ..headers.set(
                  HttpHeaders.contentRangeHeader, 'bytes $start-$end/$length');

            // Pipe the 'range' of the file.
            if (request.method == 'HEAD') {
              await response.close();
            } else {
              try {
                await file
                    .openRead(start, end + 1)
                    .cast<List<int>>()
                    .pipe(_VirtualDirectoryFileStream(response, file.path));
              } catch (e) {
                Get.log(e.toString(), isError: true);
              }
            }
            return;
          }
        }
      }

      response.headers.set(HttpHeaders.contentLengthHeader, length);
      if (request.method == 'HEAD') {
        await response.close();
      } else {
        try {
          await file
              .openRead()
              .cast<List<int>>()
              .pipe(_VirtualDirectoryFileStream(response, file.path));
        } catch (e) {
          Get.log(e.toString(), isError: true);
        }
      }
    } catch (_) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
    }
  }

  void _serveDirectory(Directory dir, HttpRequest request) async {
    if (_dirCallback != null) {
      _dirCallback!(dir, request);
      return;
    }
    var response = request.response;
    try {
      var stats = await dir.stat();
      if (request.headers.ifModifiedSince != null &&
          !stats.modified.isAfter(request.headers.ifModifiedSince!)) {
        response.statusCode = HttpStatus.notModified;
        await response.close();
        return;
      }

      response.headers.contentType =
          ContentType('text', 'html', parameters: {'charset': 'utf-8'});
      response.headers.set(HttpHeaders.lastModifiedHeader, stats.modified);
      var path = Uri.decodeComponent(request.uri.path);
      var encodedPath = const HtmlEscape().convert(path);
      var header =
          '''<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Index of $encodedPath</title>
</head>
<body>
<h1>Index of $encodedPath</h1>
<table>
  <tr>
    <td>Name</td>
    <td>Last modified</td>
    <td>Size</td>
  </tr>
''';
      var server = response.headers.value(HttpHeaders.serverHeader);
      server ??= '';
      var footer = '''</table>
$server
</body>
</html>
''';

      response.write(header);

      void add(String name, String? modified, var size, bool folder) {
        size ??= '-';
        modified ??= '';
        var encodedSize = const HtmlEscape().convert(size.toString());
        var encodedModified = const HtmlEscape().convert(modified);
        var encodedLink = const HtmlEscape(HtmlEscapeMode.attribute)
            .convert(Uri.encodeComponent(name));
        if (folder) {
          encodedLink += '/';
          name += '/';
        }
        var encodedName = const HtmlEscape().convert(name);

        var entry = '''  <tr>
    <td><a href="$encodedLink">$encodedName</a></td>
    <td>$encodedModified</td>
    <td style="text-align: right">$encodedSize</td>
  </tr>''';
        response.write(entry);
      }

      if (path != '/') {
        add('..', null, null, true);
      }

      dir.list(followLinks: true).listen((entity) {
        var name = basename(entity.path);
        var stat = entity.statSync();
        if (entity is File) {
          add(name, stat.modified.toString(), stat.size, false);
        } else if (entity is Directory) {
          add(name, stat.modified.toString(), null, true);
        }
      }, onError: (e) {
        Get.log(e.toString(), isError: true);
      }, onDone: () {
        response.write(footer);
        response.close();
      });
    } catch (e) {
      Get.log(e.toString(), isError: true);
      await response.close();
    }
  }

  void _serveErrorPage(int error, HttpRequest request) {
    var response = request.response;
    response.statusCode = error;
    if (_errorCallback != null) {
      _errorCallback!(request);
      return;
    }
    response.headers.contentType =
        ContentType('text', 'html', parameters: {'charset': 'utf-8'});
    // Default error page.
    var path = Uri.decodeComponent(request.uri.path);
    var encodedPath = const HtmlEscape().convert(path);
    var encodedReason = const HtmlEscape().convert(response.reasonPhrase);
    var encodedError = const HtmlEscape().convert(error.toString());

    var server = response.headers.value(HttpHeaders.serverHeader);
    server ??= '';
    var page = '''<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>$encodedReason: $encodedPath</title>
</head>
<body>
<h1>Error $encodedError at '$encodedPath': $encodedReason</h1>
$server
</body>
</html>''';
    response.write(page);
    response.close();
  }
}

class _VirtualDirectoryFileStream extends StreamConsumer<List<int>> {
  final HttpResponse response;
  final String path;
  List<int>? buffer = [];

  _VirtualDirectoryFileStream(this.response, this.path);

  @override
  Future addStream(Stream<List<int>> stream) {
    stream.listen((data) {
      if (buffer == null) {
        response.add(data);
        return;
      }
      if (buffer!.isEmpty) {
        if (data.length >= defaultMagicNumbersMaxLength) {
          setMimeType(data);
          response.add(data);
          buffer = null;
        } else {
          buffer!.addAll(data);
        }
      } else {
        buffer!.addAll(data);
        if (buffer!.length >= defaultMagicNumbersMaxLength) {
          setMimeType(buffer);
          response.add(buffer!);
          buffer = null;
        }
      }
    }, onDone: () {
      if (buffer != null) {
        if (buffer!.isEmpty) {
          setMimeType(null);
        } else {
          setMimeType(buffer);
          response.add(buffer!);
        }
      }
      response.close();
    }, onError: response.addError);
    return response.done;
  }

  @override
  Future close() => Future.value();

  void setMimeType(List<int>? bytes) {
    var mimeType = lookupMimeType(path, headerBytes: bytes);
    if (mimeType != null) {
      response.headers.contentType = ContentType.parse(mimeType);
    }
  }
}

// Copied from `package:pedantic` to avoid the dep.
void _unawaited(Future<void> f) {}

class HasCurrentIterator<E> implements Iterator<E> {
  final Iterator<E> _iterator;

  /// The result of the last call to [moveNext].
  bool _hasCurrent = false;

  /// Whether or not `current` has a valid value.
  ///
  /// This starts out as `false`, and then stores the value of the previous
  /// `moveNext` call.
  bool get hasCurrent => _hasCurrent;

  HasCurrentIterator(this._iterator);

  /// Must be called before reading [current] or [hasCurrent].
  @override
  bool moveNext() => _hasCurrent = _iterator.moveNext();

  @override
  E get current => _iterator.current;
}
