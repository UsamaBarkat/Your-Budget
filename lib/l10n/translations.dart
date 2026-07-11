import 'strings_en.dart';
import 'strings_ur.dart';
import 'strings_sd.dart';

const _strings = <String, Map<String, Map<String, String>>>{
  'en': stringsEn,
  'ur': stringsUr,
  'sd': stringsSd,
};

// Looks up [key] in [screen] scope for [lang], falling back to shared scope,
// then English, then the key itself.
String t(String screen, String key, String lang) {
  final langMap = _strings[lang] ?? _strings['en']!;
  final enMap = _strings['en']!;
  return langMap[screen]?[key]
      ?? langMap['shared']?[key]
      ?? enMap[screen]?[key]
      ?? enMap['shared']?[key]
      ?? key;
}
