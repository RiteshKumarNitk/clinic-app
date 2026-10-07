import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// A shimmering placeholder block.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 14, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: CityCareColors.skeleton,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// A card-shaped skeleton: avatar + lines. Used by every list while loading.
class CityCareSkeletonCard extends StatelessWidget {
  const CityCareSkeletonCard({super.key, this.lines = 2, this.avatar = true});

  final int lines;
  final bool avatar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CityCareSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (avatar) ...[
              const Skeleton(width: 52, height: 52, radius: 14),
              const SizedBox(width: CityCareSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Skeleton(width: 170, height: 16),
                  for (var i = 0; i < lines; i++) ...[
                    const SizedBox(height: 10),
                    Skeleton(width: i.isEven ? 120 : 200, height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CityCareLoading extends StatelessWidget {
  const CityCareLoading({super.key, this.count = 4, this.lines = 2});

  final int count;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(CityCareSpacing.gutter),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: CityCareSpacing.md),
      itemBuilder: (_, _) => CityCareSkeletonCard(lines: lines),
    );
  }
}

/// Centered message with an icon and an optional action. Shared by error and
/// empty states so both feel like part of the product, not a crash.
class CityCareEmptyState extends StatelessWidget {
  const CityCareEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.tone = MessageTone.neutral,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final MessageTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      MessageTone.neutral => (
        CityCareColors.primarySoft,
        CityCareColors.primary,
      ),
      MessageTone.problem => (CityCareColors.dangerSoft, CityCareColors.danger),
    };
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(CityCareSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: fg, size: 34),
            ),
            const SizedBox(height: CityCareSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: CityCareSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: CityCareSpacing.xl),
              SizedBox(
                width: 220,
                child: FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum MessageTone { neutral, problem }

class CityCareErrorState extends StatelessWidget {
  const CityCareErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => CityCareEmptyState(
    icon: Icons.cloud_off_rounded,
    title: message,
    actionLabel: 'Try again',
    onAction: onRetry,
    tone: MessageTone.problem,
  );
}

/// Small coloured pill for statuses (verified, confirmed, waiting…).
class CityCareStatusBadge extends StatelessWidget {
  const CityCareStatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Network image with an initials / icon fallback — clinics and doctors often
/// have no photo yet.
class CityCareAvatar extends StatelessWidget {
  const CityCareAvatar({
    super.key,
    required this.label,
    this.imageUrl,
    this.size = 52,
    this.icon,
    this.circle = false,
  });

  final String label;
  final String? imageUrl;
  final double size;
  final IconData? icon;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final radius = circle
        ? BorderRadius.circular(size)
        : BorderRadius.circular(size * 0.27);
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CityCareColors.primarySoft,
        borderRadius: radius,
      ),
      child: icon != null
          ? Icon(icon, color: CityCareColors.primary, size: size * 0.5)
          : Text(
              _initials(label),
              style: TextStyle(
                color: CityCareColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.34,
              ),
            ),
    );
    final url = imageUrl;
    if (url == null || url.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }

  static String _initials(String text) {
    final words = text
        .replaceAll(RegExp(r'^(Dr\.?\s+)', caseSensitive: false), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && RegExp(r'[A-Za-z]').hasMatch(w[0]))
        .toList();
    if (words.isEmpty) return '+';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }
}

/// Section header used on Home and details screens.
class CityCareSectionHeader extends StatelessWidget {
  const CityCareSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CityCareSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Icon + text row used for addresses, phone numbers, timings.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: CityCareColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
