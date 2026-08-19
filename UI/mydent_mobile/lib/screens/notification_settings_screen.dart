import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Device-local only — the backend has no per-user notification-preference storage, so these
// toggles control whether this device's UI surfaces each notification type (badge/highlight in
// NotificationListScreen), not whether the server generates them.
const String _keyAppointmentReminders = 'notif_appointment_reminders';
const String _keyClinicNews = 'notif_clinic_news';
const String _keyRecommendations = 'notif_recommendations';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _appointmentReminders = true;
  bool _clinicNews = true;
  bool _recommendations = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _appointmentReminders = prefs.getBool(_keyAppointmentReminders) ?? true;
      _clinicNews = prefs.getBool(_keyClinicNews) ?? true;
      _recommendations = prefs.getBool(_keyRecommendations) ?? true;
      _isLoading = false;
    });
  }

  Future<void> _set(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Postavke obavještenja")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text("Podsjetnici za termine"),
                  subtitle:
                      const Text("Podsjetnik prije zakazanog termina"),
                  value: _appointmentReminders,
                  onChanged: (v) {
                    setState(() => _appointmentReminders = v);
                    _set(_keyAppointmentReminders, v);
                  },
                ),
                SwitchListTile(
                  title: const Text("Novosti klinike"),
                  subtitle: const Text("Obavještenja o novim vijestima"),
                  value: _clinicNews,
                  onChanged: (v) {
                    setState(() => _clinicNews = v);
                    _set(_keyClinicNews, v);
                  },
                ),
                SwitchListTile(
                  title: const Text("Preporuke usluga"),
                  subtitle: const Text(
                      "Obavještenja kada je vrijeme za redovnu kontrolu"),
                  value: _recommendations,
                  onChanged: (v) {
                    setState(() => _recommendations = v);
                    _set(_keyRecommendations, v);
                  },
                ),
              ],
            ),
    );
  }
}
