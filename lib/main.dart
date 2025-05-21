import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'providers/theme_provider.dart';
import 'pages/login/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/timer_manager.dart';

/// Az alkalmazás belépési pontja.
/// Itt történik a szükséges inicializálás, mint a környezeti változók betöltése,
/// értesítések inicializálása és az orientáció beállítása.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // TimerManager inicializálása (értesítések)
  TimerManager().initializeNotifications();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

/// A fő alkalmazás widget.
/// Itt történik meg a témák kezelése, valamint a kezdőképernyő betöltése.
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  /// Globális Navigator kulcs a SnackBar-ok vagy navigációk kezeléséhez.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // A TimerManager is megkapja a világos/sötét téma beállítást
    TimerManager().setIsDark(themeProvider.isDarkMode);

    return MaterialApp(
      title: 'FitWithUs',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Globális navigációs kulcs beállítása
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      /// Világos téma konfiguráció
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Roboto',
            letterSpacing: 1.2,
          ),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),

      /// Sötét téma konfiguráció
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Roboto',
            letterSpacing: 1.2,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
          titleMedium: TextStyle(color: Colors.white),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.tealAccent,
          background: Color(0xFF121212),
          surface: Color(0xFF1E1E1E),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent.shade200,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),

      // Kezdőképernyő: a Firebase inicializációját követő betöltőképernyő
      home: const LoadingScreen(),
    );
  }
}

/// A Firebase inicializációt végző betöltőképernyő.
/// Amint a Firebase sikeresen elindult, a bejelentkezési képernyőre navigál.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          // Ha kész a Firebase inicializáció, betöltjük a LoginScreen-t
          if (snapshot.connectionState == ConnectionState.done) {
            return const LoginScreen();
          }

          // Amíg tart a betöltés, egy töltő animáció jelenik meg
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.blueAccent,
              strokeWidth: 3.5, // opcionális
            ),
          );
        },
      ),
    );
  }
}
