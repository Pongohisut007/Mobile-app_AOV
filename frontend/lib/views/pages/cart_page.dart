import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/cart/cart_bloc.dart';
import 'package:flutter_application_1/bloc/cart/cart_event.dart';
import 'package:flutter_application_1/bloc/cart/cart_state.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/cart_item.dart';
import 'package:flutter_application_1/repositories/purchase_repository.dart';
import 'package:flutter_application_1/widgets/cart/cart_empty_view.dart';
import 'package:flutter_application_1/widgets/cart/cart_item_tile.dart';
import 'package:flutter_application_1/widgets/cart/cart_summary_bar.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late final PurchaseRepository _purchaseRepository =
      HttpMockPurchaseRepository(baseUrl: ApiConfig.apiBaseUrl);
  bool _isCheckingOut = false;

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.redAccent : ProfileColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  Future<void> _checkout(List<CartItem> items) async {
    if (_isCheckingOut || items.isEmpty) return;
    if (!ApiConfig.mockIapEnabled) {
      _showMessage(
        'โหมดซื้อจำลองถูกปิดอยู่ กรุณาเชื่อม Google Play Billing',
        isError: true,
      );
      return;
    }

    final scenario = await _chooseMockScenario();
    if (scenario == null || !mounted) return;
    if (scenario == _MockPurchaseScenario.cancelled) {
      _showMessage('จำลองการยกเลิกการชำระเงินแล้ว');
      return;
    }
    if (scenario == _MockPurchaseScenario.failed) {
      _showMessage('จำลองการชำระเงินไม่สำเร็จ', isError: true);
      return;
    }

    setState(() => _isCheckingOut = true);
    var completed = 0;
    String? errorMessage;

    for (final item in items) {
      try {
        await _purchaseRepository.purchase(item);
        completed++;
      } on Exception catch (error) {
        errorMessage = error.toString();
        break;
      }
    }

    if (!mounted) return;
    context.read<CartBloc>().add(const CartRequested());
    setState(() => _isCheckingOut = false);

    if (errorMessage != null) {
      _showMessage(
        completed == 0
            ? errorMessage
            : 'ซื้อสำเร็จ $completed รายการ แล้วหยุด: $errorMessage',
        isError: true,
      );
      return;
    }
    _showMessage('ซื้อสูตรสำเร็จ $completed รายการ (โหมดทดสอบ)');
  }

  Future<_MockPurchaseScenario?> _chooseMockScenario() {
    return showModalBottomSheet<_MockPurchaseScenario>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Google Play Billing — โหมดจำลอง',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'เลือกผลลัพธ์ที่ต้องการทดสอบ ระบบนี้ไม่ตัดเงินจริง',
                style: TextStyle(color: ProfileColors.muted),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pop(sheetContext, _MockPurchaseScenario.success),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('จำลองชำระสำเร็จ'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pop(sheetContext, _MockPurchaseScenario.failed),
                icon: const Icon(Icons.error_outline_rounded),
                label: const Text('จำลองชำระไม่สำเร็จ'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(
                  sheetContext,
                  _MockPurchaseScenario.cancelled,
                ),
                child: const Text('จำลองผู้ใช้ยกเลิก'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //
  Future<void> _confirmClear(BuildContext context) async {
    final cartBloc = context.read<CartBloc>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('This removes every recipe from your cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              cartBloc.add(const CartCleared());
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(backgroundColor: ProfileColors.ink),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  //
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final items = state.items;

        return Scaffold(
          backgroundColor: ProfileColors.background,
          appBar: AppBar(
            backgroundColor: ProfileColors.background,
            foregroundColor: ProfileColors.ink,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Cart',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              if (items.isNotEmpty)
                IconButton(
                  onPressed: () => _confirmClear(context),
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Clear cart',
                ),
            ],
          ),
          body: switch (state.status) {
            // โหลดรอบแรกยังไม่รู้ว่ามีอะไรในตะกร้า อย่าเพิ่งบอกว่าว่าง
            CartStatus.initial || CartStatus.loading when items.isEmpty =>
              const Center(child: CircularProgressIndicator()),
            CartStatus.failure when items.isEmpty => _CartErrorView(
              message: state.error ?? 'Could not load your cart.',
              onRetry: () =>
                  context.read<CartBloc>().add(const CartRequested()),
            ),
            _ when items.isEmpty => CartEmptyView(
              onBrowsePressed: () => Navigator.pop(context),
            ),
            _ => ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return CartItemTile(
                  item: item,
                  onRemove: () =>
                      context.read<CartBloc>().add(CartItemRemoved(item.id)),
                );
              },
            ),
          },
          bottomNavigationBar: items.isEmpty
              ? null
              : CartSummaryBar(
                  itemCount: state.itemCount,
                  subtotal: state.subtotal,
                  isCheckingOut: _isCheckingOut,
                  onCheckoutPressed: _isCheckingOut
                      ? null
                      : () => _checkout(List<CartItem>.from(items)),
                ),
        );
      },
    );
  }
}

enum _MockPurchaseScenario { success, failed, cancelled }

// โหลดตะกร้าไม่ได้ตั้งแต่แรก ให้กดลองใหม่ได้
class _CartErrorView extends StatelessWidget {
  const _CartErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: ProfileColors.muted,
              size: 56,
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ProfileColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: ProfileColors.ink),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
