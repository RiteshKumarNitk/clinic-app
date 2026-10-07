import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/auth/google_auth_gateway.dart';
import '../../core/errors/api_exception.dart';
import '../../core/widgets/state_views.dart';
import '../auth/google_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: auth.isGuest ? const _GuestProfile() : const _SignedInProfile(),
    );
  }
}

class _SignedInProfile extends StatelessWidget {
  const _SignedInProfile();

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to continue with Google again to book or view '
          'appointments.',
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
      // The router returns to the login screen on its own.
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    return RefreshIndicator(
      onRefresh: context.read<AuthController>().refreshProfile,
      child: ListView(
        padding: const EdgeInsets.all(ClinicSpacing.gutter),
        children: [
          Container(
            padding: const EdgeInsets.all(ClinicSpacing.xl),
            decoration: BoxDecoration(
              gradient: ClinicGradients.hero,
              borderRadius: BorderRadius.circular(ClinicRadius.lg + 4),
              boxShadow: ClinicShadows.soft,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: EntityAvatar(
                    label: user?.fullName ?? '?',
                    imageUrl: user?.avatarUrl,
                    size: 64,
                    circle: true,
                  ),
                ),
                const SizedBox(width: ClinicSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (user != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ClinicSpacing.lg),
          Card(
            child: Column(
              children: [
                const _Row(
                  icon: Icons.verified_user_outlined,
                  title: 'Signed in with Google',
                  subtitle: 'Your Google account is your Clinic login.',
                ),
                if (user?.phone != null) ...[
                  const Divider(indent: 72),
                  _Row(
                    icon: Icons.call_outlined,
                    title: 'Phone',
                    subtitle: user!.phone!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: ClinicSpacing.xl),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: ClinicColors.danger,
              side: const BorderSide(
                color: ClinicColors.dangerSoft,
                width: 1.4,
              ),
            ),
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  Future<void> _signIn(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AuthController>().signInWithGoogle();
    } on GoogleSignInCancelled {
      // closed the picker
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            friendlyMessage(e, fallback: "We couldn't sign you in. Try again."),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(ClinicSpacing.gutter),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(ClinicSpacing.xl),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 38,
                  backgroundColor: ClinicColors.primarySoft,
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 38,
                    color: ClinicColors.primary,
                  ),
                ),
                const SizedBox(height: ClinicSpacing.md),
                Text('Guest', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Sign in to book appointments, get tokens and see your visits.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: ClinicSpacing.xl),
                GoogleButton(
                  filled: true,
                  busy: auth.busy,
                  onPressed: () => _signIn(context),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ClinicSpacing.lg),
        TextButton.icon(
          onPressed: auth.busy ? null : auth.exitGuest,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Back to login'),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: ClinicColors.primarySoft,
          borderRadius: BorderRadius.circular(ClinicRadius.sm),
        ),
        child: Icon(icon, color: ClinicColors.primary),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(subtitle),
    );
  }
}
