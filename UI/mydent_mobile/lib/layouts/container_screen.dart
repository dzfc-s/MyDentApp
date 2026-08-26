import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';
import '../screens/appointment_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/notification_list_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/booking_helpers.dart';

/// Registered on MaterialApp.navigatorObservers — lets ContainerScreen detect
/// when a pushed route (e.g. the whole booking wizard) pops back to it, so it
/// can refresh, regardless of which bottom-nav tab happens to be showing.
/// Tab-switch-triggered refreshes (see _onItemTapped below) alone weren't
/// enough: "Nazad na početnu" after booking returns via popUntil(isFirst)
/// without necessarily changing tabs, e.g. when the FAB was tapped while
/// already on the Termini tab — nothing about that path fires a tab switch,
/// so the newly-booked appointment stayed invisible until a manual
/// pull-to-refresh.
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class ContainerScreen extends StatefulWidget {
  const ContainerScreen({super.key});

  @override
  State<ContainerScreen> createState() => _ContainerScreenState();
}

class _ContainerScreenState extends State<ContainerScreen> with RouteAware {
  int _selectedIndex = 0;
  int _homeRefreshTick = 0;
  int _appointmentsRefreshTick = 0;
  int _notificationsRefreshTick = 0;
  Timer? _unreadPollTimer;

  static const _titles = ["MyDent", "Moji termini", "Obavještenja", "Profil"];

  @override
  void initState() {
    super.initState();
    // Populates the bottom-nav badge as soon as the patient lands here after
    // login, not only after they first open the Obavještenja tab.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationProvider>().refreshUnreadCount();
    });

    // No push notifications (would need FCM setup) — poll instead, so both the bell badge and
    // the Obavještenja list itself pick up something an admin just sent without the patient
    // having to leave and re-enter that tab (manual-only refresh isn't acceptable). 20s keeps
    // this "near real-time" without hammering the API.
    _unreadPollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      context.read<NotificationProvider>().refreshUnreadCount();
      setState(() => _notificationsRefreshTick++);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _unreadPollTimer?.cancel();
    super.dispose();
  }

  // Fires when a route pushed on top of this screen (e.g. the booking
  // wizard) is popped back to it — refresh everything data-bearing rather
  // than guessing which tab needs it.
  @override
  void didPopNext() {
    setState(() {
      _homeRefreshTick++;
      _appointmentsRefreshTick++;
      _notificationsRefreshTick++;
    });
    context.read<NotificationProvider>().refreshUnreadCount();
  }

  void _onItemTapped(int index) => setState(() {
        _selectedIndex = index;
        if (index == 0) _homeRefreshTick++;
        if (index == 1) _appointmentsRefreshTick++;
        if (index == 2) _notificationsRefreshTick++;
      });

  @override
  Widget build(BuildContext context) {
    // Rebuilt (not stored as a field) so the Home tab's quick actions always close
    // over the current `context` — HomeScreen's own State object is still preserved
    // across rebuilds by IndexedStack/Flutter's element reuse, same as before.
    final widgetOptions = [
      HomeScreen(
        onBookAppointment: () => pickServiceAndBook(context),
        refreshTick: _homeRefreshTick,
      ),
      AppointmentListScreen(refreshTick: _appointmentsRefreshTick),
      NotificationListScreen(refreshTick: _notificationsRefreshTick),
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
