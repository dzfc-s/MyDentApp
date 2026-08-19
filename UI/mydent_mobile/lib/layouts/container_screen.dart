import 'package:flutter/material.dart';

import '../screens/appointment_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/notification_list_screen.dart';
import '../screens/profile_screen.dart';

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
    );
  }
}
