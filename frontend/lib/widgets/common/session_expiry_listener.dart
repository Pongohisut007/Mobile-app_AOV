import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/cart/cart_bloc.dart';
import 'package:flutter_application_1/bloc/cart/cart_event.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_bloc.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_event.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_bloc.dart';
import 'package:flutter_application_1/bloc/purchased_recipes/purchased_recipes_event.dart';
import 'package:flutter_application_1/data/session_expiry.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/views/pages/login_page.dart';
import 'package:flutter_application_1/widgets/common/app_snack_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// navigator/messenger ของทั้งแอป ใช้แจ้ง session หมดอายุได้จากทุกหน้า
final appNavigatorKey = GlobalKey<NavigatorState>();
final appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// session หมดอายุ (ได้ 401 จากหน้าไหนก็ได้) → ทุกหน้าจัดการแบบเดียวกัน
/// - ตะกร้า/หัวใจ/สูตรที่ซื้อ โหลดใหม่เป็นของผู้เยี่ยมชม (ไม่ค้างของบัญชีเดิม)
/// - แจ้งผู้ใช้พร้อมปุ่ม "เข้าสู่ระบบ" ไม่ต้องหาทางไปหน้าโปรไฟล์เอง
/// วางไว้ใต้ MultiBlocProvider (ต้องอ่าน bloc ที่ใช้ทั้งแอปได้)
class SessionExpiryListener extends StatefulWidget {
  const SessionExpiryListener({super.key, required this.child});

  final Widget child;

  @override
  State<SessionExpiryListener> createState() => _SessionExpiryListenerState();
}

class _SessionExpiryListenerState extends State<SessionExpiryListener> {
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = SessionExpiry.events.listen((_) => _onExpired());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onExpired() {
    if (!mounted) return;
    context.read<CartBloc>().add(const CartRequested());
    context.read<FavoriteBloc>().add(const FavoritesRequested());
    context.read<PurchasedRecipesBloc>().add(const PurchasedRecipesRequested());

    appScaffoldMessengerKey.currentState?.showAppSnackBar(
      appL10n.sessionExpired,
      type: AppSnackType.error,
      action: SnackBarAction(
        label: appL10n.signIn,
        onPressed: () => appNavigatorKey.currentState?.pushNamed(
          AppRoutes.login,
          arguments: LoginPage.returnHere,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
