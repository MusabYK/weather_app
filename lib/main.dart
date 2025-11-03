import 'package:flutter/material.dart';
import 'package:weather_app/weather_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      brightness: MediaQuery.platformBrightnessOf(context),
      seedColor: Colors.blue,
    );
    // TextStyle? textStyle = Theme.of(context).textTheme.titleLarge;

    return MaterialApp(
      title: "Flutter",
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.onSecondary,
          // foregroundColor: colorScheme.onTertiary,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const WeatherScreen(),
    );
  }
}
