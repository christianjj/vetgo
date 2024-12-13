import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:vet_go/screens/ProfilePage.dart';
import 'package:vet_go/screens/admin_home.dart';
import 'package:vet_go/screens/clinic_admin.dart';
import 'package:vet_go/screens/clinic_details.dart';
import 'package:vet_go/screens/clinic_registration.dart';
import 'package:vet_go/screens/history.dart';
import 'package:vet_go/screens/homepage.dart';
import 'package:vet_go/screens/register.dart';
import 'package:vet_go/screens/splash.dart';
import 'package:vet_go/screens/user_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vetgo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromRGBO(184, 225, 241, 1)),
        useMaterial3: true,
      ),
      home: const Splash(),
      initialRoute: '/',
      routes: {
        // '/': (context) => const Landing(),
        '/homepage': (context) => HomePage(),
        '/register': (context) => const RegisterPage(),
        '/user_login': (context) => UserLoginPage(),
        '/admin_home': (context) => AdminHomePage(),
        '/clinics_register': (context) => ClinicRegistrationPage(),
        '/history': (context) => HistoryPage(),
        '/clinic_admin': (context) => ClinicAdminPage(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}
