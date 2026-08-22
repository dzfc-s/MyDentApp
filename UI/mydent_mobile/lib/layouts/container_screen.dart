import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';
import '../screens/appointment_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/notification_list_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/booking_helpers.dart';

class ContainerScreen extends StatefulWidget {
  const ContainerScreen({super.key});

  @override
  State<ContainerScreen> createState() => _ContainerScreenState();
}

class _ContainerScreenState extends State<ContainerScreen> {
  int _selectedIndex = 0;
  int _homeRefreshTick = 0;

  static const _titles = ["MyDent", "Moji termini", "Obavještenja", "Profil"];

  @override
  void initState() {
    super.initState();
    // Populates the bottom-nav badge as soon as the patient lands here after
    // login, not only after they first open the Obavještenja tab.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationProvider>().refreshUnreadCount();
    });
  }

  void _onItemTapped(int index) => setState(() {
        _selectedIndex = index;
        if (index == 0) _homeRefreshTick++;
      });

  void _goToAppointments() => setState(() => _selectedIndex = 1);

  @override
  Widget build(BuildContext context) {
    // Rebuilt (not stored as a field) so the Home tab's quick actions always close
    // over the current `context` — HomeScreen's own State object is still preserved
    // across rebuilds by IndexedStack/Flutter's element reuse, same as before.
    final widgetOptions = [
      HomeScreen(
        onGoToAppointments: _goToAppointments,
        onBookAppointment: () => pickServiceAndBook(context),
        refreshTick: _homeRefreshTick,
      ),
      const AppointmentListScreen(),
      const NotificationListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
      ),
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: widgetOptions),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Početna'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Termini'),
          BottomNavigationBarItem(
            icon: Consumer<NotificationProvider>(
              builder: (context, provider, _) => Badge(
                label: Text('${provider.unreadCount > 9 ? '9+' : provider.unreadCount}'),
                isLabelVisible: provider.unreadCount > 0,
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
            label: 'Obavještenja',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () => pickServiceAndBook(context),
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
