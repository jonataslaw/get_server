import 'package:get_server/get_server.dart';

class VisibilityPage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<VisibilityPage> {
  bool visible = false;

  @override
  void initState() {
    print('initState called');
    _fireTextAfterTwoSeconds();
    super.initState();
  }

  Future<void> _fireTextAfterTwoSeconds() async {
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      visible = true;
    });
    print('setState called');
  }

  @override
  void dispose() {
    print('dispose called');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: Text('After 2 seconds, Text appear'),
    );
  }
}
