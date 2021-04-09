part of server;

abstract class TokenUtil {
  static String generateToken({required JwtClaim claim}) {
    try {
      var key = getJwtKey()!;
      var token = issueJwtHS256(claim, key);
      return token;
    } catch (err) {
      rethrow;
    }
  }

  static JwtClaim getClaims(String token) {
    try {
      var key = getJwtKey()!;
      return verifyJwtHS256Signature(token, key);
    } catch (err) {
      rethrow;
    }
  }

  static String? getJwtKey() {
    var key = Get.find<String?>(tag: 'jwtKey');
    return key;
  }

  static void saveJwtKey(String? jwtKey) {
    Get.put(jwtKey, tag: 'jwtKey');
  }

  static String getTokenFromHeader(ContextRequest request) {
    var token = request.header('Authorization')!.first as String;
    token = token.replaceAll('Bearer ', '');

    return token;
  }

  static String? getSubjectFromToken(ContextRequest request) {
    var token = getTokenFromHeader(request);
    var claims = getClaims(token);
    return claims.subject;
  }
}
