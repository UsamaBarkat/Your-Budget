import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const _key = 'language';
  static const _valid = {'en', 'ur', 'sd'};

  final Future<String?> Function() _read;
  final Future<bool> Function(String) _write;

  LanguageService({
    required Future<String?> Function() read,
    required Future<bool> Function(String) write,
  })  : _read = read,
        _write = write;

  static Future<LanguageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LanguageService(
      read: () async => prefs.getString(_key),
      write: (lang) async => prefs.setString(_key, lang),
    );
  }

  /// Returns the stored language if present and valid; otherwise maps [deviceLocale].
  Future<String> load(String deviceLocale) async {
    final stored = await _read();
    if (stored != null && _valid.contains(stored)) return stored;
    return mapLocale(deviceLocale);
  }

  Future<bool> save(String lang) => _write(lang);

  /// Maps a device locale language code to a supported app language.
  static String mapLocale(String languageCode) {
    if (languageCode == 'ur') return 'ur';
    if (languageCode == 'sd') return 'sd';
    return 'en';
  }
}
