import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/utils/device_location.dart';
import '../../../core/widgets/citycare.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../../doctors/data/doctor_repository.dart';
import '../../doctors/presentation/doctor_card.dart';
import '../data/clinic_models.dart';
import '../data/clinic_repository.dart';
import 'clinic_card.dart';

/// Find Healthcare: server-side search over clinics or doctors with filters
/// (near me, city, clinic type, specialty) and infinite scroll.
class FindHealthcareScreen extends StatefulWidget {
  const FindHealthcareScreen({
    super.key,
    this.initialQuery,
    this.initialDoctors = false,
  });

  final String? initialQuery;

  /// Open on the Doctors segment instead of Clinics.
  final bool initialDoctors;

  @override
  State<FindHealthcareScreen> createState() => _FindHealthcareScreenState();
}

enum _Mode { clinics, doctors }

class _FindHealthcareScreenState extends State<FindHealthcareScreen> {
  late final _search = TextEditingController(text: widget.initialQuery ?? '');
  late String _query = widget.initialQuery?.trim() ?? '';
  late _Mode _mode = widget.initialDoctors ? _Mode.doctors : _Mode.clinics;
  Timer? _debounce;

  // Filters
  String? _city;
  String? _orgType;
  String? _specialty;
  ({double lat, double lng})? _near;
  bool _locating = false;
  DiscoveryFilters? _filters;

  @override
  void initState() {
    super.initState();
    context
        .read<ClinicRepository>()
        .filters()
        .then((f) {
          if (mounted) setState(() => _filters = f);
        })
        .catchError((_) {});
  }

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

  Future<void> _toggleNearMe() async {
    if (_near != null) {
      setState(() => _near = null);
      return;
    }
    setState(() => _locating = true);
    try {
      final pos = await DeviceLocation.current();
      if (mounted) setState(() => _near = pos);
    } on LocationUnavailable catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          action: e.canOpenSettings
              ? const SnackBarAction(
                  label: 'Settings',
                  onPressed: DeviceLocation.openSettings,
                )
              : null,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("We couldn't find your location.")),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickCity() async {
    final cities = _filters?.cities ?? const <String>[];
    if (cities.isEmpty) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Choose a city',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.public_rounded),
              title: const Text('All cities'),
              onTap: () => Navigator.pop(ctx, ''),
            ),
            for (final c in cities)
              ListTile(
                leading: const Icon(Icons.location_city_rounded),
                title: Text(c),
                trailing: c == _city
                    ? const Icon(
                        Icons.check_rounded,
                        color: CityCareColors.primary,
                      )
                    : null,
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _city = picked.isEmpty ? null : picked);
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    bool busy = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CityCareChip(
        label: label,
        icon: icon,
        selected: selected,
        busy: busy,
        onTap: onTap,
      ),
    );
  }

  Widget _filterRow() {
    final children = _mode == _Mode.clinics
        ? [
            _chip(
              label: 'Near me',
              icon: Icons.near_me_rounded,
              selected: _near != null,
              busy: _locating,
              onTap: _locating ? () {} : _toggleNearMe,
            ),
            if ((_filters?.cities ?? const []).isNotEmpty)
              _chip(
                label: _city ?? 'City',
                icon: Icons.location_city_rounded,
                selected: _city != null,
                onTap: _pickCity,
              ),
            for (final e in clinicTypes.entries)
              _chip(
                label: e.value,
                selected: _orgType == e.key,
                onTap: () =>
                    setState(() => _orgType = _orgType == e.key ? null : e.key),
              ),
          ]
        : [
            for (final s in _filters?.specialties ?? const <String>[])
              _chip(
                label: s,
                selected: _specialty == s,
                onTap: () =>
                    setState(() => _specialty = _specialty == s ? null : s),
              ),
          ];
    if (children.isEmpty) return const SizedBox(height: CityCareSpacing.sm);
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: CityCareSpacing.gutter,
          vertical: 6,
        ),
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinics = context.read<ClinicRepository>();
    final doctors = context.read<DoctorRepository>();
    final filtered =
        _query.isNotEmpty ||
        (_mode == _Mode.clinics
            ? _city != null || _orgType != null
            : _specialty != null);

    return Scaffold(
      appBar: AppBar(title: const Text('Find healthcare')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CityCareSpacing.gutter,
              CityCareSpacing.xs,
              CityCareSpacing.gutter,
              CityCareSpacing.md,
            ),
            child: CityCareSearchBar(
              controller: _search,
              onChanged: _onChanged,
              onSubmitted: (v) => setState(() => _query = v.trim()),
              hint: _mode == _Mode.clinics
                  ? 'Search clinics'
                  : 'Search doctors or specialties',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CityCareSpacing.gutter,
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
          const SizedBox(height: CityCareSpacing.xs),
          _filterRow(),
          Expanded(
            child: _mode == _Mode.clinics
                ? PagedList(
                    key: ValueKey(
                      'clinics:$_query:$_city:$_orgType:${_near?.lat}:${_near?.lng}',
                    ),
                    fetch: (page) => clinics.list(
                      query: _query,
                      city: _city,
                      orgType: _orgType,
                      near: _near,
                      page: page,
                    ),
                    itemBuilder: (_, c) => ClinicCard(clinic: c),
                    errorMessage: "We couldn't load clinics.",
                    empty: CityCareEmptyState(
                      icon: Icons.local_hospital_outlined,
                      title: filtered
                          ? 'No clinics match these filters.'
                          : 'No clinics are available right now.',
                      message: filtered
                          ? 'Try a different name, city or type.'
                          : 'Please check back soon.',
                    ),
                  )
                : PagedList(
                    key: ValueKey('doctors:$_query:$_specialty'),
                    fetch: (page) => doctors.list(
                      query: _query,
                      specialty: _specialty,
                      page: page,
                    ),
                    itemBuilder: (_, d) =>
                        DoctorCard(doctor: d, showClinic: true),
                    errorMessage: "We couldn't load doctors.",
                    empty: CityCareEmptyState(
                      icon: Icons.medical_services_outlined,
                      title: filtered
                          ? 'No doctors match these filters.'
                          : 'No doctors are available right now.',
                      message: filtered
                          ? 'Try a name or another specialty.'
                          : null,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
