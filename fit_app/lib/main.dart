import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fit_app/firebase_options.dart';
import 'package:fit_app/screens/profile/featured_requests_screen.dart';
import 'package:fit_app/screens/splash/splash_screen.dart';
import 'package:fit_app/viewmodels/auth_viewmodel.dart';
import 'package:fit_app/viewmodels/wardrobe_viewmodel.dart';
import 'package:fit_app/viewmodels/weather_viewmodel.dart';
import 'package:fit_app/viewmodels/stylist_viewmodel.dart';
import 'package:fit_app/viewmodels/outfit_viewmodel.dart';
import 'package:fit_app/viewmodels/schedule_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize Stripe
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  Stripe.merchantIdentifier = 'merchant.the.fit.app';
  await Stripe.instance.applySettings();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Handle foreground notifications (app is open and visible)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      debugPrint('Foreground Notification: ${message.notification?.title}');

      final notificationType = message.data['type'] ?? '';

      // Determine snackbar appearance based on notification type
      Color bgColor;
      IconData icon;
      switch (notificationType) {
        case 'feature_approval':
          bgColor = const Color(0xff0AAE00);
          icon = Icons.verified_rounded;
          break;
        case 'feature_rejection':
          bgColor = const Color(0xffE53935);
          icon = Icons.info_outline_rounded;
          break;
        case 'premium_success':
          bgColor = const Color(0xff7C4DFF);
          icon = Icons.diamond_rounded;
          break;
        case 'payment_success':
          bgColor = const Color(0xff00897B);
          icon = Icons.check_circle_rounded;
          break;
        default:
          bgColor = Colors.deepPurple;
          icon = Icons.notifications_active_rounded;
      }

      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.notification!.title ?? 'Notification',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (message.notification!.body != null)
                      Text(
                        message.notification!.body!,
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: () {
              scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
            },
          ),
        ),
      );

      // Auto-refresh feature request data when approval/rejection arrives
      if (notificationType == 'feature_approval' ||
          notificationType == 'feature_rejection') {
        try {
          final ctx = navigatorKey.currentContext;
          if (ctx != null) {
            ctx.read<WardrobeViewmodel>().fetchFeaturedWardrobeRequests();
            ctx.read<WardrobeViewmodel>().fetchWardrobes();
          }
        } catch (_) {
          // Context may not be available yet during startup
        }
      }
    }
  });

  // Handle notification tap when app was in background (not terminated)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('Notification tapped (background): ${message.data}');
    _handleNotificationTap(message.data);
  });

  // Handle notification tap when app was terminated
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    debugPrint('Notification tapped (terminated): ${initialMessage.data}');
    // Delay to allow the app to fully build before navigating
    Future.delayed(const Duration(seconds: 2), () {
      _handleNotificationTap(initialMessage.data);
    });
  }

  runApp(const MyApp());
}

/// Routes the user to the correct screen based on notification data
void _handleNotificationTap(Map<String, dynamic> data) {
  final notificationType = data['type'] ?? '';

  if (notificationType == 'feature_approval' ||
      notificationType == 'feature_rejection' ||
      notificationType == 'payment_success') {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const FeaturedRequestsScreen(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewmodel()),
        ChangeNotifierProvider(create: (_) => WeatherViewmodel()),
        ChangeNotifierProvider(create: (_) => WardrobeViewmodel()),
        ChangeNotifierProvider(create: (_) => OutfitViewmodel()),
        ChangeNotifierProvider(create: (_) => ScheduleViewmodel()),
        ChangeNotifierProvider(create: (_) => StylistViewmodel()),
      ],
      child: MaterialApp(
        title: 'Fit App',
        scaffoldMessengerKey: scaffoldMessengerKey,
        navigatorKey: navigatorKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
