import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dental_service.dart';
import '../models/search_result.dart';
import '../providers/dental_service_provider.dart';
import '../screens/book_appointment_screen.dart';
import '../widgets/booking_steps.dart';
import 'utils_widgets.dart';

/// Shows the "pick a service to book" sheet and, once one is chosen, pushes
/// `BookAppointmentScreen` for it. Originally lived only inside
/// `ContainerScreen` (used by its FAB and Home's quick action); factored out
/// so `AppointmentDetailsScreen`'s "Zakaži ponovo" (rebook after cancellation)
/// can trigger the exact same flow without duplicating it.
Future<void> pickServiceAndBook(BuildContext context) async {
  final provider = context.read<DentalServiceProvider>();
  SearchResult<DentalService>? result;
  try {
    result = await provider.get(filter: {"isActive": true});
  } on Exception catch (e) {
    if (context.mounted) alertBox(context, 'Greška', e.toString());
    return;
  }
  if (!context.mounted) return;

  final services = result.items ?? [];
  final selected = await showModalBottomSheet<DentalService>(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BookingSteps(step: 1),
            Text("Odaberite uslugu",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(
              child: services.isEmpty
                  ? const Center(child: Text("Nema dostupnih usluga"))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final s = services[index];
                        return ListTile(
                          title: Text(s.name ?? ''),
                          subtitle: Text(s.serviceCategoryName ?? ''),
                          trailing: Text("${s.price} KM"),
                          onTap: () => Navigator.pop(context, s),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );

  if (selected != null && context.mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookAppointmentScreen(service: selected),
      ),
    );
  }
}
