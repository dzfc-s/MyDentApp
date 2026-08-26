import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/utils_widgets.dart';

/// Two steps in one screen instead of two separate routes: (1) enter email, request a code;
/// (2) enter the emailed code + new password. Kept as one screen so "request a new code" (re-run
/// step 1) doesn't require backing out and back in.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormBuilderState>();
  final _resetFormKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _codeRequested = false;
  String? _email;

  Future<void> _requestCode() async {
    if (!(_emailFormKey.currentState?.saveAndValidate() ?? false)) return;
    final email = _emailFormKey.currentState!.value['email'] as String;

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().forgotPassword(email);
      if (!mounted) return;
      setState(() {
        _email = email;
        _codeRequested = true;
      });
    } on Exception catch (e) {
      if (mounted) alertBox(context, "Greška", e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!(_resetFormKey.currentState?.saveAndValidate() ?? false)) return;
    final values = _resetFormKey.currentState!.value;

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().resetPassword(
            email: _email!,
            code: values['code'],
            newPassword: values['newPassword'],
            confirmNewPassword: values['confirmPassword'],
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lozinka uspješno promijenjena. Prijavite se.")),
      );
      Navigator.pop(context);
    } on Exception catch (e) {
      if (mounted) alertBox(context, "Greška", e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Zaboravljena lozinka")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _codeRequested ? _buildResetStep() : _buildEmailStep(),
      ),
    );
  }

  Widget _buildEmailStep() {
    return FormBuilder(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Unesite email adresu povezanu sa vašim nalogom. Poslat ćemo vam kod za resetovanje lozinke.",
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _requestCode,
            child: _isLoading
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("Pošalji kod"),
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return FormBuilder(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Poslali smo kod na $_email. Kod vrijedi 15 minuta."),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'code',
            decoration: const InputDecoration(labelText: "Kod iz emaila"),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return mField;
              if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) return "Kod ima 6 cifara";
              return null;
            },
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'newPassword',
            decoration: const InputDecoration(labelText: "Nova lozinka"),
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
            decoration: const InputDecoration(labelText: "Potvrdi novu lozinku"),
            obscureText: true,
            validator: (v) {
              final newPassword = _resetFormKey.currentState?.fields['newPassword']?.value;
              if (v == null || v.isEmpty) return mField;
              if (v != newPassword) return "Lozinke se ne podudaraju";
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            child: _isLoading
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("Resetuj lozinku"),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isLoading ? null : () => setState(() => _codeRequested = false),
            child: const Text("Nisam dobio kod / pošalji ponovo"),
          ),
        ],
      ),
    );
  }
}
