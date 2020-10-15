import 'package:get_server/get_server.dart';
import 'routes/app_pages.dart';

void main() {
  runApp(
    GetServer(
      getPages: AppPages.routes,
      jwtKey: 'S3CR3T',
      public: Public('example/web'),
    ),
  );
}

// void main() {
//   runApp(
//     GetServer(
//       getPages: AppPages.routes,
//       port: 8443,
//       jwtKey: 'S3CR3T',
//       host: '0.0.0.0',
//       cors: true,
//       certificateChain: 'cert.pem',
//       privateKey: 'cert.key',
//       public: Public('web'),
//     ),
//   );
// }
