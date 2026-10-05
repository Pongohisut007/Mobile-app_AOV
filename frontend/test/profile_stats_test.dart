import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/widgets/profile/profile_stats_row.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/localized_app.dart';

UserProfile _profile(String role, {int reviewCount = 12}) {
  return UserProfile.fromJson({
    'id': 'u1',
    'displayName': 'Cook',
    'email': 'cook@example.com',
    'avatarUrl': null,
    'role': role,
    'status': 'active',
    'recipeCount': 3,
    'purchasedCount': 1,
    'savedCount': 9,
    'draftCount': 0,
    'rating': 4.26,
    'reviewCount': reviewCount,
    'salesCount': 58,
    'officialSavedCount': 40,
    'communitySavedCount': 7,
    'commentsReceivedCount': 3,
    'reviewsWrittenCount': 5,
  }, apiBaseUrl: 'http://localhost');
}

Future<void> _pump(WidgetTester tester, UserProfile profile) {
  return tester.pumpWidget(
    localizedApp(
      home: Scaffold(body: ProfileStatsRow(profile: profile)),
    ),
  );
}

void main() {
  testWidgets('creators see sales-focused stats', (tester) async {
    await _pump(tester, _profile('creator'));

    expect(find.text('4.3'), findsOneWidget);
    expect(find.text('12 รีวิว'), findsOneWidget);
    expect(find.text('58'), findsOneWidget);
    expect(find.text('ขายได้'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    expect(find.text('บันทึกสูตร Official'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('บันทึกสูตรคอมมูนิตี้'), findsOneWidget);
  });

  testWidgets('creators without reviews see a dash, not 0.0', (tester) async {
    await _pump(tester, _profile('creator', reviewCount: 0));

    expect(find.text('–'), findsOneWidget);
    expect(find.text('ยังไม่มีรีวิว'), findsOneWidget);
    expect(find.text('4.3'), findsNothing);
  });

  testWidgets('regular users see community and activity stats', (tester) async {
    await _pump(tester, _profile('user'));

    expect(find.text('ถูกบันทึก'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('ความคิดเห็น'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('รีวิวที่เขียน'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    // ไม่มีตัวเลขฝั่งขาย/คะแนน
    expect(find.text('ขายได้'), findsNothing);
    expect(find.text('คะแนนสูตร'), findsNothing);
  });

  test('older backends without the new counts parse as zero', () {
    final profile = UserProfile.fromJson({
      'id': 'u1',
      'displayName': 'Cook',
      'email': 'cook@example.com',
      'role': 'user',
      'status': 'active',
      'recipeCount': 0,
      'purchasedCount': 0,
      'savedCount': 0,
      'draftCount': 0,
      'rating': 0,
    }, apiBaseUrl: 'http://localhost');

    expect(profile.salesCount, 0);
    expect(profile.reviewsWrittenCount, 0);
  });
}
