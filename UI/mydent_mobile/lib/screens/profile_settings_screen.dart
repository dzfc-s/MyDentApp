import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/asset_provider.dart';
import '../providers/user_provider.dart';
import '../utils/utils_widgets.dart';
import '../widgets/image_asset_picker.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final User user;

  const ProfileSettingsScreen({super.key, required this.user});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _imagePickerKey = GlobalKey<ImageAssetPickerState>();
  Map<String, dynamic> _initialValue = {};

  late UserProvider _userProvider;
  late AssetProvider _assetProvider;

  @override
  void initState() {
    super.initState();

    _initialValue = {
      'firstName': widget.user.firstName ?? '',
      'lastName': widget.user.lastName ?? '',
      'email': widget.user.email ?? '',
      'username': widget.user.username ?? '',
      'phoneNumber': widget.user.phoneNumber ?? '',
      'isActive': widget.user.isActive ?? true,
    };

    _userProvider = context.read<UserProvider>();
    _assetProvider = context.read<AssetProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Uredi profil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildForm(),
                const SizedBox(height: 15),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

          try {
            final request = Map<String, dynamic>.from(_formKey.currentState!.value);
            request['profileImageAssetId'] =
                await _imagePickerKey.currentState?.resolveAssetId();

            await _userProvider.update(widget.user.id!, request);

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profil uspješno ažuriran")),
            );
            Navigator.pop(context, 'reload');
          } on Exception catch (e) {
            if (mounted) alertBox(context, "Greška", e.toString());
          }
        },
        child: const Text("Sačuvaj", style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildForm() {
    return FormBuilder(
      key: _formKey,
      initialValue: _initialValue,
      child: Column(
        children: [
          ImageAssetPicker(
            key: _imagePickerKey,
            initialAssetId: widget.user.profileImageAssetId,
            assetProvider: _assetProvider,
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: "firstName",
            decoration: const InputDecoration(labelText: "Ime"),
            validator: (v) => (v == null || v.isEmpty) ? mField : null,
          ),
          const SizedBox(height: 10),
          FormBuilderTextField(
            name: "lastName",
            decoration: const InputDecoration(labelText: "Prezime"),
            validator: (v) => (v == null || v.isEmpty) ? mField : null,
          ),
          const SizedBox(height: 10),
          FormBuilderTextField(
            name: "username",
            decoration: const InputDecoration(labelText: "Korisničko ime"),
            validator: (v) => (v == null || v.isEmpty) ? mField : null,
          ),
          const SizedBox(height: 10),
          FormBuilderTextField(
            name: "email",
            decoration: const InputDecoration(labelText: "Email"),
            validator: (v) {
              if (v == null || v.isEmpty) return mField;
              if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(v)) {
                return "Neispravan email";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          FormBuilderTextField(
            name: "phoneNumber",
            decoration: const InputDecoration(labelText: "Telefon"),
          ),
          const SizedBox(height: 10),
          FormBuilderCheckbox(name: 'isActive', title: const Text("Aktivan nalog")),
        ],
      ),
    );
  }
}
