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

typedef WidgetCallback = Widget Function(BuildContext context);

class _Wrapper<T> {
  T data;
}

//TODO: Change the name after
abstract class GetWidget<T> extends StatelessWidget {
  final _value = _Wrapper<T>();

  final String tag = null;

  T get controller {
    _value.data ??= GetInstance().find<T>(tag: tag);
    return _value.data;
  }
}

class WidgetEmpty extends Widget {
  @override
  Element createElement(a, b) {
    return _StubElement(this, a, b);
  }
}

class _StubElement extends Element {
  _StubElement(
      Widget widget, ContextRequest request, Stream<GetSocket> socketStream)
      : super(widget, request, socketStream);
}

class WidgetResponse extends StatelessWidget {
  WidgetResponse(this.text, {this.statusCode, this.headers, this.redirectUrl});
  final String text;
  final int statusCode;
  final String headers;
  final String redirectUrl;

  @override
  Widget build(BuildContext context) {
    context.request.response.status(statusCode);
    context.request.response.header(headers);
    context.request.response.send(text);
    context.request.response.redirect(redirectUrl);
    return WidgetEmpty();
  }
}

class Text extends StatelessWidget {
  Text(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    print('text chamado');
    context.request.response.send(text);
    return WidgetEmpty();
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
  HeaderWidget({@required this.child, this.name, this.value});
  final Widget child;
  final String name;
  final Object value;

  @override
  Widget build(BuildContext context) {
    context.request.response.header(name, value);
    return child ?? WidgetEmpty();
  }
}

class Html extends StatelessWidget {
  final String path;
  final Widget child;
  Html({@required this.path, this.child});
  @override
  Widget build(BuildContext context) {
    // context.response.configureHtml();
    context.response.sendFile(path);
    return WidgetEmpty();
  }
}

class HtmlText extends StatelessWidget {
  HtmlText(this.content);
  final String content;

  @override
  Widget build(BuildContext context) {
    context.response.sendHtmlText(content);
    return WidgetEmpty();
  }
}

class Json extends StatelessWidget {
  final Object content;
  Json(this.content);
  @override
  Widget build(BuildContext context) {
    context.response.sendJson(content);
    return WidgetEmpty();
  }
}

typedef WidgetBuilderCallback = Widget Function(BuildContext context);

typedef SocketBuilder = void Function(GetSocket socket);

class Socket extends StatelessWidget {
  Socket({@required this.builder});
  final SocketBuilder builder;
  @override
  Widget build(BuildContext context) {
    context.ws.listen((event) {
      print('ver se isso é chamado sempre');
      builder(event);
    });
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
