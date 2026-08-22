import 'package:MyDent_desktop/providers/auth_provider.dart';
import 'package:MyDent_desktop/utils/utils_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/tooth_icon.dart';
void main() {
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDent Admin',
      theme: buildAppTheme(),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.login(_usernameController.text, _passwordController.text);
      if (AuthProvider.role != "Admin") {
        authProvider.logout();
        if (!mounted) return;
        alertBox(context, "Pristup odbijen",
            "Ovaj panel je namijenjen administratorima. Prijavite se putem mobilne aplikacije.");
        return;
      }
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
    } on Exception catch (e) {
      alertBox(context, "Error", e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin panel"),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 400, maxHeight: 400),
          child: Card(
           
            child: Padding(padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(child: ToothLogo(width: 58)),
                ),
                const SizedBox(height: 8),
                Text("MyDent",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: "Username",
                      ),
                    ),
                    SizedBox(height: 16.0,),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,

                      decoration: InputDecoration(
                        labelText: "Password",

                      ),
                    ),
                    SizedBox(height: 16.0,),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : const Text("Login"),
                    )
              ],
            ),),
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Row(children: [
          Container(
            color: Theme.of(context).colorScheme.primary,
            width: 100,
            height: 100,
            margin: const EdgeInsets.all(8.0),
          ),
          Container(
            color: Theme.of(context).colorScheme.secondary,
            width: 100,
            height: 100,
            

            child: Column(
              children: [
                Container(
                  color: Colors.green,
                  width: 50,
                  height: 50,
                 
                ),
                Container(
                  color: Colors.yellow,
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.all(8.0),
                ),
              ],
            ),
          ),
        ],),
      ),
    );
  }
}
