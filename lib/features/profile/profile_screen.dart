import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/widgets/state_views.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to continue with Google again to book or view appointments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay signed in'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ClinicColors.danger),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthController>().logout();
      // The router returns to Continue with Google on its own.
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: context.read<AuthController>().refreshProfile,
        child: ListView(
          padding: const EdgeInsets.all(ClinicSpacing.gutter),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(ClinicSpacing.xl),
                child: Column(
                  children: [
                    EntityAvatar(
                      label: user?.fullName ?? '?',
                      imageUrl: user?.avatarUrl,
                      size: 84,
                      circle: true,
                    ),
                    const SizedBox(height: ClinicSpacing.md),
                    Text(
                      user?.fullName ?? '',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (user != null) ...[
                      const SizedBox(height: 4),
                      Text(user.email, style: theme.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: ClinicSpacing.lg),
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(
                      Icons.account_circle_outlined,
                      color: ClinicColors.primary,
                    ),
                    title: Text('Signed in with Google'),
                    subtitle: Text(
                      'Your Google account is your Clinic App login.',
                    ),
                  ),
                  if (user?.phone != null) ...[
                    const Divider(indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(
                        Icons.call_outlined,
                        color: ClinicColors.primary,
                      ),
                      title: const Text('Phone'),
                      subtitle: Text(user!.phone!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: ClinicSpacing.xl),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: ClinicColors.danger,
              ),
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}
