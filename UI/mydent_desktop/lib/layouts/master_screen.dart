import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/auth_provider.dart';
import '../screens/appointment_list.dart';
import '../screens/dental_service_list.dart';
import '../screens/doctor_absence_list.dart';
import '../screens/doctor_list.dart';
import '../screens/doctor_specialty_list.dart';
import '../screens/doctor_working_hours_list.dart';
import '../screens/news_list.dart';
import '../screens/notification_list.dart';
import '../screens/payment_list.dart';
import '../screens/review_list.dart';
import '../screens/service_category_list.dart';
import '../screens/user_list.dart';
import '../theme/app_theme.dart';

enum AppSection {
  serviceCategories,
  dentalServices,
  doctors,
  doctorSpecialties,
  doctorWorkingHours,
  doctorAbsences,
  appointments,
  reviews,
  payments,
  notifications,
  news,
  users,
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});
  final String title;

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
          Text(title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          const Icon(Icons.notifications_none, color: Colors.black54),
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
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 18,
                  child: const Icon(Icons.medical_services_outlined,
                      color: Colors.white, size: 18),
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
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              children: [
                _tile(context, Icons.calendar_month, 'Rezervacije',
                    AppSection.appointments, () => const AppointmentList()),
                _tile(context, Icons.category_outlined, 'Kategorije usluga',
                    AppSection.serviceCategories, () => const ServiceCategoryList()),
                _tile(context, Icons.medical_services_outlined, 'Usluge',
                    AppSection.dentalServices, () => const DentalServiceList()),
                _tile(context, Icons.people_alt_outlined, 'Doktori',
                    AppSection.doctors, () => const DoctorList()),
                _tile(context, Icons.workspace_premium_outlined, 'Specijalnosti',
                    AppSection.doctorSpecialties, () => const DoctorSpecialtyList()),
                _tile(context, Icons.schedule, 'Radno vrijeme',
                    AppSection.doctorWorkingHours, () => const DoctorWorkingHoursList()),
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
                _tile(context, Icons.people, 'Korisnici',
                    AppSection.users, () => const UserList()),
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
