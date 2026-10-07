import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/api_exception.dart';
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
                ? ErrorView(
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
                padding: const EdgeInsets.all(ClinicSpacing.gutter),
                children: [
                  _TokenHero(status: s),
                  const SizedBox(height: ClinicSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: 'Now serving',
                          value: s.nowServingToken == null
                              ? '—'
                              : '#${s.nowServingToken}',
                        ),
                      ),
                      const SizedBox(width: ClinicSpacing.md),
                      Expanded(
                        child: _Stat(
                          label: 'People ahead',
                          value: s.state == 'WAITING' ? '${s.ahead}' : '—',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ClinicSpacing.lg),
                  if (s.advice != null) _Advice(status: s),
                  const SizedBox(height: ClinicSpacing.lg),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(ClinicSpacing.lg),
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
                              text: s.queueDate!,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: ClinicSpacing.md),
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
  const _TokenHero({required this.status});

  final TokenStatus status;

  @override
  Widget build(BuildContext context) {
    final called = status.state == 'CALLED';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: called
              ? const [Color(0xFF15803D), Color(0xFF0F5F2E)]
              : const [ClinicColors.primary, ClinicColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(ClinicRadius.lg + 4),
      ),
      child: Column(
        children: [
          const Text(
            'YOUR TOKEN',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Semantics(
            label: 'Token number ${status.tokenNumber}',
            child: Text(
              '#${status.tokenNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status.stateLabel.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
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
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: ClinicColors.ink),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
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
        ClinicColors.success,
        ClinicColors.successSoft,
        Icons.campaign_rounded,
      ),
      AdviceTone.done => (
        ClinicColors.success,
        ClinicColors.successSoft,
        Icons.check_circle_rounded,
      ),
      AdviceTone.seeReception => (
        ClinicColors.warning,
        ClinicColors.warningSoft,
        Icons.support_agent_rounded,
      ),
      AdviceTone.problem => (
        ClinicColors.danger,
        ClinicColors.dangerSoft,
        Icons.error_outline_rounded,
      ),
      AdviceTone.wait => (
        ClinicColors.accent,
        ClinicColors.accentSoft,
        Icons.hourglass_top_rounded,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(ClinicSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ClinicRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: ClinicSpacing.md),
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
      padding: EdgeInsets.all(ClinicSpacing.gutter),
      child: Column(
        children: [
          Skeleton(height: 190, radius: 24),
          SizedBox(height: ClinicSpacing.lg),
          Row(
            children: [
              Expanded(child: Skeleton(height: 90, radius: 20)),
              SizedBox(width: ClinicSpacing.md),
              Expanded(child: Skeleton(height: 90, radius: 20)),
            ],
          ),
          SizedBox(height: ClinicSpacing.lg),
          Skeleton(height: 60, radius: 14),
        ],
      ),
    );
  }
}
