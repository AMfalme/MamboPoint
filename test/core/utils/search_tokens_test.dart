import 'package:flutter_test/flutter_test.dart';
import 'package:mambopoint/core/utils/search_tokens.dart';

void main() {
  group('buildNameTokens', () {
    test('produces lowercase prefixes from two characters upwards', () {
      final List<String> tokens = buildNameTokens('Tomatoes');
      expect(tokens, contains('to'));
      expect(tokens, contains('tom'));
      expect(tokens, contains('tomatoes'));
      expect(tokens, isNot(contains('t')));
    });

    test('tokenises every word and is deterministic', () {
      final List<String> tokens = buildNameTokens('Fresh Tomatoes');
      expect(tokens, contains('fre'));
      expect(tokens, contains('tom'));
      expect(tokens.first, 'fr');
      expect(tokens, equals(buildNameTokens('Fresh Tomatoes')));
    });

    test('ignores punctuation and casing', () {
      expect(
        buildNameTokens('Tomato-2kg'),
        equals(buildNameTokens('tomato 2kg')),
      );
    });

    test('caps the number of tokens', () {
      final List<String> tokens = buildNameTokens(
        'a very long product name indeed',
        maxTokens: 5,
      );
      expect(tokens.length, 5);
    });

    test('keeps single character words', () {
      expect(buildNameTokens('a'), equals(<String>['a']));
    });

    test('returns empty for blank names', () {
      expect(buildNameTokens('   '), isEmpty);
    });

    test('returns empty when maxTokens is not positive', () {
      expect(buildNameTokens('Tomatoes', maxTokens: 0), isEmpty);
    });
  });

  group('normalisation helpers', () {
    test('normalizeSku lowercases and strips whitespace', () {
      expect(normalizeSku(' TOM-001 '), 'tom-001');
      expect(normalizeSku('tom 001'), 'tom001');
    });

    test('normalizeBarcode strips whitespace', () {
      expect(normalizeBarcode(' 616110 123456 '), '616110123456');
    });

    test('normalizeName lowercases and trims', () {
      expect(normalizeName('  Fresh Tomatoes '), 'fresh tomatoes');
    });
  });
}
