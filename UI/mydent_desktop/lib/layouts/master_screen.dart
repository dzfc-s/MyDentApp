import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/auth_provider.dart';
import '../screens/appointment_list.dart';
import '../screens/category_service_list.dart';
import '../screens/dashboard_screen.dart';
import '../screens/doctor_absence_list.dart';
import '../screens/doctor_list.dart';
import '../screens/news_list.dart';
import '../screens/notification_list.dart';
import '../screens/patient_list.dart';
import '../screens/payment_list.dart';
import '../screens/review_list.dart';
import '../models/enums.dart';
import '../providers/appointment_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/tooth_icon.dart';

enum AppSection {
  dashboard,
  dentalServices,
  doctors,
  doctorAbsences,
  appointments,
  reviews,
  payments,
  notifications,
  news,
  patients,
}

/// Persistent left sidebar (not a hide-until-tapped Drawer) — every admin screen stays reachable
/// in one click, matching the approved MyDent desktop design.
class MasterScreen extends StatelessWidget {
  const MasterScreen({
    super.key,
    required this.child,
    required this.title,
    this.currentSection,
  });

  final Widget child;
  final String title;
  final AppSection? currentSection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(currentSection: currentSection),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: title),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatefulWidget {
  const _TopBar({required this.title});
  final String title;

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    // Fires on every MasterScreen (every admin screen wraps its content in
    // one), so the badge is always fresh on every navigation without a
    // shared reactive store — appointment status changes almost always
    // happen via a full screen navigation anyway (confirm/cancel/reschedule
    // all call initTable() on their own screen, not this one).
    _refreshPendingCount();
  }

  Future<void> _refreshPendingCount() async {
    try {
      final result = await context.read<AppointmentProvider>().get(filter: {
        "status": AppointmentStatus.pending.index,
        "includeTotalCount": true,
        "pageSize": 1,
      });
      if (!mounted) return;
      setState(() => _pendingCount = result.totalCount ?? 0);
    } catch (_) {
      // Badge staying at its last value beats crashing the whole top bar.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEDE9F5))),
      ),
      child: Row(
        children: [
          Text(widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          Tooltip(
            message: 'Termini na čekanju',
            child: Material(
              color: _pendingCount > 0 ? AppColors.danger : const Color(0xFFF6F4FB),
              borderRadius: BorderRadius.circular(999),
              elevation: _pendingCount > 0 ? 2 : 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppointmentList(
                          initialStatus: AppointmentStatus.pending),
                    ),
                  );
                  _refreshPendingCount();
                },
                // A plain icon (even with a small dot badge) reads as decoration
                // easy to skim past — when there's actually something to act on,
                // this becomes a solid, labeled pill instead, so it can't be
                // mistaken for a passive status indicator.
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: _pendingCount > 0 ? 16 : 10, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _pendingCount > 0
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                        size: 26,
                        color: _pendingCount > 0 ? Colors.white : Colors.black54,
                      ),
                      if (_pendingCount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          "${_pendingCount > 99 ? '99+' : _pendingCount} na čekanju",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.currentSection});
  final AppSection? currentSection;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppColors.primaryDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 18,
                  child: ToothLogo(width: 15),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MyDent',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text('Administracija',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.white38),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ClinicInfo.name,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      Text(ClinicInfo.address,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              children: [
                _tile(context, Icons.space_dashboard_outlined, 'Početna',
                    AppSection.dashboard, () => const DashboardScreen()),
                _tile(context, Icons.calendar_month, 'Rezervacije',
                    AppSection.appointments, () => const AppointmentList()),
                _tile(context, Icons.medical_services_outlined, 'Usluge',
                    AppSection.dentalServices, () => const CategoryServiceList()),
                _tile(context, Icons.people_alt_outlined, 'Doktori',
                    AppSection.doctors, () => const DoctorList()),
                _tile(context, Icons.medical_information_outlined, 'Pacijenti',
                    AppSection.patients, () => const PatientList()),
                _tile(context, Icons.event_busy, 'Odsustva',
                    AppSection.doctorAbsences, () => const DoctorAbsenceList()),
                _tile(context, Icons.reviews_outlined, 'Recenzije',
                    AppSection.reviews, () => const ReviewList()),
                _tile(context, Icons.payments_outlined, 'Plaćanja',
                    AppSection.payments, () => const PaymentList()),
                _tile(context, Icons.notifications_outlined, 'Obavještenja',
                    AppSection.notifications, () => const NotificationList()),
                _tile(context, Icons.article_outlined, 'Novosti',
                    AppSection.news, () => const NewsList()),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          _UserFooter(),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label,
      AppSection section, Widget Function() builder) {
    final active = currentSection == section;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: active
              ? null
              : () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => builder())),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 19, color: active ? Colors.white : Colors.white60),
                const SizedBox(width: 12),
                Text(label,
                    style: TextStyle(
                        color: active ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firstName = AuthProvider.accessTokenDecoded?['FirstName'] as String?;
    final lastName = AuthProvider.accessTokenDecoded?['LastName'] as String?;
    final role = AuthProvider.accessTokenDecoded?['Role'] as String?;
    final fullName = [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
    final initials = [firstName, lastName]
        .where((s) => s != null && s.isNotEmpty)
        .map((s) => s![0].toUpperCase())
        .join();

    return InkWell(
      onTap: () => _showLogoutDialog(context),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 18,
              child: Text(initials.isEmpty ? '?' : initials,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullName.isEmpty ? 'Korisnik' : fullName,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                  Text(role ?? '',
                      style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.logout, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Odjava"),
        content: const Text("Da li ste sigurni da se želite odjaviti?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Odustani"),
          ),
          TextButton(
            onPressed: () async {
              try {
                AuthProvider authProvider = context.read<AuthProvider>();
                await authProvider.logoutRemote();
                authProvider.logout();

                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text("Da"),
          ),
        ],
      ),
    );
  }
}
