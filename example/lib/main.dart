import 'package:get_server/get_server.dart';
import 'routes/app_pages.dart';

void main() {
  runApp(
    GetServer(
      getPages: AppPages.routes,
      port: 8080,
      jwtKey: 'S3CR3T',
      cors: true,
    ),
  );
}
