// Imports ============================================================================================

// Flutter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_app/screens/registration_screen.dart';

// Localization
import 'package:test_app/l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

// Login Screen =======================================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// Login Screen - State ===============================================================================
class _LoginScreenState extends State<LoginScreen> {
  // States ------------------------------------------------------------
  String email = '', password = '';
  bool isLoading = false;

  // Widget Builder ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Access Localization & Provider
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 1, 183, 207),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 49, 250, 230),
        title: Text(l10n.loginTitle),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 25,
          color: Color.fromARGB(255, 82, 79, 79),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: l10n.changeLanguage,
            onPressed: () {
              final currentLocale = localeProvider.locale;
              if (currentLocale.languageCode == 'en') {
                localeProvider.setLocale(const Locale('el'));
              } else {
                localeProvider.setLocale(const Locale('en'));
              }
            },
          ),
        ],
      ),

      body: Center(
        child: SingleChildScrollView(
          child: Container(
            height: 400,
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(230, 255, 255, 255),
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 85, 84, 84).withValues(),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.emailLabel,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    setState(() => email = value);
                  },
                ),
                const SizedBox(height: 20),

                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.passwordLabel,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  obscureText: true,
                  onChanged: (value) {
                    setState(() => password = value);
                  },
                ),
                const SizedBox(height: 20),

                isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.cyan),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 48),
                        ),
                        onPressed: () {
                          login(l10n); // Pass l10n to function
                        },
                        child: Text(l10n.loginButton),
                      ),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },

                  child: Text(
                    l10n.registerLink,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Login Function --------------------------------------------------------------
  Future<void> login(AppLocalizations l10n) async {
    // Indicate Loading
    setState(() => isLoading = true);

    try {
      // Try to sign in
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Show Success Message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${l10n.loginSuccess} ${credential.user?.email}"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${l10n.errorMessage}: ${e.message}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}
