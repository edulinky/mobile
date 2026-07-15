import 'package:flutter_test/flutter_test.dart';

import 'package:edulink/app/router.dart';
import 'package:edulink/features/auth/models/app_user.dart';

void main() {
  group('roleHome', () {
    test('maps each role to its home route', () {
      expect(roleHome('student'), '/student/discover');
      expect(roleHome('teacher'), '/teacher/discover');
      expect(roleHome('institution'), '/institution/dashboard');
    });

    test('falls back to the student home for unknown/null roles', () {
      expect(roleHome(null), '/student/discover');
      expect(roleHome('someone-else'), '/student/discover');
    });
  });

  group('AppUser.hasRole', () {
    AppUser make(String? role) => AppUser(
          uid: 'u1',
          email: 'a@b.com',
          displayName: 'A',
          role: role,
          verifiedStatus: null,
        );

    test('is false when role is null or empty', () {
      expect(make(null).hasRole, isFalse);
      expect(make('').hasRole, isFalse);
    });

    test('is true when a role is present', () {
      expect(make('teacher').hasRole, isTrue);
    });
  });
}
