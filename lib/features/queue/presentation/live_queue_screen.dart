import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/widgets/citycare.dart';
import '../../../core/widgets/state_views.dart';
import '../data/queue_models.dart';
import '../data/queue_repository.dart';

/// Live queue for one appointment's token. Every number is read from the
/// server, polled while the screen is visible and the app is in front.
class LiveQueueScreen extends StatefulWidget {
  const LiveQueueScreen({
    super.key,
    required this.appointmentId,
    this.organizationId,
  });

  final String appointmentId;
  final String? organizationId;

  @override
  State<LiveQueueScreen> createState() => _LiveQueueScreenState();
}

class _LiveQueueScreenState extends State<LiveQueueScreen>
    with WidgetsBindingObserver {
  TokenStatus? _status;
  Object? _error;
  DateTime? _updatedAt;
  Timer? _timer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _poll();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  Future<void> _poll() async {
    _timer?.cancel();
    if (_loading) return;
    _loading = true;
    try {
      final s = await context.read<QueueRepository>().status(
        widget.appointmentId,
      );
      if (!mounted) return;
      setState(() {
        _status = s;
        _error = null;
        _updatedAt = DateTime.now();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      _loading = false;
    }
    if (mounted && !(_status?.isFinished ?? false)) {
      _timer = Timer(AppConfig.queuePollInterval, _poll);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live queue'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _poll,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: s == null
          ? _error != null
                ? CityCareErrorState(
                    message: friendlyMessage(
                      _error!,
                      fallback: "We couldn't load your queue status.",
                    ),
                    onRetry: _poll,
                  )
                : const _QueueSkeleton()
          : RefreshIndicator(
              onRefresh: _poll,
              child: ListView(
                padding: const EdgeInsets.all(CityCareSpacing.gutter),
                children: [
                  _TokenHero(status: s, live: !s.isFinished && _error == null),
                  const SizedBox(height: CityCareSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          icon: Icons.campaign_rounded,
                          label: 'Current token',
                          value: s.nowServingToken == null
                              ? '—'
                              : '#${s.nowServingToken}',
                        ),
                      ),
                      const SizedBox(width: CityCareSpacing.md),
                      Expanded(
                        child: _Stat(
                          icon: Icons.groups_rounded,
                          label: 'Patients ahead',
                          value: s.state == 'WAITING' ? '${s.ahead}' : '—',
                          highlight: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CityCareSpacing.lg),
                  if (s.advice != null) _Advice(status: s),
                  const SizedBox(height: CityCareSpacing.lg),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(CityCareSpacing.lg),
                      child: Column(
                        children: [
                          if (s.doctorName != null)
                            InfoRow(
                              icon: Icons.person_outline_rounded,
                              text: s.doctorName!,
                            ),
                          if (s.queueStartAt != null)
                            InfoRow(
                              icon: Icons.schedule_rounded,
                              text: 'Queue starts at ${s.queueStartAt}',
                            ),
                          if (s.queueDate != null)
                            InfoRow(
                              icon: Icons.event_outlined,
                              text: _prettyDate(s.queueDate!),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: CityCareSpacing.md),
                  if (widget.organizationId != null)
                    TextButton(
                      onPressed: () => context.push(
                        Routes.appointment(
                          widget.organizationId!,
                          widget.appointmentId,
                        ),
                      ),
                      child: const Text('Appointment details'),
                    ),
                  if (_updatedAt != null)
                    Center(
                      child: Text(
                        s.isFinished
                            ? 'Final status'
                            : _error != null
                            ? 'Offline — showing last update'
                            : 'Updates automatically',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _TokenHero extends StatelessWidget {
  const _TokenHero({required this.status, required this.live});

  final TokenStatus status;

  /// Still polling: show the pulsing LIVE pill.
  final bool live;

  @override
  Widget build(BuildContext context) {
    final called = status.state == 'CALLED';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
      decoration: BoxDecoration(
        gradient: called
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1F9A70), Color(0xFF14724F)],
              )
            : CityCareGradients.hero,
        borderRadius: BorderRadius.circular(CityCareRadius.xl + 4),
        boxShadow: CityCareShadows.soft,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'YOUR TOKEN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                ),
              ),
              const Spacer(),
              if (live)
                Container(
                  padding: const EdgeInsets.only(left: 2, right: 10),
                  decoration: BoxDecoration(
                    color: CityCareColors.navy.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(CityCareRadius.pill),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LiveDot(size: 8),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            label: 'Token number ${status.tokenNumber}',
            excludeSemantics: true,
            child: Text(
              '#${status.tokenNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 76,
                fontWeight: FontWeight.w800,
                height: 1.0,
                letterSpacing: -2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: called ? CityCareColors.lime : Colors.white,
              borderRadius: BorderRadius.circular(CityCareRadius.pill),
            ),
            child: Text(
              status.stateLabel.toUpperCase(),
              style: const TextStyle(
                color: CityCareColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CityCareSpacing.lg),
      decoration: BoxDecoration(
        color: highlight ? CityCareColors.navy : CityCareColors.surface,
        borderRadius: BorderRadius.circular(CityCareRadius.lg),
        border: highlight ? null : Border.all(color: CityCareColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: highlight ? CityCareColors.lime : CityCareColors.primary,
          ),
          const SizedBox(height: CityCareSpacing.md),
          Text(
            value,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -1,
              color: highlight ? Colors.white : CityCareColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: highlight ? CityCareColors.mint : CityCareColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Advice extends StatelessWidget {
  const _Advice({required this.status});

  final TokenStatus status;

  @override
  Widget build(BuildContext context) {
    final (fg, bg, icon) = switch (status.adviceTone) {
      AdviceTone.actNow => (
        CityCareColors.success,
        CityCareColors.successSoft,
        Icons.campaign_rounded,
      ),
      AdviceTone.done => (
        CityCareColors.success,
        CityCareColors.successSoft,
        Icons.check_circle_rounded,
      ),
      AdviceTone.seeReception => (
        CityCareColors.warning,
        CityCareColors.warningSoft,
        Icons.support_agent_rounded,
      ),
      AdviceTone.problem => (
        CityCareColors.danger,
        CityCareColors.dangerSoft,
        Icons.error_outline_rounded,
      ),
      AdviceTone.wait => (
        CityCareColors.accent,
        CityCareColors.accentSoft,
        Icons.hourglass_top_rounded,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(CityCareSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(CityCareRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: CityCareSpacing.md),
          Expanded(
            child: Text(
              status.advice!,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueSkeleton extends StatelessWidget {
  const _QueueSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(CityCareSpacing.gutter),
      child: Column(
        children: [
          Skeleton(height: 190, radius: 24),
          SizedBox(height: CityCareSpacing.lg),
          Row(
            children: [
              Expanded(child: Skeleton(height: 90, radius: 20)),
              SizedBox(width: CityCareSpacing.md),
              Expanded(child: Skeleton(height: 90, radius: 20)),
            ],
          ),
          SizedBox(height: CityCareSpacing.lg),
          Skeleton(height: 60, radius: 14),
        ],
      ),
    );
  }
}

/// "2026-10-07" (clinic-local day from the server) → "Wed, 7 Oct 2026".
String _prettyDate(String day) {
  final d = DateTime.tryParse(day);
  return d == null ? day : DateFormat('EEE, d MMM yyyy').format(d);
}
