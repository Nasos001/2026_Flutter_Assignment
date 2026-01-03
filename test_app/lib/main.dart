// Imports ============================================================================================

// Flutter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Localization
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:test_app/l10n/app_localizations.dart';
import 'providers/locale_provider.dart';

// Files
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'models/user_model.dart';

// Main ===============================================================================================
void main() async {
  // Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();

  // Connect with Firebase according to Platform
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Run Root Widget
  runApp(const RootApp());
}

// RootApp =============================================================================================
class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Initialize LocaleProvider
        ChangeNotifierProvider(create: (_) => LocaleProvider()),

        // Auth User Provider
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
      ],
      child: const MyApp(),
    );
  }
}

// MyApp: The MaterialApp =============================================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the Language provider
    final localeProvider = Provider.of<LocaleProvider>(context);
    final user = Provider.of<User?>(context);

    return MaterialApp(
      // Remove Debug Banner
      debugShowCheckedModeBanner: false,

      // Connect Localization settings
      locale: localeProvider.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Wrap the Navigator with User Stream
      builder: (context, child) {
        // No Auth User, return raw Navigator
        if (user == null) return child!;

        // Else, wrap Navigator in User Data Stream
        return StreamProvider<UserModel?>.value(
          value: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots()
              .map(
                (snap) => snap.exists
                    ? UserModel.fromMap(snap.data()!, user.uid)
                    : null,
              ),
          initialData: null,
          child: child!,
        );
      },

      // Render based on Auth User Stream output
      home: user == null ? const LoginScreen() : const HomeScreen(),
    );
  }
}
