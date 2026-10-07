import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/notification_center.dart';
import 'package:flutter_application_1/data/push_notifications.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/models/app_notification.dart';
import 'package:flutter_application_1/repositories/notification_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/widgets/common/app_network_image.dart';
import 'package:flutter_application_1/widgets/common/app_shadows.dart';
import 'package:flutter_application_1/widgets/common/time_ago.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';
import 'package:flutter_application_1/widgets/notifications/notification_route.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

/// กล่องแจ้งเตือน: ใหม่สุดอยู่บน เลื่อนถึงท้ายแล้วโหลดหน้าถัดไป
/// กดรายการ = อ่านแล้ว + เปิดสูตรนั้น
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, this.repository, this.storage});

  /// ไว้ให้เทสต์ส่งของปลอม ไม่ส่ง = ใช้ตัวเดียวกับ NotificationCenter
  final NotificationRepository? repository;
  final TokenStorage? storage;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final _repository = widget.repository ?? NotificationCenter.repository;
  late final _storage = widget.storage ?? NotificationCenter.storage;
  final _scrollController = ScrollController();

  final List<AppNotification> _items = [];
  int _page = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_load(reset: true));
    // คนที่เปิดกล่องแจ้งเตือนเห็นประโยชน์แล้ว ถามสิทธิ์ push ตรงนี้ (ถามแค่ครั้งแรก)
    unawaited(PushNotifications.requestPermission());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels > position.maxScrollExtent - 300) unawaited(_load());
  }

  Future<String?> _token() async {
    final token = (await _storage.readAccessToken())?.trim();
    return token == null || token.isEmpty ? null : token;
  }

  Future<void> _load({bool reset = false}) async {
    if (_isLoading || (!reset && !_hasMore)) return;
    setState(() {
      _isLoading = true;
      if (reset) _error = null;
    });
    try {
      final token = await _token();
      if (token == null) {
        throw NotificationException(appL10n.notificationsSignInRequired);
      }
      final nextPage = reset ? 1 : _page + 1;
      final result = await _repository.fetchPage(token, page: nextPage);
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(result.items);
        _page = result.page;
        _hasMore = result.hasMore;
        _error = null;
      });
      if (reset) unawaited(NotificationCenter.refreshUnread());
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    final token = await _token();
    if (token == null || !mounted) return;
    setState(() {
      for (final (index, item) in _items.indexed) {
        _items[index] = item.markedRead();
      }
    });
    NotificationCenter.markedAllRead();
    try {
      await _repository.markAllRead(token);
    } catch (_) {
      await NotificationCenter.refreshUnread();
    }
  }

  Future<void> _open(int index) async {
    final item = _items[index];
    if (!item.isRead) {
      setState(() => _items[index] = item.markedRead());
      NotificationCenter.markedRead();
      final token = await _token();
      if (token != null) {
        unawaited(
          _repository
              .markRead(token, item.id)
              .catchError((Object _) => NotificationCenter.refreshUnread()),
        );
      }
    }
    final recipeId = item.recipeId;
    if (recipeId == null || !mounted) return;
    await Navigator.of(
      context,
    ).push(notificationRecipeRoute(recipeId, item.type));
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((item) => !item.isRead);
    return Scaffold(
      backgroundColor: ProfileColors.background,
      appBar: RecipeFormStyle.appBar(
        title: context.l10n.notificationsTitle,
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              style: TextButton.styleFrom(foregroundColor: ProfileColors.ink),
              child: Text(
                context.l10n.notificationsMarkAllRead,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: ProfileColors.ink,
        onRefresh: () => _load(reset: true),
        child: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_items.isEmpty) {
      if (_isLoading) {
        return const Center(
          child: CircularProgressIndicator(color: ProfileColors.ink),
        );
      }
      // ListView ให้ดึงลงเพื่อลองใหม่ได้แม้ไม่มีรายการ
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
        children: [
          _EmptyState(
            icon: _error == null
                ? Icons.notifications_none_rounded
                : Icons.wifi_off_rounded,
            title: _error ?? context.l10n.notificationsEmpty,
            message: _error == null
                ? context.l10n.notificationsEmptyHint
                : null,
            onRetry: _error == null ? null : () => _load(reset: true),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: ProfileColors.ink,
                ),
              ),
            ),
          );
        }
        return NotificationTile(
          notification: _items[index],
          onTap: () => _open(index),
        );
      },
    );
  }
}

/// สีและไอคอนของแต่ละประเภท
(IconData, Color) _typeStyle(AppNotification notification) =>
    switch (notification.type) {
      AppNotificationType.recipePurchased => (
        Icons.payments_rounded,
        const Color(0xFF2E9E5B),
      ),
      AppNotificationType.recipeModerated => (
        notification.status == 'rejected'
            ? Icons.block_rounded
            : Icons.visibility_off_rounded,
        const Color(0xFFD54444),
      ),
      AppNotificationType.recipeReviewed => (
        Icons.star_rounded,
        const Color(0xFFF5A300),
      ),
      AppNotificationType.recipeCommented => (
        Icons.chat_bubble_rounded,
        const Color(0xFF3B82F6),
      ),
      AppNotificationType.unknown => (
        Icons.notifications_rounded,
        ProfileColors.ink,
      ),
    };

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final (icon, color) = _typeStyle(notification);
    final excerpt = notification.excerpt;
    final radius = BorderRadius.circular(20);

    return ShadowBox(
      borderRadius: radius,
      shadows: unread ? AppShadows.card : const [],
      child: Material(
        color: unread ? Colors.white : Colors.white.withValues(alpha: 0.55),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumbnail(
                  coverUrl: notification.recipeCoverUrl,
                  icon: icon,
                  color: color,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.message(context),
                        style: TextStyle(
                          color: ProfileColors.ink,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (excerpt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '“$excerpt”',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ProfileColors.muted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        timeAgo(context.l10n, notification.createdAt),
                        style: TextStyle(
                          color: unread ? color : ProfileColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 6),
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5484D),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// รูปสูตร + ไอคอนประเภทแจ้งเตือนมุมขวาล่าง (ไม่มีรูป = ไอคอนในวงกลมสี)
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.coverUrl,
    required this.icon,
    required this.color,
  });

  final String? coverUrl;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final url = coverUrl;
    final fallback = Container(
      color: color.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 24),
    );
    return SizedBox.square(
      dimension: 54,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox.square(
              dimension: 54,
              child: url == null
                  ? fallback
                  : AppNetworkImage(
                      url,
                      width: 54,
                      height: 54,
                      errorBuilder: (_) => fallback,
                    ),
            ),
          ),
          if (url != null)
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(icon, color: Colors.white, size: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 36, color: ProfileColors.muted),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ProfileColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ProfileColors.muted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
        if (onRetry != null) ...[
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: ProfileColors.ink,
              shape: const StadiumBorder(),
            ),
            child: Text(context.l10n.retry),
          ),
        ],
      ],
    );
  }
}
