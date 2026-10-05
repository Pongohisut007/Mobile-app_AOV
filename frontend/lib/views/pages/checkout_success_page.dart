import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class CheckoutSuccessPage extends StatelessWidget {
  const CheckoutSuccessPage({
    super.key,
    required this.purchasedCount,
    required this.onViewRecipes,
    required this.onBackHome,
  });

  final int purchasedCount;
  final VoidCallback onViewRecipes;
  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.background,
      appBar: AppBar(
        backgroundColor: ProfileColors.background,
        foregroundColor: ProfileColors.ink,
        automaticallyImplyLeading: false,
        title: Text(context.l10n.paymentSuccessTitle),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: const BoxDecoration(
                    color: ProfileColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 64,
                    color: ProfileColors.ink,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  context.l10n.purchaseSuccess,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ProfileColors.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.purchaseUnlocked(purchasedCount),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ProfileColors.muted,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.mockPaymentNotice,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ProfileColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onViewRecipes,
                    icon: const Icon(Icons.menu_book_rounded),
                    label: Text(context.l10n.viewPurchasedRecipes),
                    style: FilledButton.styleFrom(
                      backgroundColor: ProfileColors.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onBackHome,
                  child: Text(context.l10n.backToHome),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
