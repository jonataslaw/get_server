part of server;

abstract class GetView<T> extends StatelessWidget {
  final String? tag = null;

  T get controller => GetInstance().find<T>(tag: tag);
  @override
  Widget build(BuildContext context);
}

abstract class GetEndpoint<T> extends StatelessWidget {
  final String? tag = null;

  T get controller => GetInstance().find<T>(tag: tag);
  @override
  Widget build(BuildContext context);
}

class _Wrapper<T> {
  T? data;
}

abstract class GetWidget<T> extends StatelessWidget {
  final _value = _Wrapper<T>();

  final String? tag = null;

  T? get controller {
    _value.data ??= GetInstance().find<T>(tag: tag);
    return _value.data;
  }
}

class WidgetEmpty extends Widget {
  const WidgetEmpty({Key? key}) : super(key: key);
  @override
  Element? createElement(request, getSocket) {
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
  final Map? headers;

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
  PageRedirect({required this.redirectUrl, this.statusCode = 302});
  final String redirectUrl;
  final int statusCode;

  @override
  Widget build(BuildContext context) {
    context.request.response!.redirect(redirectUrl, statusCode);
    return WidgetEmpty();
  }
}

class StatusCode extends StatelessWidget {
  StatusCode({required this.child, required this.statusCode});
  final Widget child;
  final int statusCode;

  @override
  Widget build(BuildContext context) {
    context.request.response!.status(statusCode);
    return child;
  }
}

class HeaderWidget extends StatelessWidget {
  HeaderWidget({required this.child, required this.name, required this.value});
  final Widget child;
  final String name;
  final Object value;

  @override
  Widget build(BuildContext context) {
    context.request.response!.header(name, value);

    return child;
  }
}

class FullHeadersWidget extends StatelessWidget {
  FullHeadersWidget({
    required this.child,
    required this.headers,
  });
  final Widget child;
  final Map? headers;

  @override
  Widget build(BuildContext context) {
    if (headers != null) {
      headers!.forEach((key, value) {
        context.request.response!.header(key, value);
      });
    }
    return child;
  }
}

abstract class SenderWidget extends StatelessWidget {}

class Html extends SenderWidget {
  final String path;
  Html({required this.path});
  @override
  Widget build(BuildContext context) {
    context.response!.sendFile(path);
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
    context.request.response!.send(text);
    return WidgetEmpty();
  }
}

class HtmlText extends SenderWidget {
  HtmlText(this.content);
  final String content;

  @override
  Widget build(BuildContext context) {
    context.response!.sendHtmlText(content);
    return WidgetEmpty();
  }
}

class Json extends SenderWidget {
  final dynamic content;
  Json(this.content);
  @override
  Widget build(BuildContext context) {
    final data =
        (content is Map || content is Iterable) ? content : content.toJson();
    context.response!.sendJson(data);
    return WidgetEmpty();
  }
}

typedef WidgetBuilderCallback = Widget Function(BuildContext context);

typedef SocketBuilder = void Function(GetSocket socket);

class Socket extends SenderWidget {
  Socket({required this.builder});
  final SocketBuilder builder;
  @override
  Widget build(BuildContext context) {
    var event = context.getSocket;
    event!.rawSocket.done.then((value) {
      event = null;
    });
    builder(event!);

    return WidgetEmpty();
  }
}

class WidgetBuilder extends StatelessWidget {
  final WidgetBuilderCallback builder;

  const WidgetBuilder({
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(context);
}

typedef WidgetCallback = Widget Function();

typedef NodeWidgetCallback = Widget Function(BuildContext ctx);

abstract class ObxWidget extends StatefulWidget {
  const ObxWidget({Key? key}) : super(key: key);

  @override
  ObxState createState() => ObxState();

  @protected
  Widget build();
}

class ObxState extends State<ObxWidget> {
  RxInterface? _observer;
  late StreamSubscription subs;

  ObxState() {
    _observer = RxNotifier();
  }

  @override
  void initState() {
    subs = _observer!.listen(_updateTree);
    super.initState();
  }

  void _updateTree(_) {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    subs.cancel();
    _observer!.close();
    super.dispose();
  }

  Widget get notifyChilds {
    final observer = RxInterface.proxy;
    RxInterface.proxy = _observer;
    final result = widget.build();
    if (!_observer!.canUpdate) {
      throw '''
      [Get] the improper use of a GetX has been detected. 
      You should only use GetX or Obx for the specific widget that will be updated.
      If you are seeing this error, you probably did not insert any observable variables into GetX/Obx 
      or insert them outside the scope that GetX considers suitable for an update 
      (example: GetX => HeavyWidget => variableObservable).
      If you need to update a parent widget and a child widget, wrap each one in an Obx/GetX.
      ''';
    }
    RxInterface.proxy = observer;
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
    Key? key,
    required this.child,
    this.replacement = const WidgetEmpty(),
    this.visible = true,
  }) : super(key: key);

  final Widget child;
  final Widget replacement;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return visible ? child : replacement;
  }
}

typedef MultiPartBuilder = Widget Function(
    BuildContext context, MultipartUpload? file);

typedef PayloadBuilder = Widget Function(BuildContext context, Map? payload);

class MultiPartWidget extends StatefulWidget {
  MultiPartWidget({
    Key? key,
    this.name = 'file',
    required this.builder,
  }) : super(key: key);
  final MultiPartBuilder builder;
  final String name;
  @override
  MultiPartWidgetState createState() => MultiPartWidgetState();
}

class MultiPartWidgetState extends State<MultiPartWidget> {
  @override
  void initState() {
    _decoderFile();
    super.initState();
  }

  MultipartUpload? _upload;

  Future<void> _decoderFile() async {
    _upload = await context.file(widget.name);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _upload != null ? widget.builder(context, _upload) : WidgetEmpty();
  }
}

class PayloadWidget extends StatefulWidget {
  final PayloadBuilder builder;
  final bool payloadRequired;
  const PayloadWidget({
    Key? key,
    required this.builder,
    this.payloadRequired = true,
  }) : super(key: key);

  @override
  PayloadWidgetState createState() => PayloadWidgetState();
}

class PayloadWidgetState extends State<PayloadWidget> {
  Map? _payload;
  Widget? _error;
  bool visible = false;

  @override
  void initState() {
    _decoderFile();
    super.initState();
  }

  Future<void> _decoderFile() async {
    try {
      _payload = await context.payload();
      if (widget.payloadRequired && _payload == null) {
        _error = Error(error: 'Payload is required!');
      }
    } catch (err) {
      _error = Error(error: 'Failed to decode the payload!');
    }

    setState(() => visible = true);
  }

  @override
  Widget build(BuildContext context) {
    return !visible
        ? WidgetEmpty()
        : _error ?? widget.builder(context, _payload);
  }
}

class Error extends StatelessWidget {
  final String error;

  const Error({
    Key? key,
    required this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Json(ResponseBaseModel(error: error, success: false, data: null));
  }
}

class FutureBuilder<T> extends StatefulWidget {
  /// Creates a widget that builds itself based on the latest snapshot of
  /// interaction with a [Future].
  ///
  /// The [builder] must not be null.
  const FutureBuilder({
    Key? key,
    this.future,
    this.initialData,
    required this.builder,
  }) : super(key: key);

  /// The asynchronous computation to which this builder is currently connected,
  /// possibly null.
  ///
  /// If no future has yet completed, including in the case where [future] is
  /// null, the data provided to the [builder] will be set to [initialData].
  final Future<T>? future;

  /// The build strategy currently used by this builder.
  ///
  /// The builder is provided with an [AsyncSnapshot] object whose
  /// [AsyncSnapshot.connectionState] property will be one of the following
  /// values:
  ///
  ///  * [ConnectionState.none]: [future] is null. The [AsyncSnapshot.data] will
  ///    be set to [initialData], unless a future has previously completed, in
  ///    which case the previous result persists.
  ///
  ///  * [ConnectionState.waiting]: [future] is not null, but has not yet
  ///    completed. The [AsyncSnapshot.data] will be set to [initialData],
  ///    unless a future has previously completed, in which case the previous
  ///    result persists.
  ///
  ///  * [ConnectionState.done]: [future] is not null, and has completed. If the
  ///    future completed successfully, the [AsyncSnapshot.data] will be set to
  ///    the value to which the future completed. If it completed with an error,
  ///    [AsyncSnapshot.hasError] will be true and [AsyncSnapshot.error] will be
  ///    set to the error object.
  ///
  /// This builder must only return a widget and should not have any side
  /// effects as it may be called multiple times.
  final AsyncWidgetBuilder<T> builder;

  /// The data that will be used to create the snapshots provided until a
  /// non-null [future] has completed.
  ///
  /// If the future completes with an error, the data in the [AsyncSnapshot]
  /// provided to the [builder] will become null, regardless of [initialData].
  /// (The error itself will be available in [AsyncSnapshot.error], and
  /// [AsyncSnapshot.hasError] will be true.)
  final T? initialData;

  @override
  State<FutureBuilder<T?>> createState() => _FutureBuilderState<T>();
}

/// State for [FutureBuilder].
class _FutureBuilderState<T> extends State<FutureBuilder<T?>> {
  /// An object that identifies the currently active callbacks. Used to avoid
  /// calling setState from stale callbacks, e.g. after disposal of this state,
  /// or after widget reconfiguration to a new Future.
  Object? _activeCallbackIdentity;
  AsyncSnapshot<T?>? _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initialData == null
        ? AsyncSnapshot<T>.nothing()
        : AsyncSnapshot<T?>.withData(ConnectionState.none, widget.initialData);
    _subscribe();
  }

  @override
  void didUpdateWidget(FutureBuilder<T?> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.future != widget.future) {
      if (_activeCallbackIdentity != null) {
        _unsubscribe();
        _snapshot = _snapshot!.inState(ConnectionState.none);
      }
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _snapshot);

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    if (widget.future != null) {
      final callbackIdentity = Object();
      _activeCallbackIdentity = callbackIdentity;
      widget.future!.then<void>((T? data) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T?>.withData(ConnectionState.done, data);
          });
        }
      }, onError: (Object error, StackTrace stackTrace) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withError(
                ConnectionState.done, error, stackTrace);
          });
        }
      });
      _snapshot = _snapshot!.inState(ConnectionState.waiting);
    }
  }

  void _unsubscribe() {
    _activeCallbackIdentity = null;
  }
}

typedef AsyncWidgetBuilder<T> = Widget Function(
    BuildContext context, AsyncSnapshot<T>? snapshot);

@immutable
class AsyncSnapshot<T> {
  /// Creates an [AsyncSnapshot] with the specified [connectionState],
  /// and optionally either [data] or [error] with an optional [stackTrace]
  /// (but not both data and error).
  const AsyncSnapshot._(
      this.connectionState, this.data, this.error, this.stackTrace)
      : assert(!(data != null && error != null)),
        assert(stackTrace == null || error != null);

  /// Creates an [AsyncSnapshot] in [ConnectionState.none] with null data and error.
  const AsyncSnapshot.nothing()
      : this._(ConnectionState.none, null, null, null);

  /// Creates an [AsyncSnapshot] in [ConnectionState.waiting] with null data and error.
  const AsyncSnapshot.waiting()
      : this._(ConnectionState.waiting, null, null, null);

  /// Creates an [AsyncSnapshot] in the specified [state] and with the specified [data].
  const AsyncSnapshot.withData(ConnectionState state, T data)
      : this._(state, data, null, null);

  /// Creates an [AsyncSnapshot] in the specified [state] with the specified [error]
  /// and a [stackTrace].
  ///
  /// If no [stackTrace] is explicitly specified, [StackTrace.empty] will be used instead.
  const AsyncSnapshot.withError(
    ConnectionState state,
    Object error, [
    StackTrace stackTrace = StackTrace.empty,
  ]) : this._(state, null, error, stackTrace);

  /// Current state of connection to the asynchronous computation.
  final ConnectionState connectionState;

  /// The latest data received by the asynchronous computation.
  ///
  /// If this is non-null, [hasData] will be true.
  ///
  /// If [error] is not null, this will be null. See [hasError].
  ///
  /// If the asynchronous computation has never returned a value, this may be
  /// set to an initial data value specified by the relevant widget. See
  /// [FutureBuilder.initialData] and [StreamBuilder.initialData].
  final T? data;

  /// Returns latest data received, failing if there is no data.
  ///
  /// Throws [error], if [hasError]. Throws [StateError], if neither [hasData]
  /// nor [hasError].
  T? get requireData {
    if (hasData) return data;
    if (hasError) throw error!;
    throw StateError('Snapshot has neither data nor error');
  }

  /// The latest error object received by the asynchronous computation.
  ///
  /// If this is non-null, [hasError] will be true.
  ///
  /// If [data] is not null, this will be null.
  final Object? error;

  /// The latest stack trace object received by the asynchronous computation.
  ///
  /// This will not be null iff [error] is not null. Consequently, [stackTrace]
  /// will be non-null when [hasError] is true.
  ///
  /// However, even when not null, [stackTrace] might be empty. The stack trace
  /// is empty when there is an error but no stack trace has been provided.
  final StackTrace? stackTrace;

  /// Returns a snapshot like this one, but in the specified [state].
  ///
  /// The [data], [error], and [stackTrace] fields persist unmodified, even if
  /// the new state is [ConnectionState.none].
  AsyncSnapshot<T> inState(ConnectionState state) =>
      AsyncSnapshot<T>._(state, data, error, stackTrace);

  /// Returns whether this snapshot contains a non-null [data] value.
  ///
  /// This can be false even when the asynchronous computation has completed
  /// successfully, if the computation did not return a non-null value. For
  /// example, a [Future<void>] will complete with the null value even if it
  /// completes successfully.
  bool get hasData => data != null;

  /// Returns whether this snapshot contains a non-null [error] value.
  ///
  /// This is always true if the asynchronous computation's last result was
  /// failure.
  bool get hasError => error != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AsyncSnapshot<T> &&
        other.connectionState == connectionState &&
        other.data == data &&
        other.error == error &&
        other.stackTrace == stackTrace;
  }

  @override
  int get hashCode => Object.hash(connectionState, data, error);
}

enum ConnectionState {
  /// Not currently connected to any asynchronous computation.
  ///
  /// For example, a [FutureBuilder] whose [FutureBuilder.future] is null.
  none,

  /// Connected to an asynchronous computation and awaiting interaction.
  waiting,

  /// Connected to an active asynchronous computation.
  ///
  /// For example, a [Stream] that has returned at least one value, but is not
  /// yet done.
  active,

  /// Connected to a terminated asynchronous computation.
  done,
}
