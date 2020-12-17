part of server;

@immutable
abstract class Widget {
  const Widget();

  /// Inflates this configuration to a concrete instance.
  ///
  /// A given widget can be included in the tree zero or more times. In particular
  /// a given widget can be placed in the tree multiple times. Each time a widget
  /// is placed in the tree, it is inflated into an [Element], which means a
  /// widget that is incorporated into the tree multiple times will be inflated
  /// multiple times.
  @protected
  @factory
  Element createElement(ContextRequest request, Stream<GetSocket> ws);
}

abstract class Element implements BuildContext {
  /// Creates an element that uses the given widget sas its configuration.
  ///
  /// Typically called by an override of [Widget.createElement].
  Element(Widget widget, ContextRequest request, Stream<GetSocket> ws)
      : assert(widget != null),
        request = request,
        ws = ws,
        _widget = widget;

  Widget get widget => _widget;
  final Widget _widget;

  @override
  ContextResponse get response => request.response;
  @override
  final ContextRequest request;
  @override
  final Stream<GetSocket> ws;

  @override
  Future pageNotFound() {
    return response.close();
  }

  @override
  void statusCode(int code) {
    if (code == null) {
      return;
    }
    response.status(code);
  }

  @override
  Future close() {
    return response.close();
  }

  @override
  Future send(Object string) {
    return response.send(string);
  }

  @override
  Future sendBytes(List<int> data) {
    return response.send(data);
  }

  @override
  Future sendJson(Object string) {
    return response
        // this headers are not working
        .header('Content-Type', 'application/json; charset=UTF-8')
        .sendJson(string);
  }

  @override
  Future sendHtml(String path) {
    // this headers are not working
    response.header('Content-Type', 'text/html; charset=UTF-8');
    return response.sendFile(path);
  }

  @override
  Future<MultipartUpload> file(String name, {Encoding encoder = utf8}) async {
    final payload = await request.payload(encoder: encoder);
    final multiPart = await payload[name];
    return multiPart;
  }

  @override
  String param(String name) => request.param(name);

  @override
  Future<Map> payload({Encoding encoder = utf8}) =>
      request.payload(encoder: encoder);
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget() : super();

  @override
  StatelessElement createElement(ContextRequest request, Stream<GetSocket> ws) {
    final element = StatelessElement(this, request, ws);
    build(element).createElement(request, ws);
    return element;
  }

  @protected
  Widget build(BuildContext context);
}

class StatelessElement extends ComponentElement {
  /// Creates an element that uses the given widget as its configuration.
  StatelessElement(
      StatelessWidget widget, ContextRequest request, Stream<GetSocket> ws)
      : super(widget, request, ws);

  @override
  StatelessWidget get widget => super.widget as StatelessWidget;

  @override
  Widget build() => widget.build(this);
}

abstract class ComponentElement extends Element {
  /// Creates an element that uses the given widget as its configuration.
  ComponentElement(Widget widget, ContextRequest request, Stream<GetSocket> ws)
      : super(widget, request, ws);

  @protected
  Widget build();
}
