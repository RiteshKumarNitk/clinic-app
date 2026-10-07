import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/auth/auth_controller.dart';
import '../data/appointment_models.dart';

/// "Who is this visit for" — prefilled from the signed-in Google account. The
/// clinic needs a name on the first booking; nothing else is required.
class PatientDetailsForm extends StatefulWidget {
  const PatientDetailsForm({super.key});

  @override
  State<PatientDetailsForm> createState() => PatientDetailsFormState();
}

class PatientDetailsFormState extends State<PatientDetailsForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().user;
    _first = TextEditingController(text: user?.firstName ?? '');
    _last = TextEditingController(text: user?.lastName ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// Validates and returns the details, or null if a field needs fixing.
  PatientDetails? read() {
    if (!(_form.currentState?.validate() ?? false)) return null;
    return PatientDetails(
      firstName: _first.text,
      lastName: _last.text,
      phone: _phone.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? v) =>
        v == null || v.trim().isEmpty ? 'Required' : null;
    return Form(
      key: _form,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _first,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: required,
                ),
              ),
              const SizedBox(width: ClinicSpacing.md),
              Expanded(
                child: TextFormField(
                  controller: _last,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: required,
                ),
              ),
            ],
          ),
          const SizedBox(height: ClinicSpacing.md),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile number (optional)',
              prefixIcon: Icon(Icons.call_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
