import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/cart/cart_bloc.dart';
import 'package:flutter_application_1/bloc/cart/cart_state.dart';
import 'package:flutter_application_1/bloc/food/food_bloc.dart';
import 'package:flutter_application_1/bloc/food/food_event.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';
import 'package:flutter_application_1/bloc/page/page_bloc.dart';
import 'package:flutter_application_1/bloc/page/page_state.dart';
import 'package:flutter_application_1/bloc/profile/profile_bloc.dart';
import 'package:flutter_application_1/bloc/profile/profile_event.dart';
import 'package:flutter_application_1/views/pages/home_page.dart';
import 'package:flutter_application_1/views/pages/community_page.dart';
import 'package:flutter_application_1/views/pages/user_page.dart';
import 'package:flutter_application_1/widgets/bottom_navbar.dart';
import 'package:flutter_application_1/widgets/common/app_snack_bar.dart';
import 'package:flutter_application_1/widgets/common/fade_indexed_stack.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class MainTreeWidget extends StatefulWidget {
  const MainTreeWidget({super.key, required this.title});

  final String title;

  @override
  State<MainTreeWidget> createState() => _MainTreeWidgetState();
}

class _MainTreeWidgetState extends State<MainTreeWidget> {
  // เก็บทุกแท็บไว้ใน RAM (IndexedStack) สลับแท็บแล้วไม่ต้องสร้างหน้า/โหลดข้อมูลใหม่
  // แท็บที่ยังไม่เคยเปิดยังไม่สร้าง จะได้ไม่ยิง API ตอนเปิดแอปเกินจำเป็น
  final Set<int> _visitedPages = {0};

  // community มี FoodBloc ของตัวเอง ไม่งั้นรายการโพสต์จะทับรายการเมนูหน้า Home
  // สร้างไว้ที่นี่ เพื่อสั่งอัปเดตเงียบ ๆ ตอนสลับกลับมาแท็บ community ได้
  final _communityFoodBloc = FoodBloc(FoodRepository());

  @override
  void dispose() {
    _communityFoodBloc.close();
    super.dispose();
  }

  Widget _buildPage(int index) => switch (index) {
    0 => const HomePage(),
    1 => BlocProvider.value(
      value: _communityFoodBloc,
      child: const CommunityPage(),
    ),
    _ => const UserPage(),
  };

  // สลับกลับมาแท็บที่เคยเปิดแล้ว: โชว์ของเดิมทันที แล้วอัปเดตรายการเงียบ ๆ
  // (เปิดครั้งแรกหน้าโหลดเองใน initState อยู่แล้ว)
  void _onPageChanged(BuildContext context, PageState state) {
    final page = state.selectedPage;
    if (!_visitedPages.contains(page)) return;
    switch (page) {
      case 0:
        context.read<FoodBloc>().add(FoodSilentRefreshRequested());
      case 1:
        _communityFoodBloc.add(FoodSilentRefreshRequested());
      default:
        // อัปเดตโปรไฟล์เงียบ ๆ โชว์ข้อมูลเดิมไว้ระหว่างโหลด ไม่ขึ้นตัวหมุนเต็มจอ
        context.read<ProfileBloc>().add(const ProfileRefreshRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    // ปุ่ม + อยู่บนการ์ดในหน้าลูก จึงฟังผลการเพิ่มของไว้ที่นี่ที่เดียว
    return MultiBlocListener(
      listeners: [
        BlocListener<CartBloc, CartState>(
          listenWhen: (previous, current) =>
              current.feedback != CartFeedback.none,
          listener: _showCartFeedback,
        ),
        BlocListener<PageBloc, PageState>(
          listenWhen: (previous, current) =>
              previous.selectedPage != current.selectedPage,
          // ทำงานก่อน builder ด้านล่าง _visitedPages จึงยังบอกได้ว่าเคยเปิดแท็บนี้หรือยัง
          listener: _onPageChanged,
        ),
      ],
      child: BlocBuilder<PageBloc, PageState>(
        builder: (context, state) {
          _visitedPages.add(state.selectedPage);
          return Scaffold(
            backgroundColor: Colors.white,
            // สลับแท็บแบบจางเข้า ทุกแท็บยังเก็บ state ไว้เหมือน IndexedStack
            body: FadeIndexedStack(
              index: state.selectedPage,
              children: [
                for (var index = 0; index < 3; index++)
                  _visitedPages.contains(index)
                      ? _buildPage(index)
                      : const SizedBox.shrink(),
              ],
            ),
            bottomNavigationBar: const BottomNavbar(),
          );
        },
      ),
    );
  }

  void _showCartFeedback(BuildContext context, CartState state) {
    final l10n = context.l10n;
    final title = state.feedbackTitle ?? l10n.cartFallbackTitle;

    final message = switch (state.feedback) {
      CartFeedback.added => l10n.cartAdded(title),
      CartFeedback.alreadyInCart => l10n.cartAlreadyIn(title),
      CartFeedback.failed => state.error ?? l10n.cartAddFailed(title),
      CartFeedback.none => null,
    };
    if (message == null) return;

    showAppSnackBar(
      context,
      message,
      type: switch (state.feedback) {
        CartFeedback.added => AppSnackType.success,
        CartFeedback.failed => AppSnackType.error,
        _ => AppSnackType.info,
      },
    );
  }
}
