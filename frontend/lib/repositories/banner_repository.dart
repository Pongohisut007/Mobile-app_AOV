import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/models/banner_item.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/l10n/l10n.dart';

abstract interface class BannerRepository {
  Future<List<BannerItem>> fetchBanners();
}

class HttpBannerRepository implements BannerRepository {
  HttpBannerRepository({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration requestTimeout;

  @override
  Future<List<BannerItem>> fetchBanners() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/banners'))
        .timeout(requestTimeout);

    if (response.statusCode != 200) {
      throw Exception(appL10n.loadBannersFailed(response.statusCode));
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map((item) => BannerItem.fromJson(item, apiBaseUrl: _baseUrl))
        .where((banner) => banner.imageUrl.isNotEmpty)
        .toList(growable: false);
  }
}
