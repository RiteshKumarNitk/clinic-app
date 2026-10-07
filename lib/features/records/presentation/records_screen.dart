import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../data/records_models.dart';
import '../data/records_repository.dart';

/// Every prescription the patient's doctors have issued, newest first.
class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RecordsRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('My prescriptions')),
      body: AsyncView<List<Prescription>>(
        load: repo.prescriptions,
        errorMessage: "We couldn't load your records.",
        builder: (context, list, reload) => RefreshIndicator(
          onRefresh: reload,
          child: list.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(
                      height: 480,
                      child: MessageView(
                        icon: Icons.description_outlined,
                        title: 'No prescriptions yet',
                        message:
                            'After a visit, prescriptions from your doctor '
                            'appear here.',
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(ClinicSpacing.gutter),
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: ClinicSpacing.md),
                  itemBuilder: (_, i) =>
                      PrescriptionCard(prescription: list[i]),
                ),
        ),
      ),
    );
  }
}

/// One prescription with its medicines — shared with appointment details.
class PrescriptionCard extends StatelessWidget {
  const PrescriptionCard({super.key, required this.prescription});

  final Prescription prescription;

  @override
  Widget build(BuildContext context) {
    final p = prescription;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ClinicSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ClinicColors.accentSoft,
                    borderRadius: BorderRadius.circular(ClinicRadius.sm),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: ClinicColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: ClinicSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('d MMM yyyy').format(p.issuedAt.toLocal()),
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        [
                          p.doctorName,
                          p.clinicName,
                          p.patientName,
                        ].whereType<String>().join(' · '),
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (p.items.isNotEmpty) ...[
              const SizedBox(height: ClinicSpacing.md),
              const Divider(),
              for (final item in p.items)
                Padding(
                  padding: const EdgeInsets.only(top: ClinicSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.medication_rounded,
                          size: 18,
                          color: ClinicColors.primary,
                        ),
                      ),
                      const SizedBox(width: ClinicSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: theme.textTheme.titleSmall),
                            if (item.directions.isNotEmpty)
                              Text(
                                item.directions,
                                style: theme.textTheme.bodySmall,
                              ),
                            if (item.instructions != null)
                              Text(
                                item.instructions!,
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (p.notes != null) ...[
              const SizedBox(height: ClinicSpacing.md),
              Text(p.notes!, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
