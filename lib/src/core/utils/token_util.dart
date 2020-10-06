import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:meta/meta.dart';

abstract class TokenUtil {
  static String generateToken({
    @required JwtClaim claim,
    @required String jwtKey,
  }) {
    try {
      var token = issueJwtHS256(claim, jwtKey);
      return token;
    } catch (err) {
      rethrow;
    }
  }
}
