import '../../../get_core/get_core.dart';

extension Trans on String {
  String get tr {
    // Returns the key if locale is null.
    if (Get.locale?.languageCode == null) return this;

    // Checks whether the language code and country code are present, and
    // whether the key is also present.
    if (Get.translations.containsKey(
            '${Get.locale!.languageCode}_${Get.locale!.countryCode}') &&
        Get.translations[
                '${Get.locale!.languageCode}_${Get.locale!.countryCode}']!
            .containsKey(this)) {
      return Get.translations[
          '${Get.locale!.languageCode}_${Get.locale!.countryCode}']![this]!;

      // Checks if there is a callback language in the absence of the specific
      // country, and if it contains that key.
    } else if (Get.translations.containsKey(Get.locale!.languageCode) &&
        Get.translations[Get.locale!.languageCode]!.containsKey(this)) {
      return Get.translations[Get.locale!.languageCode]![this]!;
      // If there is no corresponding language or corresponding key, return
      // the key.
    } else if (Get.fallbackLocale != null) {
      final fallback = Get.fallbackLocale!;
      final key = '${fallback.languageCode}_${fallback.countryCode}';

      if (Get.translations.containsKey(key) &&
          Get.translations[key]!.containsKey(this)) {
        return Get.translations[key]![this]!;
      }
      if (Get.translations.containsKey(fallback.languageCode) &&
          Get.translations[fallback.languageCode]!.containsKey(this)) {
        return Get.translations[fallback.languageCode]![this]!;
      }
      return this;
    } else {
      return this;
    }
  }

  String trArgs([List<String> args = const []]) {
    var key = tr;
    if (args.isNotEmpty) {
      for (final arg in args) {
        key = key.replaceFirst(RegExp(r'%s'), arg.toString());
      }
    }
    return key;
  }

  String trPlural([String? pluralKey, int? i, List<String> args = const []]) {
    return i == 1 ? pluralKey!.trArgs(args) : trArgs(args);
  }

  String? trParams([Map<String, String> params = const {}]) {
    var trans = tr;
    if (params.isNotEmpty) {
      params.forEach((key, value) {
        trans = trans.replaceAll('@$key', value);
      });
    }
    return trans;
  }

  String? trPluralParams(
      [String? pluralKey, int? i, Map<String, String> params = const {}]) {
    return i == 1 ? pluralKey!.trParams(params) : trParams(params);
  }
}

class _IntlHost {
  Locale? locale;

  Locale? fallbackLocale;

  Map<String, Map<String, String>> translations = {};
}

extension LocalesIntl on GetInterface {
  static final _intlHost = _IntlHost();

  Locale? get locale => _intlHost.locale;

  Locale? get fallbackLocale => _intlHost.fallbackLocale;

  set locale(Locale? newLocale) => _intlHost.locale = newLocale;

  set fallbackLocale(Locale? newLocale) => _intlHost.fallbackLocale = newLocale;

  Map<String, Map<String, String>> get translations => _intlHost.translations;

  void addTranslations(Map<String, Map<String, String>> tr) {
    translations.addAll(tr);
  }

  void appendTranslations(Map<String, Map<String, String>> tr) {
    tr.forEach((key, map) {
      if (translations.containsKey(key)) {
        translations[key]!.addAll(map);
      } else {
        translations[key] = map;
      }
    });
  }
}

class Locale {
  /// Creates a new Locale object. The first argument is the
  /// primary language subtag, the second is the region (also
  /// referred to as 'country') subtag.
  ///
  /// For example:
  ///
  /// ```dart
  /// const Locale swissFrench = Locale('fr', 'CH');
  /// const Locale canadianFrench = Locale('fr', 'CA');
  /// ```
  ///
  /// The primary language subtag must not be null. The region subtag is
  /// optional. When there is no region/country subtag, the parameter should
  /// be omitted or passed `null` instead of an empty-string.
  ///
  /// The subtag values are _case sensitive_ and must be one of the valid
  /// subtags according to CLDR supplemental data:
  /// [language](https://github.com/unicode-org/cldr/blob/master/common/validity/language.xml),
  /// [region](https://github.com/unicode-org/cldr/blob/master/common/validity/region.xml). The
  /// primary language subtag must be at least two and at most eight lowercase
  /// letters, but not four letters. The region region subtag must be two
  /// uppercase letters or three digits. See the [Unicode Language
  /// Identifier](https://www.unicode.org/reports/tr35/#Unicode_language_identifier)
  /// specification.
  ///
  /// Validity is not checked by default, but some methods may throw away
  /// invalid data.
  ///
  /// See also:
  ///
  ///  * [Locale.fromSubtags], which also allows a [scriptCode] to be
  ///    specified.
  const Locale(
    this._languageCode, [
    this._countryCode,
  ])  : assert(_languageCode != null), // ignore: unnecessary_null_comparison
        assert(_languageCode != ''),
        scriptCode = null;

  /// Creates a new Locale object.
  ///
  /// The keyword arguments specify the subtags of the Locale.
  ///
  /// The subtag values are _case sensitive_ and must be valid subtags according
  /// to CLDR supplemental data:
  /// [language](https://github.com/unicode-org/cldr/blob/master/common/validity/language.xml),
  /// [script](https://github.com/unicode-org/cldr/blob/master/common/validity/script.xml) and
  /// [region](https://github.com/unicode-org/cldr/blob/master/common/validity/region.xml) for
  /// each of languageCode, scriptCode and countryCode respectively.
  ///
  /// The [languageCode] subtag is optional. When there is no language subtag,
  /// the parameter should be omitted or set to "und". When not supplied, the
  /// [languageCode] defaults to "und", an undefined language code.
  ///
  /// The [countryCode] subtag is optional. When there is no country subtag,
  /// the parameter should be omitted or passed `null` instead of an empty-string.
  ///
  /// Validity is not checked by default, but some methods may throw away
  /// invalid data.
  const Locale.fromSubtags({
    String languageCode = 'und',
    this.scriptCode,
    String? countryCode,
  })  : assert(languageCode != null), // ignore: unnecessary_null_comparison
        assert(languageCode != ''),
        _languageCode = languageCode,
        assert(scriptCode != ''),
        assert(countryCode != ''),
        _countryCode = countryCode;

  /// The primary language subtag for the locale.
  ///
  /// This must not be null. It may be 'und', representing 'undefined'.
  ///
  /// This is expected to be string registered in the [IANA Language Subtag
  /// Registry](https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry)
  /// with the type "language". The string specified must match the case of the
  /// string in the registry.
  ///
  /// Language subtags that are deprecated in the registry and have a preferred
  /// code are changed to their preferred code. For example, `const
  /// Locale('he')` and `const Locale('iw')` are equal, and both have the
  /// [languageCode] `he`, because `iw` is a deprecated language subtag that was
  /// replaced by the subtag `he`.
  ///
  /// This must be a valid Unicode Language subtag as listed in [Unicode CLDR
  /// supplemental
  /// data](https://github.com/unicode-org/cldr/blob/master/common/validity/language.xml).
  ///
  /// See also:
  ///
  ///  * [Locale.fromSubtags], which describes the conventions for creating
  ///    [Locale] objects.
  String get languageCode =>
      _deprecatedLanguageSubtagMap[_languageCode] ?? _languageCode;
  final String _languageCode;

  // This map is generated by //flutter/tools/gen_locale.dart
  // Mappings generated for language subtag registry as of 2019-02-27.
  static const Map<String, String> _deprecatedLanguageSubtagMap =
      <String, String>{
    'in': 'id', // Indonesian; deprecated 1989-01-01
    'iw': 'he', // Hebrew; deprecated 1989-01-01
    'ji': 'yi', // Yiddish; deprecated 1989-01-01
    'jw': 'jv', // Javanese; deprecated 2001-08-13
    'mo': 'ro', // Moldavian, Moldovan; deprecated 2008-11-22
    'aam': 'aas', // Aramanik; deprecated 2015-02-12
    'adp': 'dz', // Adap; deprecated 2015-02-12
    'aue': 'ktz', // ǂKxʼauǁʼein; deprecated 2015-02-12
    'ayx': 'nun', // Ayi (China); deprecated 2011-08-16
    'bgm': 'bcg', // Baga Mboteni; deprecated 2016-05-30
    'bjd': 'drl', // Bandjigali; deprecated 2012-08-12
    'ccq': 'rki', // Chaungtha; deprecated 2012-08-12
    'cjr': 'mom', // Chorotega; deprecated 2010-03-11
    'cka': 'cmr', // Khumi Awa Chin; deprecated 2012-08-12
    'cmk': 'xch', // Chimakum; deprecated 2010-03-11
    'coy': 'pij', // Coyaima; deprecated 2016-05-30
    'cqu': 'quh', // Chilean Quechua; deprecated 2016-05-30
    'drh': 'khk', // Darkhat; deprecated 2010-03-11
    'drw': 'prs', // Darwazi; deprecated 2010-03-11
    'gav': 'dev', // Gabutamon; deprecated 2010-03-11
    'gfx': 'vaj', // Mangetti Dune ǃXung; deprecated 2015-02-12
    'ggn': 'gvr', // Eastern Gurung; deprecated 2016-05-30
    'gti': 'nyc', // Gbati-ri; deprecated 2015-02-12
    'guv': 'duz', // Gey; deprecated 2016-05-30
    'hrr': 'jal', // Horuru; deprecated 2012-08-12
    'ibi': 'opa', // Ibilo; deprecated 2012-08-12
    'ilw': 'gal', // Talur; deprecated 2013-09-10
    'jeg': 'oyb', // Jeng; deprecated 2017-02-23
    'kgc': 'tdf', // Kasseng; deprecated 2016-05-30
    'kgh': 'kml', // Upper Tanudan Kalinga; deprecated 2012-08-12
    'koj': 'kwv', // Sara Dunjo; deprecated 2015-02-12
    'krm': 'bmf', // Krim; deprecated 2017-02-23
    'ktr': 'dtp', // Kota Marudu Tinagas; deprecated 2016-05-30
    'kvs': 'gdj', // Kunggara; deprecated 2016-05-30
    'kwq': 'yam', // Kwak; deprecated 2015-02-12
    'kxe': 'tvd', // Kakihum; deprecated 2015-02-12
    'kzj': 'dtp', // Coastal Kadazan; deprecated 2016-05-30
    'kzt': 'dtp', // Tambunan Dusun; deprecated 2016-05-30
    'lii': 'raq', // Lingkhim; deprecated 2015-02-12
    'lmm': 'rmx', // Lamam; deprecated 2014-02-28
    'meg': 'cir', // Mea; deprecated 2013-09-10
    'mst': 'mry', // Cataelano Mandaya; deprecated 2010-03-11
    'mwj': 'vaj', // Maligo; deprecated 2015-02-12
    'myt': 'mry', // Sangab Mandaya; deprecated 2010-03-11
    'nad': 'xny', // Nijadali; deprecated 2016-05-30
    'ncp': 'kdz', // Ndaktup; deprecated 2018-03-08
    'nnx': 'ngv', // Ngong; deprecated 2015-02-12
    'nts': 'pij', // Natagaimas; deprecated 2016-05-30
    'oun': 'vaj', // ǃOǃung; deprecated 2015-02-12
    'pcr': 'adx', // Panang; deprecated 2013-09-10
    'pmc': 'huw', // Palumata; deprecated 2016-05-30
    'pmu': 'phr', // Mirpur Panjabi; deprecated 2015-02-12
    'ppa': 'bfy', // Pao; deprecated 2016-05-30
    'ppr': 'lcq', // Piru; deprecated 2013-09-10
    'pry': 'prt', // Pray 3; deprecated 2016-05-30
    'puz': 'pub', // Purum Naga; deprecated 2014-02-28
    'sca': 'hle', // Sansu; deprecated 2012-08-12
    'skk': 'oyb', // Sok; deprecated 2017-02-23
    'tdu': 'dtp', // Tempasuk Dusun; deprecated 2016-05-30
    'thc': 'tpo', // Tai Hang Tong; deprecated 2016-05-30
    'thx': 'oyb', // The; deprecated 2015-02-12
    'tie': 'ras', // Tingal; deprecated 2011-08-16
    'tkk': 'twm', // Takpa; deprecated 2011-08-16
    'tlw': 'weo', // South Wemale; deprecated 2012-08-12
    'tmp': 'tyj', // Tai Mène; deprecated 2016-05-30
    'tne': 'kak', // Tinoc Kallahan; deprecated 2016-05-30
    'tnf': 'prs', // Tangshewi; deprecated 2010-03-11
    'tsf': 'taj', // Southwestern Tamang; deprecated 2015-02-12
    'uok': 'ema', // Uokha; deprecated 2015-02-12
    'xba': 'cax', // Kamba (Brazil); deprecated 2016-05-30
    'xia': 'acn', // Xiandao; deprecated 2013-09-10
    'xkh': 'waw', // Karahawyana; deprecated 2016-05-30
    'xsj': 'suj', // Subi; deprecated 2015-02-12
    'ybd': 'rki', // Yangbye; deprecated 2012-08-12
    'yma': 'lrr', // Yamphe; deprecated 2012-08-12
    'ymt': 'mtm', // Mator-Taygi-Karagas; deprecated 2015-02-12
    'yos': 'zom', // Yos; deprecated 2013-09-10
    'yuu': 'yug', // Yugh; deprecated 2014-02-28
  };

  /// The script subtag for the locale.
  ///
  /// This may be null, indicating that there is no specified script subtag.
  ///
  /// This must be a valid Unicode Language Identifier script subtag as listed
  /// in [Unicode CLDR supplemental
  /// data](https://github.com/unicode-org/cldr/blob/master/common/validity/script.xml).
  ///
  /// See also:
  ///
  ///  * [Locale.fromSubtags], which describes the conventions for creating
  ///    [Locale] objects.
  final String? scriptCode;

  /// The region subtag for the locale.
  ///
  /// This may be null, indicating that there is no specified region subtag.
  ///
  /// This is expected to be string registered in the [IANA Language Subtag
  /// Registry](https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry)
  /// with the type "region". The string specified must match the case of the
  /// string in the registry.
  ///
  /// Region subtags that are deprecated in the registry and have a preferred
  /// code are changed to their preferred code. For example, `const Locale('de',
  /// 'DE')` and `const Locale('de', 'DD')` are equal, and both have the
  /// [countryCode] `DE`, because `DD` is a deprecated language subtag that was
  /// replaced by the subtag `DE`.
  ///
  /// See also:
  ///
  ///  * [Locale.fromSubtags], which describes the conventions for creating
  ///    [Locale] objects.
  String? get countryCode =>
      _deprecatedRegionSubtagMap[_countryCode] ?? _countryCode;
  final String? _countryCode;

  // This map is generated by //flutter/tools/gen_locale.dart
  // Mappings generated for language subtag registry as of 2019-02-27.
  static const Map<String, String> _deprecatedRegionSubtagMap =
      <String, String>{
    'BU': 'MM', // Burma; deprecated 1989-12-05
    'DD': 'DE', // German Democratic Republic; deprecated 1990-10-30
    'FX': 'FR', // Metropolitan France; deprecated 1997-07-14
    'TP': 'TL', // East Timor; deprecated 2002-05-20
    'YD': 'YE', // Democratic Yemen; deprecated 1990-08-14
    'ZR': 'CD', // Zaire; deprecated 1997-07-14
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Locale) {
      return false;
    }
    final String? countryCode = _countryCode;
    final String? otherCountryCode = other.countryCode;
    return other.languageCode == languageCode &&
        other.scriptCode == scriptCode // scriptCode cannot be ''
        &&
        (other.countryCode == countryCode // Treat '' as equal to null.
            ||
            otherCountryCode != null &&
                otherCountryCode.isEmpty &&
                countryCode == null ||
            countryCode != null &&
                countryCode.isEmpty &&
                other.countryCode == null);
  }

  @override
  int get hashCode => hashValues(
      languageCode, scriptCode, countryCode == '' ? null : countryCode);

  static Locale? _cachedLocale;
  static String? _cachedLocaleString;

  /// Returns a string representing the locale.
  ///
  /// This identifier happens to be a valid Unicode Locale Identifier using
  /// underscores as separator, however it is intended to be used for debugging
  /// purposes only. For parsable results, use [toLanguageTag] instead.
  @override
  String toString() {
    if (!identical(_cachedLocale, this)) {
      _cachedLocale = this;
      _cachedLocaleString = _rawToString('_');
    }
    return _cachedLocaleString!;
  }

  /// Returns a syntactically valid Unicode BCP47 Locale Identifier.
  ///
  /// Some examples of such identifiers: "en", "es-419", "hi-Deva-IN" and
  /// "zh-Hans-CN". See http://www.unicode.org/reports/tr35/ for technical
  /// details.
  String toLanguageTag() => _rawToString('-');

  String _rawToString(String separator) {
    final out = StringBuffer(languageCode);
    if (scriptCode != null && scriptCode!.isNotEmpty) {
      out.write('$separator$scriptCode');
    }
    if (_countryCode != null && _countryCode!.isNotEmpty) {
      out.write('$separator$countryCode');
    }
    return out.toString();
  }
}

class _HashEnd {
  const _HashEnd();
}

const _HashEnd _hashEnd = _HashEnd();

/// Jenkins hash function, optimized for small integers.
//
// Borrowed from the dart sdk: sdk/lib/math/jenkins_smi_hash.dart.
class _Jenkins {
  static int combine(int hash, Object? o) {
    assert(o is! Iterable);
    hash = 0x1fffffff & (hash + o.hashCode);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Combine up to twenty objects' hash codes into one value.
///
/// If you only need to handle one object's hash code, then just refer to its
/// [Object.hashCode] getter directly.
///
/// If you need to combine an arbitrary number of objects from a [List] or other
/// [Iterable], use [hashList]. The output of [hashList] can be used as one of
/// the arguments to this function.
///
/// For example:
///
/// ```dart
/// int hashCode => hashValues(foo, bar, hashList(quux), baz);
/// ```
int hashValues(Object? arg01, Object? arg02,
    [Object? arg03 = _hashEnd,
    Object? arg04 = _hashEnd,
    Object? arg05 = _hashEnd,
    Object? arg06 = _hashEnd,
    Object? arg07 = _hashEnd,
    Object? arg08 = _hashEnd,
    Object? arg09 = _hashEnd,
    Object? arg10 = _hashEnd,
    Object? arg11 = _hashEnd,
    Object? arg12 = _hashEnd,
    Object? arg13 = _hashEnd,
    Object? arg14 = _hashEnd,
    Object? arg15 = _hashEnd,
    Object? arg16 = _hashEnd,
    Object? arg17 = _hashEnd,
    Object? arg18 = _hashEnd,
    Object? arg19 = _hashEnd,
    Object? arg20 = _hashEnd]) {
  int result = 0;
  result = _Jenkins.combine(result, arg01);
  result = _Jenkins.combine(result, arg02);
  if (!identical(arg03, _hashEnd)) {
    result = _Jenkins.combine(result, arg03);
    if (!identical(arg04, _hashEnd)) {
      result = _Jenkins.combine(result, arg04);
      if (!identical(arg05, _hashEnd)) {
        result = _Jenkins.combine(result, arg05);
        if (!identical(arg06, _hashEnd)) {
          result = _Jenkins.combine(result, arg06);
          if (!identical(arg07, _hashEnd)) {
            result = _Jenkins.combine(result, arg07);
            if (!identical(arg08, _hashEnd)) {
              result = _Jenkins.combine(result, arg08);
              if (!identical(arg09, _hashEnd)) {
                result = _Jenkins.combine(result, arg09);
                if (!identical(arg10, _hashEnd)) {
                  result = _Jenkins.combine(result, arg10);
                  if (!identical(arg11, _hashEnd)) {
                    result = _Jenkins.combine(result, arg11);
                    if (!identical(arg12, _hashEnd)) {
                      result = _Jenkins.combine(result, arg12);
                      if (!identical(arg13, _hashEnd)) {
                        result = _Jenkins.combine(result, arg13);
                        if (!identical(arg14, _hashEnd)) {
                          result = _Jenkins.combine(result, arg14);
                          if (!identical(arg15, _hashEnd)) {
                            result = _Jenkins.combine(result, arg15);
                            if (!identical(arg16, _hashEnd)) {
                              result = _Jenkins.combine(result, arg16);
                              if (!identical(arg17, _hashEnd)) {
                                result = _Jenkins.combine(result, arg17);
                                if (!identical(arg18, _hashEnd)) {
                                  result = _Jenkins.combine(result, arg18);
                                  if (!identical(arg19, _hashEnd)) {
                                    result = _Jenkins.combine(result, arg19);
                                    if (!identical(arg20, _hashEnd)) {
                                      result = _Jenkins.combine(result, arg20);
                                      // I can see my house from here!
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  return _Jenkins.finish(result);
}

/// Combine the [Object.hashCode] values of an arbitrary number of objects from
/// an [Iterable] into one value. This function will return the same value if
/// given null as if given an empty list.
int hashList(Iterable<Object?>? arguments) {
  int result = 0;
  if (arguments != null) {
    for (final Object? argument in arguments) {
      result = _Jenkins.combine(result, argument);
    }
  }
  return _Jenkins.finish(result);
}
