import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../data/appointment_models.dart';
import '../data/appointment_repository.dart';

/// "Who is this visit for?" — the patient, a family member they already book
/// for at this clinic, or a new family member. The server re-checks that the
/// caller may book for the chosen person.
class BookingForPicker extends StatefulWidget {
  const BookingForPicker({super.key, required this.organizationId});

  final String organizationId;

  @override
  State<BookingForPicker> createState() => BookingForPickerState();
}

class BookingForPickerState extends State<BookingForPicker> {
  static const _self = '__self__';
  static const _new = '__new__';

  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  String _relation = 'CHILD';
  String _selected = _self;
  List<FamilyMember> _members = const [];

  @override
  void initState() {
    super.initState();
    context
        .read<AppointmentRepository>()
        .family(widget.organizationId)
        .then((m) {
          if (mounted) setState(() => _members = m);
        })
        // First visit to this clinic, or offline: "Myself" / "Add" still work.
        .catchError((_) {});
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  /// Validates and returns the choice, or null if the new-member form needs
  /// fixing.
  BookingFor? read() {
    if (_selected == _self) return const BookingFor.self();
    if (_selected == _new) {
      if (!(_form.currentState?.validate() ?? false)) return null;
      return BookingFor.newMember(
        NewDependent(
          firstName: _first.text,
          lastName: _last.text,
          relation: _relation,
        ),
      );
    }
    return BookingFor.member(_selected);
  }

  Widget _chip(String value, String label, {IconData? icon}) {
    final selected = _selected == value;
    return ChoiceChip(
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 18,
              color: selected
                  ? ClinicColors.primaryDark
                  : ClinicColors.inkMuted,
            ),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      side: BorderSide(
        color: selected ? ClinicColors.primary : ClinicColors.border,
      ),
      onSelected: (_) => setState(() => _selected = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Who is this visit for?', style: theme.textTheme.titleMedium),
        const SizedBox(height: ClinicSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(_self, 'Myself', icon: Icons.person_rounded),
            for (final m in _members)
              _chip(
                m.patientId,
                m.relationLabel == null
                    ? m.name
                    : '${m.name} (${m.relationLabel})',
                icon: Icons.family_restroom_rounded,
              ),
            _chip(_new, 'Add family member', icon: Icons.person_add_alt_1),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _selected != _new
              ? const SizedBox(width: double.infinity)
              : Form(
                  key: _form,
                  child: Padding(
                    padding: const EdgeInsets.only(top: ClinicSpacing.lg),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _first,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'First name',
                                ),
                                validator: _required,
                              ),
                            ),
                            const SizedBox(width: ClinicSpacing.md),
                            Expanded(
                              child: TextFormField(
                                controller: _last,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Last name',
                                ),
                                validator: _required,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: ClinicSpacing.md),
                        DropdownButtonFormField<String>(
                          initialValue: _relation,
                          decoration: const InputDecoration(
                            labelText: 'Relation to you',
                          ),
                          items: [
                            for (final e in familyRelations.entries)
                              DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ),
                          ],
                          onChanged: (v) =>
                              setState(() => _relation = v ?? _relation),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  static String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Required' : null;
}
