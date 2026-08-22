import 'package:MyDent_mobile/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

import 'layouts/container_screen.dart';
import 'theme/app_theme.dart';
import 'providers/appointment_provider.dart';
import 'providers/asset_provider.dart';
import 'providers/dental_service_provider.dart';
import 'providers/doctor_absence_provider.dart';
import 'providers/doctor_provider.dart';
import 'providers/doctor_specialty_provider.dart';
import 'providers/doctor_working_hours_provider.dart';
import 'providers/news_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/recommendation_provider.dart';
import 'providers/review_provider.dart';
import 'providers/service_category_provider.dart';
import 'providers/user_provider.dart';
import 'screens/register_screen.dart';
import 'widgets/tooth_icon.dart';

void main() {
  // Publishable key only (safe client-side) — pass the real one via
  // --dart-define=stripePublishableKey=pk_test_... from the same Stripe account as the
  // backend's Stripe__SecretKey. Payments will fail against Stripe until this is set.
  Stripe.publishableKey = const String.fromEnvironment(
    "stripePublishableKey",
    defaultValue: "",
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_)=> AuthProvider()),
        ChangeNotifierProvider(create: (_)=> DoctorProvider()),
        ChangeNotifierProvider(create: (_)=> DoctorSpecialtyProvider()),
        ChangeNotifierProvider(create: (_)=> DoctorWorkingHoursProvider()),
        ChangeNotifierProvider(create: (_)=> DoctorAbsenceProvider()),
        ChangeNotifierProvider(create: (_)=> ServiceCategoryProvider()),
        ChangeNotifierProvider(create: (_)=> DentalServiceProvider()),
        ChangeNotifierProvider(create: (_)=> AppointmentProvider()),
        ChangeNotifierProvider(create: (_)=> ReviewProvider()),
        ChangeNotifierProvider(create: (_)=> PaymentProvider()),
        ChangeNotifierProvider(create: (_)=> NotificationProvider()),
        ChangeNotifierProvider(create: (_)=> NewsProvider()),
        ChangeNotifierProvider(create: (_)=> RecommendationProvider()),
        ChangeNotifierProvider(create: (_)=> AssetProvider()),
        ChangeNotifierProvider(create: (_)=> UserProvider()),
      ],
      child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDent',
      theme: buildAppTheme(),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(_usernameController.text, _passwordController.text);
      if (AuthProvider.role == "Admin") {
        authProvider.logout();
        if (!mounted) return;
        alertBox(context, "Pristup odbijen",
            "Administratorski nalog se koristi putem desktop aplikacije.");
        return;
      }
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ContainerScreen()));
    } on Exception catch (e) {
      alertBox(context, "Error", e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dark purple hero + pill inputs, matching the app's own theme
    // (lib/theme/app_theme.dart, itself ported from the approved Figma
    // PatientApp.tsx palette) instead of the generic template gradient/
    // stock-photo background this screen shipped with before. The tooth
    // badge below is the app's logo, also used as the installed app icon.
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(child: ToothLogo(width: 48)),
                ),
                const SizedBox(height: 20),
                const Text('MyDent',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Dobrodošli nazad',
                    style: TextStyle(color: Colors.white60, fontSize: 14)),
                const SizedBox(height: 36),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Korisničko ime',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Lozinka',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Prijava'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text("Nemate nalog? Registrujte se"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void alertBox(BuildContext context, String title, String content) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

// (Unused `MyHomePage`/`_MyHomePageState` boilerplate from the default
// `flutter create` template — nothing referenced it — removed here.)
