import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/notification_center.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/models/app_notification.dart';
import 'package:flutter_application_1/models/paged_result.dart';
import 'package:flutter_application_1/repositories/notification_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/views/pages/notifications_page.dart';
import 'package:flutter_application_1/views/pages/settings_page.dart';
import 'package:flutter_application_1/widgets/notifications/notification_bell.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'helpers/localized_app.dart';

Map<String, dynamic> _json({
  String id = 'n1',
  String type = 'recipe_reviewed',
  String? readAt,
  Map<String, dynamic> data = const {'rating': 5, 'excerpt': 'อร่อยมาก'},
  Map<String, dynamic>? recipe = const {
    'id': 'r1',
    'title': 'ต้มยำกุ้ง',
    'titleEn': 'Tom yum',
    'coverImageUrl': null,
  },
}) => {
  'id': id,
  'type': type,
  'data': data,
  'readAt': readAt,
  'createdAt': DateTime.now()
      .subtract(const Duration(minutes: 5))
      .toUtc()
      .toIso8601String(),
  'actor': {'id': 'u2', 'displayName': 'สมชาย', 'avatarUrl': null},
  'recipe': recipe,
};

AppNotification _notification({
  String id = 'n1',
  String type = 'recipe_reviewed',
  String? readAt,
  Map<String, dynamic> data = const {'rating': 5, 'excerpt': 'อร่อยมาก'},
  Map<String, dynamic>? recipe = const {
    'id': 'r1',
    'title': 'ต้มยำกุ้ง',
    'titleEn': 'Tom yum',
    'coverImageUrl': null,
  },
}) => AppNotification.fromJson(
  _json(id: id, type: type, readAt: readAt, data: data, recipe: recipe),
  apiBaseUrl: 'http://api',
);

/// แสดงข้อความของแจ้งเตือนตามภาษา
Future<String> _messageIn(
  WidgetTester tester,
  AppNotification notification,
  Locale locale,
) async {
  late String text;
  await tester.pumpWidget(
    localizedApp(
      locale: locale,
      home: Builder(
        builder: (context) {
          text = notification.message(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return text;
}

class _FakeRepository implements NotificationRepository {
  _FakeRepository(this.items);

  final List<AppNotification> items;
  final read = <String>[];
  var allRead = false;
  final savedSettings = <NotificationSettings>[];

  @override
  Future<PagedResult<AppNotification>> fetchPage(
    String accessToken, {
    required int page,
  }) async => PagedResult(
    items: page == 1 ? items : const [],
    page: page,
    totalPages: 1,
    total: items.length,
  );

  @override
  Future<int> fetchUnreadCount(String accessToken) async =>
      allRead ? 0 : items.where((item) => !item.isRead).length - read.length;

  @override
  Future<void> markRead(String accessToken, String id) async => read.add(id);

  @override
  Future<void> markAllRead(String accessToken) async => allRead = true;

  @override
  Future<NotificationSettings> fetchSettings(String accessToken) async =>
      const NotificationSettings();

  @override
  Future<NotificationSettings> updateSettings(
    String accessToken,
    NotificationSettings settings,
  ) async {
    savedSettings.add(settings);
    return settings;
  }

  @override
  Future<void> registerDevice(
    String accessToken, {
    required String token,
    required String platform,
    required String locale,
  }) async {}

  @override
  Future<void> unregisterDevice(String token) async {}
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      TokenStorage.accessTokenKey: 'jwt',
      TokenStorage.userIdKey: 'u1',
    });
    NotificationCenter.storage = TokenStorage();
    NotificationCenter.unreadCount.value = 0;
  });

  group('AppNotification', () {
    testWidgets('builds the message in the app language', (tester) async {
      final review = _notification();
      expect(
        await _messageIn(tester, review, AppLanguage.thai),
        'สมชาย ให้ 5 ดาวกับ "ต้มยำกุ้ง"',
      );
      expect(
        await _messageIn(tester, review, AppLanguage.english),
        'สมชาย rated "Tom yum" 5 stars',
      );
      expect(review.excerpt, 'อร่อยมาก');
      expect(review.isRead, isFalse);
    });

    testWidgets('names the team for moderation and survives deleted recipes', (
      tester,
    ) async {
      final rejected = _notification(
        type: 'recipe_moderated',
        data: const {'status': 'rejected'},
        recipe: null,
      );
      expect(
        await _messageIn(tester, rejected, AppLanguage.thai),
        'สูตร "สูตรที่ถูกลบแล้ว" ของคุณไม่ผ่านการตรวจ แก้ไขแล้วลองใหม่ได้',
      );
      expect(rejected.recipeId, isNull);
    });

    test('keeps unknown types from newer servers instead of crashing', () {
      expect(
        _notification(type: 'something_new').type,
        AppNotificationType.unknown,
      );
    });
  });

  group('HttpNotificationRepository', () {
    test('reads a page of notifications', () async {
      final repository = HttpNotificationRepository(
        baseUrl: 'http://api/',
        client: MockClient((request) async {
          expect(request.url.path, '/notifications');
          expect(request.url.queryParameters, {'page': '2', 'limit': '20'});
          expect(request.headers['Authorization'], 'Bearer jwt');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'data': [_json()],
                'total': 21,
                'page': 2,
                'limit': 20,
                'totalPages': 2,
              }),
            ),
            200,
          );
        }),
      );

      final page = await repository.fetchPage('jwt', page: 2);
      expect(page.items.single.recipeTitle, 'ต้มยำกุ้ง');
      expect(page.hasMore, isFalse);
    });

    test('registers a device and unregisters it without a session', () async {
      final requests = <http.Request>[];
      final repository = HttpNotificationRepository(
        baseUrl: 'http://api',
        client: MockClient((request) async {
          requests.add(request);
          return http.Response('', 204);
        }),
      );

      await repository.registerDevice(
        'jwt',
        token: 'fcm-token',
        platform: 'android',
        locale: 'en',
      );
      await repository.unregisterDevice('fcm-token');

      expect(requests[0].method, 'POST');
      expect(jsonDecode(requests[0].body), {
        'token': 'fcm-token',
        'platform': 'android',
        'locale': 'en',
      });
      expect(requests[1].method, 'DELETE');
      expect(requests[1].headers.containsKey('Authorization'), isFalse);
      expect(jsonDecode(requests[1].body), {'token': 'fcm-token'});
    });
  });

  group('NotificationsPage', () {
    testWidgets('marks a notification read when opened', (tester) async {
      final repository = _FakeRepository([
        _notification(id: 'n1', recipe: null),
        _notification(id: 'n2', readAt: DateTime.now().toIso8601String()),
      ]);
      NotificationCenter.unreadCount.value = 1;

      await tester.pumpWidget(
        localizedApp(
          locale: AppLanguage.thai,
          home: NotificationsPage(
            repository: repository,
            storage: TokenStorage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotificationTile), findsNWidgets(2));
      expect(find.text('“อร่อยมาก”'), findsNWidgets(2));
      expect(find.text('อ่านทั้งหมดแล้ว'), findsOneWidget);

      // n1 ไม่มีสูตรแล้ว: กดได้ อ่านแล้ว แต่ไม่เปิดหน้าไหน
      await tester.tap(find.byType(NotificationTile).first);
      await tester.pumpAndSettle();

      expect(repository.read, ['n1']);
      expect(NotificationCenter.unreadCount.value, 0);
      expect(find.text('อ่านทั้งหมดแล้ว'), findsNothing);
    });

    testWidgets('marks everything read at once', (tester) async {
      final repository = _FakeRepository([
        _notification(id: 'n1'),
        _notification(id: 'n2'),
      ]);
      NotificationCenter.unreadCount.value = 2;

      await tester.pumpWidget(
        localizedApp(
          locale: AppLanguage.thai,
          home: NotificationsPage(repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('อ่านทั้งหมดแล้ว'));
      await tester.pumpAndSettle();

      expect(repository.allRead, isTrue);
      expect(NotificationCenter.unreadCount.value, 0);
    });

    testWidgets('explains an empty inbox', (tester) async {
      await tester.pumpWidget(
        localizedApp(
          locale: AppLanguage.thai,
          home: NotificationsPage(repository: _FakeRepository(const [])),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ยังไม่มีการแจ้งเตือน'), findsOneWidget);
    });
  });

  testWidgets('the bell shows how many notifications are unread', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        locale: AppLanguage.thai,
        home: const Scaffold(body: Center(child: NotificationBellButton())),
      ),
    );
    expect(find.text('3'), findsNothing);

    NotificationCenter.unreadCount.value = 3;
    await tester.pump();
    expect(find.text('3'), findsOneWidget);

    NotificationCenter.unreadCount.value = 25;
    await tester.pump();
    expect(find.text('9+'), findsOneWidget);
  });

  testWidgets('settings saves push switches for the account', (tester) async {
    final repository = _FakeRepository(const []);
    final original = NotificationCenter.repository;
    NotificationCenter.repository = repository;
    addTearDown(() => NotificationCenter.repository = original);

    await tester.pumpWidget(
      localizedApp(locale: AppLanguage.thai, home: const SettingsPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('การแจ้งเตือนแบบพุช'), findsOneWidget);
    // Firebase ไม่ได้ตั้งค่าในเทสต์ = บอกว่าเครื่องนี้ยังรับ push ไม่ได้
    expect(
      find.text(
        'เครื่องนี้ยังรับการแจ้งเตือนแบบพุชไม่ได้ (ดูได้ในกล่องแจ้งเตือน)',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('คอมเมนต์ใหม่ในสูตรของฉัน'));
    await tester.pumpAndSettle();
    expect(repository.savedSettings.single.comments, isFalse);
    expect(repository.savedSettings.single.sales, isTrue);

    // ปิดสวิตช์หลัก = สวิตช์แยกประเภทกดไม่ได้
    await tester.tap(find.text('การแจ้งเตือนแบบพุช'));
    await tester.pumpAndSettle();
    expect(repository.savedSettings.last.pushEnabled, isFalse);
    final sales = tester.widget<SwitchListTile>(
      find.ancestor(
        of: find.text('มีคนซื้อสูตรของฉัน'),
        matching: find.byType(SwitchListTile),
      ),
    );
    expect(sales.onChanged, isNull);
  });
}
