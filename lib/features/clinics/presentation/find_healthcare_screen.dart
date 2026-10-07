import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../../doctors/data/doctor_repository.dart';
import '../../doctors/presentation/doctor_card.dart';
import '../data/clinic_repository.dart';
import 'clinic_card.dart';

/// Find Healthcare: server-side search over clinics or doctors, with
/// infinite scroll.
class FindHealthcareScreen extends StatefulWidget {
  const FindHealthcareScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<FindHealthcareScreen> createState() => _FindHealthcareScreenState();
}

enum _Mode { clinics, doctors }

class _FindHealthcareScreenState extends State<FindHealthcareScreen> {
  late final _search = TextEditingController(text: widget.initialQuery ?? '');
  late String _query = widget.initialQuery?.trim() ?? '';
  _Mode _mode = _Mode.clinics;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (value.trim() != _query) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final clinics = context.read<ClinicRepository>();
    final doctors = context.read<DoctorRepository>();
    final searching = _query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Find healthcare')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ClinicSpacing.gutter,
              ClinicSpacing.xs,
              ClinicSpacing.gutter,
              ClinicSpacing.md,
            ),
            child: TextField(
              controller: _search,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: _mode == _Mode.clinics
                    ? 'Search clinics'
                    : 'Search doctors or specialties',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClinicSpacing.gutter,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_Mode>(
                segments: const [
                  ButtonSegment(
                    value: _Mode.clinics,
                    label: Text('Clinics'),
                    icon: Icon(Icons.local_hospital_outlined),
                  ),
                  ButtonSegment(
                    value: _Mode.doctors,
                    label: Text('Doctors'),
                    icon: Icon(Icons.medical_services_outlined),
                  ),
                ],
                selected: {_mode},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
            ),
          ),
          const SizedBox(height: ClinicSpacing.sm),
          Expanded(
            child: _mode == _Mode.clinics
                ? PagedList(
                    key: ValueKey('clinics:$_query'),
                    fetch: (page) => clinics.list(query: _query, page: page),
                    itemBuilder: (_, c) => ClinicCard(clinic: c),
                    errorMessage: "We couldn't load clinics.",
                    empty: MessageView(
                      icon: Icons.local_hospital_outlined,
                      title: searching
                          ? 'No clinics match "$_query".'
                          : 'No clinics are available right now.',
                      message: searching
                          ? 'Try a different name or search doctors instead.'
                          : 'Please check back soon.',
                    ),
                  )
                : PagedList(
                    key: ValueKey('doctors:$_query'),
                    fetch: (page) => doctors.list(query: _query, page: page),
                    itemBuilder: (_, d) =>
                        DoctorCard(doctor: d, showClinic: true),
                    errorMessage: "We couldn't load doctors.",
                    empty: MessageView(
                      icon: Icons.medical_services_outlined,
                      title: searching
                          ? 'No doctors match "$_query".'
                          : 'No doctors are available right now.',
                      message: searching
                          ? 'Try a name or a specialty like "General Medicine".'
                          : null,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
