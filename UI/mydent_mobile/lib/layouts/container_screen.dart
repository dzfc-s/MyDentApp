import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dental_service.dart';
import '../models/search_result.dart';
import '../providers/dental_service_provider.dart';
import '../screens/appointment_list_screen.dart';
import '../screens/book_appointment_screen.dart';
import '../screens/home_screen.dart';
import '../screens/notification_list_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/utils_widgets.dart';

class ContainerScreen extends StatefulWidget {
  const ContainerScreen({super.key});

  @override
  State<ContainerScreen> createState() => _ContainerScreenState();
}

class _ContainerScreenState extends State<ContainerScreen> {
  int _selectedIndex = 0;

  static const _titles = ["MyDent", "Moji termini", "Obavještenja", "Profil"];

  final List<Widget> _widgetOptions = const [
    HomeScreen(),
    AppointmentListScreen(),
    NotificationListScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
      ),
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Početna'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Termini'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined), label: 'Obavještenja'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () => _pickServiceToBook(context),
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _pickServiceToBook(BuildContext context) async {
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
}
