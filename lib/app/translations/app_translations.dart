import 'package:get/get.dart';
import 'en_us.dart';
import 'ur_pk.dart';

/// AppTranslations — registers English and Urdu translation maps with GetX.
/// Used by GetMaterialApp's `translations` parameter.
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en': enUs,
        'ur': urPk,
      };
}

