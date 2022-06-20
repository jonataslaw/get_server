part of server;

abstract class BuildContext {
  ContextResponse? get response;
  ContextRequest get request;

  Method get method;

  Future pageNotFound();

  void statusCode(int code);

  Future close();

//  Stream<GetSocket> get ws;

  GetSocket? get getSocket;

  Future send(Object string);

  Future sendBytes(List<int> data);

  Future? sendJson(Object string);

  Future sendHtml(String path);

  Future<MultipartUpload> file(String name, {Encoding encoder = utf8});

  String? param(String name) => request.param(name);

  Future<Map?> payload({Encoding encoder = utf8});
}

@immutable
abstract class Widget {
  const Widget({this.key});

  final Key? key;

  /// Inflates this configuration to a concrete instance.
  /// A given widget can be included in the tree zero or more times.
  /// In particular
  /// a given widget can be placed in the tree multiple times.
  /// Each time a widget
  /// is placed in the tree, it is inflated into an [Element], which means a
  /// widget that is incorporated into the tree multiple times will be inflated
  /// multiple times.
  @protected
  @factory
  Element? createElement(ContextRequest request, GetSocket? getSocket);
}

abstract class Element implements BuildContext {
  /// Creates an element that uses the given widget sas its configuration.
  ///
  /// Typically called by an override of [Widget.createElement].
  Element(this._widget, this.request, this.getSocket);

  Widget get widget => _widget;
  final Widget _widget;

  void performRebuild();

  @override
  ContextResponse? get response => request.response;
  @override
  final ContextRequest request;

  @override
  final GetSocket? getSocket;

  @override
  Future pageNotFound() {
    return response!.close();
  }

  @override
  void statusCode(int code) {
    response!.status(code);
  }

  @override
  Future close() {
    return response!.close();
  }

  @override
  Future send(Object string) {
    return response!.send(string);
  }

  @override
  Future sendBytes(List<int> data) {
    return response!.send(data);
  }

  @override
  Future? sendJson(Object string) {
    return response!
        // this headers are not working
        .header('Content-Type', 'application/json; charset=UTF-8')
        .sendJson(string);
  }

  @override
  Future sendHtml(String path) {
    // this headers are not working
    response!.header('Content-Type', 'text/html; charset=UTF-8');
    return response!.sendFile(path);
  }

  @override
  Future<MultipartUpload> file(String name, {Encoding encoder = utf8}) async {
    final payload = await (request.payload(encoder: encoder)
        as FutureOr<Map<dynamic, dynamic>>);
    final multiPart = await payload[name];
    if (multiPart is MultipartUpload) {
      return multiPart;
    } else {
      Get.log('Incorrect format, upload the file as Multipart/formdata',
          isError: true);
      return MultipartUpload(null, null, null, null);
    }
  }

  @override
  String? param(String name) => request.param(name);

  @override
  Future<Map?> payload({Encoding encoder = utf8}) =>
      request.payload(encoder: encoder);
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget({Key? key}) : super(key: key);

  @override
  StatelessElement createElement(ContextRequest request, GetSocket? getSocket) {
    return StatelessElement(this, request, getSocket);
    // element.performRebuild();
    // return element;
  }

  @protected
  Widget build(BuildContext context);
}

class StatelessElement extends ComponentElement {
  /// Creates an element that uses the given widget as its configuration.
  StatelessElement(
      StatelessWidget widget, ContextRequest request, GetSocket? socketStream)
      : super(widget, request, socketStream) {
    performRebuild();
  }

  @override
  void performRebuild() {
    build().createElement(request, getSocket);
  }

  @override
  StatelessWidget get widget => super.widget as StatelessWidget;

  @override
  Widget build() => widget.build(this);

  @override
  Method get method => request.requestMethod;
}

abstract class ComponentElement extends Element {
  /// Creates an element that uses the given widget as its configuration.
  ComponentElement(
    Widget widget,
    ContextRequest request,
    GetSocket? getSocket,
  ) : super(
          widget,
          request,
          getSocket,
        );

  @protected
  Widget? build();
}

typedef VoidCallback = void Function();

abstract class StatefulWidget extends Widget {
  /// Initializes [key] for subclasses.
  const StatefulWidget({Key? key}) : super(key: key);

  @override
  StatefulElement createElement(ContextRequest request, GetSocket? getSocket) {
    return StatefulElement(this, request, getSocket);
  }

  @protected
  @factory
  State createState();
}

class StatefulElement extends ComponentElement {
  /// Creates an element that uses the given widget as its configuration.
  StatefulElement(
      StatefulWidget widget, ContextRequest request, GetSocket? socketStream)
      : state = widget.createState(),
        super(widget, request, socketStream) {
    activate();
  }

  @override
  void performRebuild() {
    build().createElement(request, getSocket);
  }

  @override
  Widget build() => state.build(this);

  /// The [State] instance associated with this location in the tree.
  ///
  /// There is a one-to-one relationship between [State] objects and the
  /// [StatefulElement] objects that hold them. The [State] objects are created
  /// by [StatefulElement] in [mount].
  final State<StatefulWidget> state;

  void activate() {
    state._element = this;
    state._widget = widget as StatefulWidget?;
    state.initState();
    performRebuild();

    request.input.response.done.then((value) => unmount());

    response!.addDisposeCallback(unmount);
  }

  void unmount() {
    state.dispose();
    state._element = null;
    state._widget = null;
  }

  @override
  Method get method => request.requestMethod;
}

abstract class State<T extends StatefulWidget> {
  T get widget => _widget!;
  T? _widget;

  BuildContext get context {
    assert(() {
      if (_element == null) {
        throw StateError(
            'This widget has been unmounted, so the State no longer has a context (and should be considered defunct). \n'
            'Consider canceling any active work during "dispose" or using the "mounted" getter to determine if the State is still active.');
      }
      return true;
    }());
    return _element!;
  }

  StatefulElement? _element;

  bool get mounted => _element != null;

  @protected
  @mustCallSuper
  void initState() {}

  @mustCallSuper
  @protected
  void didUpdateWidget(covariant T oldWidget) {}

  @protected
  void setState(VoidCallback fn) {
    fn();
    _element!.performRebuild();
  }

  @protected
  @mustCallSuper
  void dispose() {}

  ///  * [StatefulWidget], which contains the discussion on performance considerations.
  @protected
  Widget build(BuildContext context);

  @protected
  @mustCallSuper
  void didChangeDependencies() {}
}

@immutable
abstract class Key {
  /// Construct a [ValueKey<String>] with the given [String].
  ///
  /// This is the simplest way to create keys.
  const factory Key(String value) = ValueKey<String>;

  /// Default constructor, used by subclasses.
  ///
  /// Useful so that subclasses can call us, because the [Key.new] factory
  /// constructor shadows the implicit constructor.
  @protected
  const Key.empty();
}

/// A key that is not a [GlobalKey].
///
/// Keys must be unique amongst the [Element]s with the same parent. By
/// contrast, [GlobalKey]s must be unique across the entire app.
///
/// See also:
///
///  * [Widget.key], which discusses how widgets use keys.
abstract class LocalKey extends Key {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const LocalKey() : super.empty();
}

/// A key that is only equal to itself.
///
/// This cannot be created with a const constructor because that implies that
/// all instantiated keys would be the same instance and therefore not be unique.
class UniqueKey extends LocalKey {
  /// Creates a key that is equal only to itself.
  ///
  /// The key cannot be created with a const constructor because that implies
  /// that all instantiated keys would be the same instance and therefore not
  /// be unique.
  // ignore: prefer_const_constructors_in_immutables , never use const for this class
  UniqueKey();

  @override
  String toString() => '[#${shortHash(this)}]';
}

/// A key that uses a value of a particular type to identify itself.
///
/// A [ValueKey<T>] is equal to another [ValueKey<T>] if, and only if, their
/// values are [operator==].
///
/// This class can be subclassed to create value keys that will not be equal to
/// other value keys that happen to use the same value. If the subclass is
/// private, this results in a value key type that cannot collide with keys from
/// other sources, which could be useful, for example, if the keys are being
/// used as fallbacks in the same scope as keys supplied from another widget.
///
/// See also:
///
///  * [Widget.key], which discusses how widgets use keys.
class ValueKey<T> extends LocalKey {
  /// Creates a key that delegates its [operator==] to the given value.
  const ValueKey(this.value);

  /// The value to which this key delegates its [operator==]
  final T value;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is ValueKey<T> && other.value == value;
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() {
    final String valueString = T == String ? "<'$value'>" : '<$value>';
    // The crazy on the next line is a workaround for
    // https://github.com/dart-lang/sdk/issues/33297
    if (runtimeType == _TypeLiteral<ValueKey<T>>().type) {
      return '[$valueString]';
    }
    return '[$T $valueString]';
  }
}

class _TypeLiteral<T> {
  Type get type => T;
}

String shortHash(Object? object) {
  return object.hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');
}
