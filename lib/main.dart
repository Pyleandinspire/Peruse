import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2A3F55);
    const warmGold = Color(0xFFCFAF68);
    const backgroundColor = Color(0xFFF7F8F7);
    const cardColor = Color(0xFFFFFFFF);

    return MaterialApp(
      title: '长物',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: primaryColor,
          onPrimary: cardColor,
          secondary: warmGold,
          onSecondary: primaryColor,
          error: Colors.red,
          onError: cardColor,
          surface: cardColor,
          onSurface: primaryColor,
          surfaceContainerHighest: backgroundColor,
        ),
        scaffoldBackgroundColor: backgroundColor,
        cardColor: cardColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: cardColor,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: cardColor,
            shape: const CircleBorder(),
            elevation: 4,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primaryColor),
        ),
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      home: const HomeScreen(),
    );
  }
}
