import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'shared_preferences/token_storage.dart';
import 'views/login_view.dart';
import 'views/main_screen.dart';

void main() async {
  // Wajib ditambahin kalau kita mau ngecek memory HP sebelum aplikasi jalan
  WidgetsFlutterBinding.ensureInitialized();

  // Cek apakah token udah ada di brankas HP
  final bool isLoggedIn = await TokenStorage.hasToken();

  // Cek preferensi Dark Mode dari SharedPreferences
  final bool isDarkMode = await ThemeStorage.getTheme();

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

            // ---- LOCALIZATION (Wajib buat showDatePicker bahasa Indonesia) ----
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('id', 'ID'),
            ],

            // ---- LIGHT THEME ----
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF003F87),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF9F9F9),
            ),

            // ---- DARK THEME ----
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF003F87),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF1A1C1E),
              cardColor: const Color(0xFF2C2E30),
            ),

            // Gunakan preferensi dari ThemeProvider
            themeMode: themeProvider.themeMode,

            // Kalau isLoggedIn = true (ada token), langsung ke MainScreen.
            // Kalau false (kosong), lempar ke LoginView.
            home: isLoggedIn ? const MainScreen() : const LoginView(),
          );
        },
      ),
    );
  }
}
