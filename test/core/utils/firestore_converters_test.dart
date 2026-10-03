import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambopoint/core/utils/firestore_converters.dart';

void main() {
  group('dateTimeFromFirestore', () {
    test('reads a Timestamp', () {
      final DateTime now = DateTime(2026, 1, 2, 3, 4, 5);
      expect(dateTimeFromFirestore(Timestamp.fromDate(now)), now);
    });

    test('reads an ISO string', () {
      expect(
        dateTimeFromFirestore('2026-01-02T03:04:05.000'),
        DateTime(2026, 1, 2, 3, 4, 5),
      );
    });

    test('returns null for unusable input', () {
      expect(dateTimeFromFirestore(null), isNull);
      expect(dateTimeFromFirestore(<String, dynamic>{}), isNull);
      expect(dateTimeFromFirestore('not a date'), isNull);
    });
  });

  group('scalar readers', () {
    test('trimmedOrNull turns blanks into null', () {
      expect(trimmedOrNull('  hello '), 'hello');
      expect(trimmedOrNull('   '), isNull);
      expect(trimmedOrNull(null), isNull);
    });

    test('doubleFrom accepts num and numeric String', () {
      expect(doubleFrom(12), 12.0);
      expect(doubleFrom(12.5), 12.5);
      expect(doubleFrom('12.5'), 12.5);
      expect(doubleFrom('abc', fallback: 7), 7);
    });

    test('intFrom accepts num and numeric String', () {
      expect(intFrom(12), 12);
      expect(intFrom(12.9), 12);
      expect(intFrom('12'), 12);
      expect(intFrom('abc'), 0);
    });

    test('boolFrom only trusts real booleans', () {
      expect(boolFrom(true), isTrue);
      expect(boolFrom('true'), isFalse);
      expect(boolFrom(null, fallback: true), isTrue);
    });

    test('stringListFrom drops blanks and non-strings', () {
      expect(
        stringListFrom(<Object?>[' a ', '', null, 'b']),
        <String>['a', 'b'],
      );
      expect(stringListFrom('nope'), isEmpty);
    });
  });

  group('uniqueKey', () {
    test('lowercases and removes whitespace', () {
      expect(uniqueKey(' TOM 001 '), 'tom001');
    });
  });
}
