import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/profile/profile_widgets.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$feature is coming soon'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ProfileColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You can sign back in at any time to access your recipes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showComingSoon(context, 'Sign out');
            },
            style: FilledButton.styleFrom(backgroundColor: ProfileColors.ink),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              sliver: SliverList.list(
                children: [
                  ProfilePageHeader(
                    onSettingsPressed: () =>
                        _showComingSoon(context, 'Settings'),
                  ),
                  const SizedBox(height: 22),
                  ProfileCard(
                    onEditPressed: () =>
                        _showComingSoon(context, 'Edit profile'),
                  ),
                  const SizedBox(height: 16),
                  const ProfileStatsRow(),
                  const SizedBox(height: 30),
                  const ProfileSectionTitle(
                    title: 'Your kitchen',
                    subtitle: 'Everything you cook and collect',
                  ),
                  const SizedBox(height: 14),
                  ProfileQuickActions(
                    onPressed: (label) => _showComingSoon(context, label),
                  ),
                  const SizedBox(height: 30),
                  const ProfileSectionTitle(
                    title: 'Account',
                    subtitle: 'Manage your preferences',
                  ),
                  const SizedBox(height: 14),
                  ProfileAccountMenu(
                    onPressed: (label) => _showComingSoon(context, label),
                    onSignOut: () => _confirmSignOut(context),
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'Recipy · Version 1.0.0',
                      style: TextStyle(
                        color: ProfileColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
