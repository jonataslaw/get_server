part of server;

abstract class GetView<T> extends StatelessWidget {
  final String tag = null;

  T get controller => GetInstance().find<T>(tag: tag);
  @override
  Widget build(BuildContext context);
}

abstract class GetEndpoint<T> extends StatelessWidget {
  final String tag = null;

  T get controller => GetInstance().find<T>(tag: tag);
  @override
  Widget build(BuildContext context);
}

class _Wrapper<T> {
  T data;
}

abstract class GetWidget<T> extends StatelessWidget {
  final _value = _Wrapper<T>();

  final String tag = null;

  T get controller {
    _value.data ??= GetInstance().find<T>(tag: tag);
    return _value.data;
  }
}

class WidgetEmpty extends Widget {
  const WidgetEmpty({Key key}) : super(key: key);
  @override
  Element createElement(a, b) {
    return null;
  }
}

class WidgetResponse extends StatelessWidget {
  WidgetResponse(
    this.child, {
    this.statusCode = 200,
    this.headers,
  });
  final int statusCode;
  final Map headers;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FullHeadersWidget(
      child: StatusCode(child: child, statusCode: statusCode),
      headers: headers,
    );
  }
}

class PageRedirect extends StatelessWidget {
  PageRedirect({@required this.redirectUrl, this.statusCode = 302});
  final String redirectUrl;
  final int statusCode;

  @override
  Widget build(BuildContext context) {
    context.request.response.redirect(redirectUrl, statusCode);
    return WidgetEmpty();
  }
}

class StatusCode extends StatelessWidget {
  StatusCode({@required this.child, @required this.statusCode});
  final Widget child;
  final int statusCode;

  @override
  Widget build(BuildContext context) {
    context.request.response.status(statusCode);
    return child;
  }
}

class HeaderWidget extends StatelessWidget {
  HeaderWidget(
      {@required this.child, @required this.name, @required this.value});
  final Widget child;
  final String name;
  final Object value;

  @override
  Widget build(BuildContext context) {
    if (key != null && value != null) {
      context.request.response.header(name, value);
    }
    return child;
  }
}

class FullHeadersWidget extends StatelessWidget {
  FullHeadersWidget({
    @required this.child,
    @required this.headers,
  });
  final Widget child;
  final Map headers;

  @override
  Widget build(BuildContext context) {
    if (headers != null) {
      headers.forEach((key, value) {
        context.request.response.header(key, value);
      });
    }
    return child;
  }
}

abstract class SenderWidget extends StatelessWidget {}

class Html extends SenderWidget {
  final String path;
  Html({@required this.path});
  @override
  Widget build(BuildContext context) {
    context.response.sendFile(path);
    return WidgetEmpty();
  }
}

class BytesData extends SenderWidget {
  BytesData(this.bytes);
  final List<int> bytes;

  @override
  Widget build(BuildContext context) {
    context.sendBytes(bytes);
    return WidgetEmpty();
  }
}

class Text extends SenderWidget {
  Text(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    context.request.response.send(text);
    return WidgetEmpty();
  }
}

class HtmlText extends SenderWidget {
  HtmlText(this.content);
  final String content;

  @override
  Widget build(BuildContext context) {
    context.response.sendHtmlText(content);
    return WidgetEmpty();
  }
}

class Json extends SenderWidget {
  final dynamic content;
  Json(this.content);
  @override
  Widget build(BuildContext context) {
    context.response.sendJson(content);
    return WidgetEmpty();
  }
}

typedef WidgetBuilderCallback = Widget Function(BuildContext context);

typedef SocketBuilder = void Function(GetSocket socket);

class Socket extends SenderWidget {
  Socket({@required this.builder});
  final SocketBuilder builder;
  @override
  Widget build(BuildContext context) {
    var event = context.getSocket;
    event.rawSocket.done.then((value) {
      event = null;
    });
    builder(event);

    return WidgetEmpty();
  }
}

class WidgetBuilder extends StatelessWidget {
  final WidgetBuilderCallback builder;

  const WidgetBuilder({
    @required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(context);
}

typedef WidgetCallback = Widget Function();

abstract class ObxWidget extends StatefulWidget {
  const ObxWidget() : super();

  @override
  _ObxState createState() => _ObxState();

  @protected
  Widget build();
}

class _ObxState extends State<ObxWidget> {
  RxInterface _observer;
  StreamSubscription subs;

  _ObxState() {
    _observer = Rx();
  }

  @override
  void initState() {
    subs = _observer.listen((data) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    subs.cancel();
    _observer.close();
    super.dispose();
  }

  Widget get notifyChilds {
    final observer = getObs;
    getObs = _observer;
    final result = widget.build();
    if (!_observer.canUpdate) {
      throw '''
      [Get] the improper use of a GetX has been detected. 
      You should only use GetX or Obx for the specific widget that will be updated.
      If you are seeing this error, you probably did not insert any observable variables into GetX/Obx 
      or insert them outside the scope that GetX considers suitable for an update 
      (example: GetX => HeavyWidget => variableObservable).
      If you need to update a parent widget and a child widget, wrap each one in an Obx/GetX.
      ''';
    }
    getObs = observer;
    return result;
  }

  @override
  Widget build(BuildContext context) => notifyChilds;
}

/// The simplest reactive widget in GetX.
///
/// Just pass your Rx variable in the root scope of the callback to have it
/// automatically registered for changes.
///
/// final _name = "GetX".obs;
/// Obx(() => Text( _name.value )),... ;
class Obx extends ObxWidget {
  final WidgetCallback builder;

  const Obx(this.builder);

  @override
  Widget build() => builder();
}

class Visibility extends StatelessWidget {
  const Visibility({
    Key key,
    @required this.child,
    this.replacement = const WidgetEmpty(),
    this.visible = true,
  })  : assert(child != null),
        assert(replacement != null),
        assert(visible != null),
        super();

  final Widget child;
  final Widget replacement;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return visible ? child : replacement;
  }
}

typedef MultiPartBuilder = Widget Function(
    BuildContext context, MultipartUpload file);

typedef PayloadBuilder = Widget Function(BuildContext context, Map payload);

class MultiPartWidget extends StatefulWidget {
  MultiPartWidget({
    Key key,
    this.name = 'file',
    @required this.builder,
  }) : super(key: key);
  final MultiPartBuilder builder;
  final String name;
  @override
  _MultiPartWidgetState createState() => _MultiPartWidgetState();
}

class _MultiPartWidgetState extends State<MultiPartWidget> {
  @override
  void initState() {
    _decoderFile();
    super.initState();
  }

  MultipartUpload _upload;

  Future<void> _decoderFile() async {
    _upload = await context.file(widget.name);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _upload == null ? WidgetEmpty() : widget.builder(context, _upload);
  }
}

class PayloadWidget extends StatefulWidget {
  final PayloadBuilder builder;
  const PayloadWidget({Key key, @required this.builder}) : super(key: key);

  @override
  _PayloadWidgetState createState() => _PayloadWidgetState();
}

class _PayloadWidgetState extends State<PayloadWidget> {
  Map _payload;
  Widget _error;

  @override
  void initState() {
    _decoderFile();
    super.initState();
  }

  Future<void> _decoderFile() async {
    try {
      _payload = await context.payload();
    } catch (err) {
      _error = Error(error: 'Failed to decode the payload');
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _error ??
        (_payload == null ? WidgetEmpty() : widget.builder(context, _payload));
  }
}

class Error extends StatelessWidget {
  final String error;

  const Error({
    Key key,
    @required this.error,
  })  : assert(error != null),
        super();

  @override
  Widget build(BuildContext context) {
    return Json(ResponseBaseModel(error: error, success: false, data: null));
  }
}
