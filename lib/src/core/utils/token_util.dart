import 'package:get_server/get_server.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:meta/meta.dart';

abstract class TokenUtil {
  static String generateToken({@required JwtClaim claim}) {
    try {
      var key = getJwtKey();
      var token = issueJwtHS256(claim, key);
      return token;
    } catch (err) {
      rethrow;
    }
  }

  static JwtClaim getClaims(String token) {
    try {
      var key = getJwtKey();
      return verifyJwtHS256Signature(token, key);
    } catch (err) {
      rethrow;
    }
  }

  static String getJwtKey() {
    var key = Get.find<String>(tag: 'jwtKey');
    return key;
  }

  static void saveJwtKey(String jwtKey) {
    Get.put(jwtKey, tag: 'jwtKey');
  }
}
