import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../models/enums.dart';
import '../models/search_result.dart';
import '../providers/appointment_provider.dart';
import '../theme/app_theme.dart';
import '../utils/utils_widgets.dart';
import 'appointment_details_screen.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  SearchResult<Appointment>? result;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // AppointmentService forces non-Admin callers to their own appointments regardless of filter.
      final data = await context.read<AppointmentProvider>().get(filter: {});
      if (!mounted) return;
      setState(() {
        result = data;
        isLoading = false;
      });
    } on Exception catch (e) {
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = result?.items ?? [];
    return RefreshIndicator(
      onRefresh: _load,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(child: Text('Nemate zakazanih termina')),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final a = items[index];
                    final status = AppointmentStatusX.fromInt(a.status);
                    return Card(
                      child: ListTile(
                        title: Text(a.dentalServiceName ?? ''),
                        subtitle: Text(
                          "${a.doctorName ?? ''}\n${a.scheduledAt?.toLocal().toString().substring(0, 16) ?? ''}",
                        ),
                        isThreeLine: true,
                        trailing: StatusBadge.appointment(status),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AppointmentDetailsScreen(appointmentId: a.id!),
                            ),
                          );
                          _load();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
