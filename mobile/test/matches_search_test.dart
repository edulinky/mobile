import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edulink/core/money/currency.dart';
import 'package:edulink/features/matches/data/matches_repository.dart';
import 'package:edulink/features/matches/models/chat_models.dart';
import 'package:edulink/features/matches/widgets/matches_list.dart';
import 'package:edulink/features/profile/data/profile_repository.dart';
import 'package:edulink/features/profile/models/user_profile.dart';
import 'package:edulink/l10n/app_localizations.dart';

UserProfile _profile(String uid, String name) => UserProfile(
      uid: uid,
      role: 'teacher',
      email: '',
      displayName: name,
      about: '',
      photoUrl: '',
      primarySubject: '',
      subjects: const [],
      hourlyRate: null,
      currency: Currency.usd,
      geoLocation: null,
      verifiedStatus: 'approved',
      subStatus: 'free',
      avgRating: 0,
      totalReviews: 0,
      gallery: const [],
      qualifications: const [],
      experience: const [],
      availability: const {},
      videoLinks: const [],
      featured: false,
      website: '',
      contactEmail: '',
    );

final _alice = MatchThread(
  matchId: 'm1',
  otherUid: 'alice',
  lastMessage: 'See you Monday!',
  lastMessageAt: DateTime(2026, 1, 1),
  unread: 0,
  createdAt: DateTime(2026, 1, 1),
);

final _bob = MatchThread(
  matchId: 'm2',
  otherUid: 'bob',
  lastMessage: 'Can we reschedule?',
  lastMessageAt: DateTime(2026, 1, 2),
  unread: 2,
  createdAt: DateTime(2026, 1, 2),
);

/// A match with no messages yet — rendered in the "new matches" row, not the
/// conversation list.
final _carla = MatchThread(
  matchId: 'm3',
  otherUid: 'carla',
  lastMessage: '',
  lastMessageAt: null,
  unread: 0,
  createdAt: DateTime(2026, 1, 3),
);

Widget _harness() {
  return ProviderScope(
    overrides: [
      matchesProvider.overrideWith((ref) => Stream.value([_alice, _bob, _carla])),
      userProfileProvider.overrideWith((ref, uid) => Stream.value(switch (uid) {
            'alice' => _profile('alice', 'Alice Nguyen'),
            'bob' => _profile('bob', 'Bob Tran'),
            'carla' => _profile('carla', 'Carla Pham'),
            _ => _profile(uid, ''),
          })),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: MatchesList(chatRoute: '/student/chat')),
    ),
  );
}

void main() {
  testWidgets('shows every match with no query', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('Alice Nguyen'), findsOneWidget);
    expect(find.text('Bob Tran'), findsOneWidget);
    expect(find.text('Carla Pham'), findsOneWidget);
  });

  testWidgets('filters the thread list by name', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'bob');
    await tester.pumpAndSettle();

    expect(find.text('Bob Tran'), findsOneWidget);
    expect(find.text('Alice Nguyen'), findsNothing);
  });

  testWidgets('filters by last-message text too', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'reschedule');
    await tester.pumpAndSettle();

    expect(find.text('Bob Tran'), findsOneWidget);
    expect(find.text('Alice Nguyen'), findsNothing);
  });

  testWidgets('filters the new-matches row too', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'carla');
    await tester.pumpAndSettle();

    expect(find.text('Carla Pham'), findsOneWidget);
    expect(find.text('Alice Nguyen'), findsNothing);
    expect(find.text('Bob Tran'), findsNothing);
  });

  testWidgets('is case-insensitive', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ALICE');
    await tester.pumpAndSettle();

    expect(find.text('Alice Nguyen'), findsOneWidget);
  });

  testWidgets('shows a no-results state for an unmatched query', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz-nobody-zzz');
    await tester.pumpAndSettle();

    expect(find.text('Alice Nguyen'), findsNothing);
    expect(find.text('Bob Tran'), findsNothing);
    expect(find.text('Carla Pham'), findsNothing);
    expect(find.text('No matches found'), findsOneWidget);
  });

  testWidgets('clearing the query restores the full list', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'bob');
    await tester.pumpAndSettle();
    expect(find.text('Alice Nguyen'), findsNothing);

    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Alice Nguyen'), findsOneWidget);
    expect(find.text('Bob Tran'), findsOneWidget);
  });
}
