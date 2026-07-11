import 'package:flutter_test/flutter_test.dart';
import 'package:home_budget_app/services/language_service.dart';

LanguageService _makeService({String? initial}) {
  String? stored = initial;
  return LanguageService(
    read: () async => stored,
    write: (lang) async {
      stored = lang;
      return true;
    },
  );
}

void main() {
  // FR-L2: device locale mapping
  group('LanguageService.mapLocale — FR-L2', () {
    test("'ur' maps to Urdu", () {
      expect(LanguageService.mapLocale('ur'), 'ur');
    });

    test("'sd' maps to Sindhi", () {
      expect(LanguageService.mapLocale('sd'), 'sd');
    });

    test("'en' maps to English", () {
      expect(LanguageService.mapLocale('en'), 'en');
    });

    test('unknown locale maps to English', () {
      expect(LanguageService.mapLocale('zh'), 'en');
    });

    test('empty locale maps to English', () {
      expect(LanguageService.mapLocale(''), 'en');
    });
  });

  // FR-L1: save persists the language
  group('LanguageService.save — FR-L1', () {
    test('save returns true on success', () async {
      final svc = _makeService();
      expect(await svc.save('ur'), isTrue);
    });

    test('save returns false on write failure', () async {
      final svc = LanguageService(
        read: () async => null,
        write: (lang) async => false,
      );
      expect(await svc.save('ur'), isFalse);
    });

    test('saved language is returned by subsequent load', () async {
      final svc = _makeService(initial: null);
      await svc.save('ur');
      expect(await svc.load('en'), 'ur');
    });
  });

  // FR-L3: stored preference wins over device locale
  group('LanguageService.load — FR-L2 and FR-L3', () {
    test('no stored value: falls back to device locale', () async {
      final svc = _makeService(initial: null);
      expect(await svc.load('ur'), 'ur');
    });

    test('no stored value: unknown device locale defaults to English', () async {
      final svc = _makeService(initial: null);
      expect(await svc.load('fr'), 'en');
    });

    test('stored preference wins over device locale', () async {
      final svc = _makeService(initial: 'sd');
      expect(await svc.load('en'), 'sd'); // device says 'en', stored is 'sd'
    });

    test('stored preference of English wins even when device locale is Urdu', () async {
      final svc = _makeService(initial: 'en');
      expect(await svc.load('ur'), 'en');
    });

    test('invalid stored value falls back to device locale', () async {
      final svc = _makeService(initial: 'fr');
      expect(await svc.load('sd'), 'sd');
    });

    test('null stored value falls back to device locale', () async {
      final svc = _makeService(initial: null);
      expect(await svc.load('sd'), 'sd');
    });
  });
}
