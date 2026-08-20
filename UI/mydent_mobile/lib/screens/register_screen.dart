import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/utils_widgets.dart';

String? _required(String? v) => (v == null || v.isEmpty) ? mField : null;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registracija")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'firstName',
                      decoration: const InputDecoration(labelText: "Ime"),
                      validator: _required,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'lastName',
                      decoration: const InputDecoration(labelText: "Prezime"),
                      validator: _required,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'email',
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return mField;
                  if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(v)) {
                    return "Neispravan email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'username',
                decoration: const InputDecoration(labelText: "Korisničko ime"),
                validator: _required,
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'phoneNumber',
                decoration: const InputDecoration(labelText: "Telefon"),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'password',
                decoration: const InputDecoration(labelText: "Lozinka"),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return mField;
                  if (v.length < 6) return "Minimalno 6 karaktera";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'confirmPassword',
                decoration:
                    const InputDecoration(labelText: "Potvrdi lozinku"),
                obscureText: true,
                validator: (v) {
                  final password = _formKey.currentState?.fields['password']?.value;
                  if (v == null || v.isEmpty) return "Obavezno polje";
                  if (v != password) return "Lozinke se ne podudaraju";
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Registruj se"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final values = _formKey.currentState!.value;

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().register({
        'firstName': values['firstName'],
        'lastName': values['lastName'],
        'email': values['email'],
        'username': values['username'],
        'phoneNumber': values['phoneNumber'],
        'password': values['password'],
        'isActive': true,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registracija uspješna. Prijavite se.")),
      );
      Navigator.pop(context);
    } on Exception catch (e) {
      if (mounted) alertBox(context, "Greška", e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
