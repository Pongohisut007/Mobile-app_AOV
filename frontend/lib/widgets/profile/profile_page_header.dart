import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/cart/cart_bloc.dart';
import 'package:flutter_application_1/bloc/cart/cart_state.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class ProfilePageHeader extends StatelessWidget {
  const ProfilePageHeader({
    super.key,
    required this.onSettingsPressed,
    required this.onCartPressed,
  });

  final VoidCallback onSettingsPressed;
  final VoidCallback onCartPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.navProfile,
                style: TextStyle(
                  color: ProfileColors.ink,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: 7),
              Text(
                context.l10n.profileHeaderSubtitle,
                style: TextStyle(
                  color: ProfileColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _CartButton(onPressed: onCartPressed),
        const SizedBox(width: 10),
        IconButton.filled(
          onPressed: onSettingsPressed,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: ProfileColors.ink,
            fixedSize: const Size(46, 46),
          ),
          icon: const Icon(Icons.tune_rounded),
          tooltip: context.l10n.settingsTitle,
        ),
      ],
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (previous, current) => previous.itemCount != current.itemCount,
      builder: (context, state) {
        final count = state.itemCount;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _button(context),
            if (count > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ProfileColors.ink,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: ProfileColors.background,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: ProfileColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _button(BuildContext context) => IconButton.filled(
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: ProfileColors.ink,
      fixedSize: const Size(46, 46),
    ),
    icon: const Icon(Icons.shopping_bag_outlined),
    tooltip: context.l10n.cartTooltip,
  );
}
