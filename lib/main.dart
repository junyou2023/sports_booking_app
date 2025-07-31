import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'utils/theme.dart';
import 'screens/home_page.dart';
import 'services/api_client.dart';
import 'services/notification_service.dart';

/// Application entry-point.
/// ---------------------------------------------------------------------------
/// 1. `WidgetsFlutterBinding.ensureInitialized()` is required when you need to
///    await asynchronous code **before** runApp (here: loading the .env file).
/// 2. `dotenv.load()` reads the API_BASE_URL (and any future secrets) from the
///    `mobile/.env` file included as a Flutter asset.
/// 3. `ProviderScope` must wrap the entire widget-tree so Riverpod can manage
///    its providers (e.g. `sportsProvider`, `slotsProvider`, …).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'mobile/.env');
  // <-- load .env variables

  Stripe.publishableKey = dotenv.env['STRIPE_PUBLIC_KEY'] ?? '';

  initApiClient();
  await initPush();

  runApp(
    const ProviderScope(                        // <-- Riverpod root scope
      child: SportsBookingApp(),
    ),
  );
}

Future<void> initPush() async {
  if (dotenv.env['FCM_ENABLED'] != '1') return;
  try {
    await Firebase.initializeApp();
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    final token = await messaging.getToken();
    if (token != null) {
      await notificationService.registerDevice(token, 'android');
    }
  } catch (_) {}
}

/// Root widget of the app.
class SportsBookingApp extends StatelessWidget {
  const SportsBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sports Booking',
      theme: AppTheme.light,                    // centralised light theme
      debugShowCheckedModeBanner: false,
      home: const HomePage(),             // first screen
    );
  }
}
