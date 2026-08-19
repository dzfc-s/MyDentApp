import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../utils/utils_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  late UserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Promjena lozinke")),
      body: SingleChildScrollView(
        child: FormBuilder(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    FormBuilderTextField(
                      name: "password",
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Trenutna lozinka"),
                      validator: (v) => (v == null || v.isEmpty) ? mField : null,
                    ),
                    const SizedBox(height: 12),
                    FormBuilderTextField(
                      name: "newPassword",
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Nova lozinka"),
                      validator: (v) => (v == null || v.isEmpty) ? mField : null,
                    ),
                    const SizedBox(height: 12),
                    FormBuilderTextField(
                      name: "confirmPassword",
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Potvrdi novu lozinku"),
                      validator: (v) {
                        if (v == null || v.isEmpty) return mField;
                        if (v != _formKey.currentState?.fields['newPassword']?.value) {
                          return "Lozinke se ne podudaraju";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

                          try {
                            await _userProvider.changePassword({
                              'password': _formKey.currentState?.value['password'],
                              'newPassword': _formKey.currentState?.value['newPassword'],
                              'confirmNewPassword':
                                  _formKey.currentState?.value['confirmPassword'],
                            });

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Lozinka uspješno promijenjena")),
                            );
                            Navigator.pop(context);
                          } on Exception catch (e) {
                            if (mounted) alertBox(context, "Greška", e.toString());
                          }
                        },
                        child: const Text("Sačuvaj"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
