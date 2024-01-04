# Get Server

　GetServerでは、Flutterを使用してバックエンドアプリケーションを開発できます。ここのすべてはよく知られていて、ウィジェットからsetState、initState、disposeメソッド、コントローラとバインドを使用してGetXを使用してプロジェクトを管理する方法までです。GetServerを使用するには追加の知識は必要ありません。Flutterを知っている場合は、アプリケーションのAPIを記述するために使用できます。
　GetServerを使用すると、バックエンドとフロントエンドの間でコードを100%再使用できます。

![](get_server.png)


　Flutterはますます人気を集めており、その発展に伴い、同じStackを使いたい開発者にも新たなニーズが生まれています。
　GetXの使いやすさと実用性は、Flutterを使用してモバイル、デスクトップ、Webアプリケーションを構築するために日々多くの新しい開発者を引きつけています。しかし、GetXコミュニティは、大きな学習曲線のバックエンドでプログラムされていない凝集力のある生態系が欠けているという共通のニーズに向かっています。
　このプロジェクトの目的は、これらの開発者のニーズを満たすことであり、学習曲線が0%のバックエンドアプリケーションを構築できるようになりました。もしすでに別の言語でプログラミングしていたら、テストしましょう、もし良いと感じて、あるいは別の言語をマスターして、GetServerはあなたに合わないかもしれませんが、喜んで人々の生活に便利をもたらして、だからモバイルプログラミングに対して、しかしapiをどのように作成するか分からないならば、すでに欲しいものを見つけたかもしれません。
　dartで作成されたローカルデータベース（HiveやSembastなど）があれば、バックエンドにすることができます。

## はじめに

 インストール

pubspec.yamlファイルにGetを追加するには：

`dart create project`を実行し、pubspecに追加します：

```yaml
dependencies:
  get_server:
```

使用するファイルにGetをインポートするには：

```dart
import 'package:get_server/get_server.dart';
```

サーバーを作成してプレーンテキストを送信するには：。

```dart
void main() {
  runApp(
    GetServerApp(
      home: Home(),
    ),
  );
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Welcome to GetX!');
  }
}
```

ただし、シングルページを必要としない場合は、urlを定義するために命名Routeが必要です。これは非常に簡単で、フロントエンドのGetXのRouteと同じです

```dart
void main() {
  runApp(GetServerApp(
    getPages: [
      GetPage(name: '/', page:()=> Home()),
    ],
  ));
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text("Welcome to GetX");
  }
}
```

URLのパスと、渡したいページを定義するだけです！

jsonに返却したい場合はどうしますか？

```dart
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Json({
      "fruits": ["banana", "apple", "orange"]
    });
  }
}
```

　さて、Flutter webを使ってプロジェクトを作成しましたが、VPSでホスティングする方法がわかりません。アプリケーションのAPIを作成し、同じGetXを使ってFlutter webプロジェクトを表示することができますか？

　はい。FlutterプロジェクトからWebフォルダをコピーし、サーバファイルからディレクトリに貼り付けるだけです。

　Flutter　webはjsファイルを呼び出すhtmlファイルを生成し、jsファイルはパブリックフォルダに必要ないくつかのファイルを逆に要求します。Flutter Webフォルダをパブリックフォルダにするには、GetServerに追加するだけです。これにより、サーバにアクセスすると、Flutterを使用して作成されたWebサイトに自動的にブートされます。

```dart
void main() {
  runApp(
    GetServerApp(
      home: FolderWidget('web'),
      getPages: [
        GetPage(name: '/api', page: () => ApiPage()),
      ],
    ),
  );
}
```

-注：静的フォルダはルートフォルダのみです。「/」ルーティングを置換します。

サーバからファイルを呼び出さず、外部ファイルのみを呼び出すhtmlウィジェットがある場合は、特定のパスにhtmlウィジェットを使用できます。

```dart
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final path = '${Directory.current.path}/web/index.html';
    return Html(path);
  }
}
```

　いいでしょうが、POST方法で写真をサーバーに送信したい場合、例えば、どうすればいいのでしょうか？

　これはクレイジーに聞こえますが、ファイルをサーバーにアップロードし、「upload.data」で取ります。
　この例を小さくしないために、ファイル名、mimeType、base 64で復号された同じファイルを含むjson応答を返します。この例は5行だけではありません。

```dart
class Home extends GetView {
  @override
  Widget build(BuildContext context) {
    return MultiPartWidget(
      builder: (context, upload) {
        return Json({
           "nameFile": upload.name,
           "mimeType": upload.mimeType,
           "fileBase64": "${base64Encode(upload.data)}",
        });
      },
    );
  }
}
```


認証方法もあります。

１、jwtKeyを定義します。
```dart
void main() {
  runApp(
   GetServerApp(
    jwtKey: 'your key here',
   ),
  );
}
```
２、トークンを取り戻すことです。
```dart
final claimSet = JwtClaim(
  expiry: DateTime.now().add(Duration(days: 3)),
  issuer: 'get is awesome',
  issuedAt: DateTime.now(),
);

var token = TokenUtil.generateToken(claim: claimSet);
```
３、トークンが必要なRouteをマークするだけです。
```dart
GetPage(
  name: '/awesome-route',
  method: Method.get,
  page: () => YourPage(),
  needAuth: true,
),
```

まだ信じていません。これはhttpサーバーにすぎませんが、リアルタイム通信のチャットを作成したい場合は、どうすればいいですか？

さて、今日はあなたの幸運の日です。これはhttpサーバだけでなく、websocketサーバでもあります。

```dart
class SocketPage extends GetView {
  @override
  Widget build(BuildContext context) {
     return Socket(builder: (socket) {
      socket.onOpen((ws) {
        ws.send('socket ${ws.id} connected');
      });

      socket.on('join', (val) {
        final join = socket.join(val);
        if (join) {
          socket.sendToRoom(val, 'socket: ${socket.hashCode} join to room');
        }
      });
      socket.onMessage((data) {
        print('data: $data');
        socket.send(data);
      });

      socket.onClose((close) {
        print('socket has closed. Reason: ${close.message}');
      });
    });
  }
}

```

　しかし、dartはサーバ上では流行しておらず、Flutterでプログラムされている人をバックエンドに引き付けることもGetXの使命である。1次元プログラマを0%ラーニングカーブを持つフルスタック開発者に変更し、コードを再利用することもGetXの目標の1つです。この旅で私たちを助けてほしいと思います。


　Get-ServerのCIを使用すると簡単に、上記の内容を含むファイルを作成し、`.github/workflows/main.yml` に入れて、ワークピースとしてlinux/windows/macに対するサーバのバイナリコンパイルを取得できます。


```yaml
name: CI Building native server

on:
  # Triggers the workflow on push or pull request events but only for the main branch
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

  # Allows you to run this workflow manually from the Actions tab
  workflow_dispatch:

jobs:
  build:
    runs-on: ${{ matrix.os }}

    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macOS-latest]
        include:
          - os: ubuntu-latest
            output-name: server-linux
          - os: macOS-latest
            output-name: server-mac
          - os: windows-latest
            output-name: server-windows.exe
    steps:
          - uses: actions/checkout@v2
          - uses: dart-lang/setup-dart@v1.3
          - name: Install dependencies
            run: dart pub get
          - run: mkdir build
          - name: Install Dependencies
            run: dart pub get
          - run: dart compile exe ./lib/main.dart -v -o build/${{ matrix.output-name }}
          - uses: actions/upload-artifact@v1
            with:
                name: native-executables
                path: build

```

### 　ほとんどの「node.js」方式のように？

　このパッケージの目的は、Flutter開発者の開発を容易にすることです。しかし、javascriptの生態系は非常に大きく、より実用的な文法に慣れるかもしれません。

　get _ serverを使用すると、このパスを使用できます。get _ serverも使用できます。

```dart
import 'package:get_server/get_server.dart';
void main() {
  final app = GetServer();
  app.get('/', (ctx) => Text('Get_server of javascript way'));
  app.ws('/socket', (ws) {
    ws.onMessage((data) {
      print('data: $data');
    });

    ws.onOpen((ws) {
      print('new socket opened');
    });

    ws.onClose((ws) {
      print('socket has been closed');
    });
  });
}
```

### より強力

Getserverをコアの少ない安価なサーバにホストする場合は、デフォルトのオプションで十分です。ただし、複数のコアを持つサーバがあり、それを活用したい場合は、アイソレーションを使用してマルチスレッドサーバを起動できます。これはほんの一歩だけ必要です。

グローバル関数（スタンドアロン要件）を作成し、runAppを挿入して`runIsolate`で起動します。


```dart
void main() {
  runIsolate(init);
}

void init(_) {
  runApp(
    GetServerApp(
      home: Home(),
    ),
  );
}
```

注：これはCPUごとにスレッドを作成する関数で、GetServerを使用してアプリケーション全体で使用できます。高いCPUとメモリアクティビティを持つアクティビティが必要な場合は、runIsolateを使用します。

### 何かお手伝いできますか？

- Pull Requestを作成し、リソースを追加し、ドキュメントを改善し、サンプルアプリケーションを作成し、Getxに関する記事やビデオを作成し、改善提案を行い、開発コミュニティでこのフレームワークを伝播するのに役立ちます。

- プロジェクトをサポートします。

TODO:
- ~認証オプションの追加~
- ~削除要件。dart：mirrorsは、サーバをコンパイルし、バイナリファイルのみを使用してソースコードを保護することを許可します。~
- ~メインGetXなどのバインドとコントローラを作成して、プロジェクトをフロントエンドのGetX。~
- ORMを追加


### Get Serverのアクセス:

　Get Serverはデフォルトでポート8080で起動します。
　このようにするのは、nginxのようなリバースエージェントをインストールしたいなら、あまり努力する必要はありません。
　たとえば、この例で作成したホームページには、次の方法でアクセスできます。

`http://localhost:8080/`
あるいは
`http://127.0.0.1:8080/`

　ただし、別のポート（たとえば80）で起動したい場合は、次の操作を実行するだけです。

```dart
void main() {
  runApp(GetServer(
    port: 80,
    getPages: [
      GetPage(name: '/', page:()=> Home()),
    ],
  ));
}
```

SSLの場合、GetServerにも`certificateChain`, `privateKey`, `password`の構成があります。