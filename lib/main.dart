import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  initializeDateFormatting(
    'es_ES',
    null,
  ).then((_) => runApp(const VoluntariadoApp()));
}

class VoluntariadoApp extends StatelessWidget {
  const VoluntariadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'ES'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 17, 71, 188),
        ),
        useMaterial3: true,
      ),
      // Si la sesión ya ha sido iniciado por el usuario va a MainScreen, si no a AuthScreen
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Si snapshot.hasData es true, es que el login ha hecho su función
          if (snapshot.hasData) {
            return const MainScreen();
          }
          // Si no, mantenemos al usuario en el login
          return const AuthScreen();
        },
      ),
    );
  }
}
