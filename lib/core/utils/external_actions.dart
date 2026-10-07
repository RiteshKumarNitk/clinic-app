import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hands off to the phone's dialer, maps, mail and calendar apps.
class ExternalActions {
  ExternalActions._();

  static Future<void> call(BuildContext context, String phone) => _open(
    context,
    Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), '')),
    "Couldn't open the dialer.",
  );

  static Future<void> email(BuildContext context, String address) => _open(
    context,
    Uri(scheme: 'mailto', path: address),
    "Couldn't open email.",
  );

  static Future<void> website(BuildContext context, String url) {
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    return uri == null
        ? Future.value()
        : _open(context, uri, "Couldn't open the website.");
  }

  /// Directions to exact coordinates when known, else a maps search for the
  /// clinic's name and address.
  static Future<void> directions(
    BuildContext context, {
    required String label,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    final uri = latitude != null && longitude != null
        ? Uri.https('www.google.com', '/maps/dir/', {
            'api': '1',
            'destination': '$latitude,$longitude',
          })
        : Uri.https('www.google.com', '/maps/search/', {
            'api': '1',
            'query': [label, address].whereType<String>().join(', '),
          });
    return _open(context, uri, "Couldn't open maps.");
  }

  /// Opens a pre-filled calendar event (Google Calendar app or web).
  static Future<void> addToCalendar(
    BuildContext context, {
    required String title,
    required DateTime start,
    required DateTime end,
    String? details,
    String? location,
  }) {
    String stamp(DateTime t) =>
        '${t.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.').first}Z';
    final uri = Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': title,
      'dates': '${stamp(start)}/${stamp(end)}',
      if (details != null) 'details': details,
      if (location != null) 'location': location,
    });
    return _open(context, uri, "Couldn't open your calendar.");
  }

  static Future<void> _open(
    BuildContext context,
    Uri uri,
    String failure,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(failure)));
  }
}
