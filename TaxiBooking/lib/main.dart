import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:taxibooking/sesources/home_page.dart';
import 'package:taxibooking/sesources/login_page.dart';
import 'package:taxibooking/sesources/search_page.dart';
import 'package:taxibooking/splashpage/splash_page.dart';
import 'package:taxibooking/theme/theme_provider.dart';
import 'package:taxibooking/widgets/pay_fare_amount_dialog.dart';

Future<void> main() async {
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Flutter Demo',
      themeMode: ThemeMode.system,
      theme: Themes.lightTheme,
      darkTheme: Themes.darkTheme,
      debugShowCheckedModeBanner: false,
      home:  SplashPage(),
    );
  }
}