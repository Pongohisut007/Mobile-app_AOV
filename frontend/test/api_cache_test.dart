import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/banner/banner_bloc.dart';
import 'package:flutter_application_1/bloc/banner/banner_event.dart';
import 'package:flutter_application_1/bloc/banner/banner_state.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';
import 'package:flutter_application_1/bloc/food/food_state.dart';
import 'package:flutter_application_1/data/api_cache.dart';
import 'package:flutter_application_1/models/banner_item.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/models/paged_result.dart';
import 'package:flutter_application_1/repositories/banner_repository.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/widgets/common/app_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

Food _food(String id) => Food(
  idfoods: id,
  name: 'Recipe $id',
  category: '',
  description: '',
  filePathImage: '',
);

PagedResult<Food> _page(List<String> ids, {int totalPages = 2}) => PagedResult(
  items: ids.map(_food).toList(),
  page: 1,
  totalPages: totalPages,
  total: ids.length,
);

class _FakeFoodRepository extends FoodRepository {
  _FakeFoodRepository({this.cached, this.fresh, this.error});

  final PagedResult<Food>? cached;
  final PagedResult<Food>? fresh;
  final Object? error;

  @override
  Future<PagedResult<Food>?> cachedRecipesPage({
    String? type,
    String? status,
    String? categoryId,
    String? sort,
  }) async => cached;

  @override
  Future<PagedResult<Food>> fetchRecipesPage({
    String? type,
    String? status,
    String? categoryId,
    String? sort,
    int page = 1,
  }) async {
    if (error case final error?) throw error;
    return fresh!;
  }
}

class _FakeBannerRepository implements BannerRepository {
  _FakeBannerRepository({this.cached, this.fail = false});

  final List<BannerItem>? cached;
  final bool fail;

  @override
  Future<List<BannerItem>?> cachedBanners() async => cached;

  @override
  Future<List<BannerItem>> fetchBanners() async {
    if (fail) throw Exception('offline');
    return const [BannerItem(id: 'new', imageUrl: 'https://x/new.png')];
  }
}

Future<List<S>> _states<S>(
  Stream<S> stream,
  void Function() start,
  Future<void> Function() close,
) async {
  final states = <S>[];
  final subscription = stream.listen(states.add);
  start();
  await Future<void>.delayed(const Duration(milliseconds: 20));
  await close();
  await subscription.cancel();
  return states;
}

void main() {
  group('ApiCache', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('api_cache_test');
    });
    tearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    test('keeps responses in memory and on disk across app restarts', () async {
      final first = ApiCache(directory: () async => directory);
      await first.write('banners', '[1]');
      expect(first.peek('banners'), '[1]');

      // เปิดแอปใหม่ = RAM ว่าง แต่ยังอ่านจาก disk ได้
      final restarted = ApiCache(directory: () async => directory);
      expect(restarted.peek('banners'), isNull);
      expect(await restarted.read('banners'), '[1]');
      expect(restarted.peek('banners'), '[1]');
      expect(await restarted.read('missing'), isNull);
    });

    test(
      'forgets only the signed-in user data when switching account',
      () async {
        final cache = ApiCache(directory: () async => directory);
        await cache.write('${ApiCache.userPrefix}profile', '{"id":"u1"}');
        await cache.write('banners', '[1]');

        await cache.clearUser();

        final restarted = ApiCache(directory: () async => directory);
        expect(await restarted.read('${ApiCache.userPrefix}profile'), isNull);
        expect(await restarted.read('banners'), '[1]');

        await restarted.remove('banners');
        expect(
          await ApiCache(directory: () async => directory).read('banners'),
          isNull,
        );
      },
    );

    test('drops the oldest files beyond the disk limit', () async {
      final cache = ApiCache(
        directory: () async => directory,
        maxDiskEntries: 5,
      );
      for (var i = 0; i < 20; i++) {
        await cache.write('key-$i', '$i');
      }
      expect(directory.listSync().length, 5);
    });

    test('works in memory only when there is no disk', () async {
      final cache = ApiCache(directory: () async => null);
      await cache.write('a', '1');
      expect(await cache.read('a'), '1');
      await cache.clear();
      expect(await cache.read('a'), isNull);
    });
  });

  group('FoodBloc shows the saved list first', () {
    test('then replaces it with the fresh one', () async {
      final bloc = FoodBloc(
        _FakeFoodRepository(cached: _page(['old']), fresh: _page(['new'])),
      );
      final states = await _states(
        bloc.stream,
        () => bloc.add(FetchFoodByCategoryEvent('')),
        bloc.close,
      );

      expect(states.whereType<FoodLoading>(), isEmpty);
      final loaded = states.whereType<FoodLoaded>().toList();
      expect(loaded.first.foods.single.idfoods, 'old');
      // ระหว่างโชว์ของเก่ายังไม่ให้เลื่อนโหลดหน้าถัดไป
      expect(loaded.first.hasMore, isFalse);
      expect(loaded.last.foods.single.idfoods, 'new');
      expect(loaded.last.hasMore, isTrue);
    });

    test('and keeps it when offline', () async {
      final bloc = FoodBloc(
        _FakeFoodRepository(
          cached: _page(['old']),
          error: Exception('offline'),
        ),
      );
      final states = await _states(
        bloc.stream,
        () => bloc.add(FetchFoodByCategoryEvent('')),
        bloc.close,
      );

      expect(states.whereType<FoodError>(), isEmpty);
      expect((states.last as FoodLoaded).foods.single.idfoods, 'old');
    });

    test('shows a spinner and the error when nothing was saved', () async {
      final bloc = FoodBloc(_FakeFoodRepository(error: Exception('offline')));
      final states = await _states(
        bloc.stream,
        () => bloc.add(FetchFoodByCategoryEvent('')),
        bloc.close,
      );

      expect(states.first, isA<FoodLoading>());
      expect(states.last, isA<FoodError>());
    });
  });

  test('BannerBloc shows saved banners and keeps them when offline', () async {
    const saved = [BannerItem(id: 'old', imageUrl: 'https://x/old.png')];
    final online = BannerBloc(_FakeBannerRepository(cached: saved));
    final fresh = await _states(
      online.stream,
      () => online.add(FetchBannersEvent()),
      online.close,
    );
    expect((fresh.first as BannerLoaded).banners.single.id, 'old');
    expect((fresh.last as BannerLoaded).banners.single.id, 'new');

    final offline = BannerBloc(
      _FakeBannerRepository(cached: saved, fail: true),
    );
    final kept = await _states(
      offline.stream,
      () => offline.add(FetchBannersEvent()),
      offline.close,
    );
    expect(kept.whereType<BannerError>(), isEmpty);
    expect((kept.last as BannerLoaded).banners.single.id, 'old');
  });

  test('image cache keys ignore the rotating media signature', () {
    expect(
      imageCacheKey('http://api/uploads/images/a.png?exp=1&sig=abc'),
      'http://api/uploads/images/a.png',
    );
    expect(
      imageCacheKey('http://api/uploads/images/a.png?exp=2&sig=xyz'),
      imageCacheKey('http://api/uploads/images/a.png?exp=1&sig=abc'),
    );
    expect(
      imageCacheKey('https://cdn.example/x.png?w=200'),
      'https://cdn.example/x.png?w=200',
    );
  });

  test('the signed-in user id follows the saved session', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final storage = TokenStorage();

    await storage.saveSession(accessToken: 'jwt', userId: 'u1');
    expect(TokenStorage.currentUserId.value, 'u1');

    TokenStorage.currentUserId.value = null;
    await TokenStorage.loadCurrentUser(storage: storage);
    expect(TokenStorage.currentUserId.value, 'u1');

    await storage.clearSession();
    expect(TokenStorage.currentUserId.value, isNull);
  });

  testWidgets('AppNetworkImage still renders a placeholder for empty URLs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppNetworkImage('', width: 10, height: 10)),
    );
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
  });
}
