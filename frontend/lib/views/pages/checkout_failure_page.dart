import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class CheckoutFailurePage extends StatelessWidget {
  const CheckoutFailurePage({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onBackToCart,
    this.purchasedCount = 0,
  });

  final String message;
  final int purchasedCount;
  final VoidCallback onRetry;
  final VoidCallback onBackToCart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.background,
      appBar: AppBar(
        backgroundColor: ProfileColors.background,
        foregroundColor: ProfileColors.ink,
        automaticallyImplyLeading: false,
        title: Text(context.l10n.paymentFailedTitle),
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
                    color: Color(0xFFFFE9E3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 60,
                    color: Color(0xFFB34034),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  context.l10n.purchaseIncomplete,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ProfileColors.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ProfileColors.muted,
                    fontSize: 16,
                  ),
                ),
                if (purchasedCount > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.purchasePartialMessage(purchasedCount),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ProfileColors.ink,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.l10n.retry),
                    style: FilledButton.styleFrom(
                      backgroundColor: ProfileColors.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onBackToCart,
                  child: Text(context.l10n.backToCart),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
