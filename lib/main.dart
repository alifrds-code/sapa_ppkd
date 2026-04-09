import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'shared_preferences/token_storage.dart';
import 'views/login_view.dart';
import 'views/main_screen.dart';

void main() async {
  // Wajib dipanggil sebelum pakai async di main
  WidgetsFlutterBinding.ensureInitialized();

  // Cek apakah user udah login (ada token tersimpan atau belum)
  var isLoggedIn = await TokenStorage.hasToken();

  // Cek settingan dark mode yang disimpan sebelumnya
  var isDarkMode = await ThemeStorage.getTheme();

  runApp(MyApp(isLoggedIn: isLoggedIn, isDarkMode: isDarkMode));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool isDarkMode;

  const MyApp({super.key, required this.isLoggedIn, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(isDarkMode),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'SAPA PPKD',
            debugShowCheckedModeBanner: false,

            // Biar bisa pakai bahasa Indonesia di date picker dll
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('id', 'ID'),
            ],

            // Tema terang
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF003F87),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF9F9F9),
            ),

            // Tema gelap
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF003F87),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF1A1C1E),
              cardColor: const Color(0xFF2C2E30),
            ),

            // Pakai tema sesuai pilihan user
            themeMode: themeProvider.themeMode,

            // Kalau udah login langsung ke MainScreen, kalau belum ke LoginView
            home: isLoggedIn ? const MainScreen() : const LoginView(),
          );
        },
      ),
    );
  }
}
