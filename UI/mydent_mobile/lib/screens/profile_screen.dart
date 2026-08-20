import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart' hide alertBox;
import '../models/asset.dart';
import '../models/user.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../utils/utils_widgets.dart';
import 'change_password_screen.dart';
import 'health_record_screen.dart';
import 'notification_settings_screen.dart';
import 'profile_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProvider _userProvider;

  User? user;
  Asset? _profileImage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
    _load();
  }

  Future<void> _load() async {
    try {
      final id = AuthProvider.userId;
      if (id == null) return;
      final result = await _userProvider.getById(id);

      Asset? image;
      if (result.profileImageAssetId != null) {
        try {
          image = await context
              .read<AssetProvider>()
              .getById(result.profileImageAssetId!);
        } catch (_) {
          // Missing image is fine — falls back to the placeholder icon.
        }
      }

      if (!mounted) return;
      setState(() {
        user = result;
        _profileImage = image;
        isLoading = false;
      });
    } on Exception catch (e) {
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 32),
          CircleAvatar(
            radius: 60,
            backgroundImage: _profileImage?.base64Content != null
                ? ImageFromBase64StringWithoutDimnesions(_profileImage!.base64Content!)
                : null,
            child: _profileImage?.base64Content == null
                ? const Icon(Icons.person, size: 56)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            "${user!.firstName} ${user!.lastName}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(user!.username ?? '', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 4,
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text("Uredi profil"),
                    onTap: () async {
                      final refresh = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileSettingsScreen(user: user!),
                        ),
                      );
                      if (refresh == 'reload') _load();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.medical_information_outlined),
                    title: const Text("Zdravstveni karton"),
                    onTap: () async {
                      final refresh = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HealthRecordScreen(user: user!),
                        ),
                      );
                      if (refresh == 'reload') _load();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text("Promijeni lozinku"),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text("Postavke obavještenja"),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationSettingsScreen()),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text("Odjava"),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Odjava"),
        content: const Text("Da li ste sigurni da se želite odjaviti?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Odustani")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Odjava")),
        ],
      ),
    );
    if (leave != true || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.logoutRemote();
    authProvider.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }
}
