// Imports ============================================================================================

// Flutter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Localization
import 'package:test_app/l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

// Registration ========================================================================================
class RegisterScreen extends StatefulWidget {
  // Constructor
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

// Registration - State ================================================================================
class _RegisterScreenState extends State<RegisterScreen> {
  // States -----------------------------------------------------------
  String email = '',
      phone = '',
      password = '',
      name = '',
      surname = '',
      password2 = '';
  DateTime? birthday;
  bool isLoading = false;

  // Builder -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Access Localization & Provider
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 1, 183, 207),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 49, 250, 230),
        title: Text(l10n.registrationTitle),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 25,
          color: Color.fromARGB(255, 82, 79, 79),
        ),

        //
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
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(230, 255, 255, 255),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
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
                // Name Field
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.nameLabel,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => setState(() => name = value),
                ),
                const SizedBox(height: 16),

                // Surname Field
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.surnameLabel,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => setState(() => surname = value),
                ),
                const SizedBox(height: 16),

                // Birthday Field
                TextField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: birthday == null
                        ? ''
                        : "${birthday!.toLocal()}".split(' ')[0],
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.birthdayHint,
                    suffixIcon: const Icon(
                      Icons.calendar_today,
                      color: Colors.teal,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 16),

                // Phone Field
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.phoneLabel,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => setState(() => phone = value),
                ),
                const SizedBox(height: 16),

                // Email Field
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.emailLabel,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => setState(() => email = value),
                ),
                const SizedBox(height: 16),

                // Password Field
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.passwordLabel,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  obscureText: true,
                  onChanged: (value) => setState(() => password = value),
                ),
                const SizedBox(height: 16),

                // Repeat Password Field
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.repeatPasswordLabel,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  obscureText: true,
                  onChanged: (value) => setState(() => password2 = value),
                ),
                const SizedBox(height: 24),

                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 48),
                        ),
                        onPressed: () {
                          if ((password == password2) &&
                              (password != '' &&
                                  password2 != '' &&
                                  name != '' &&
                                  surname != '' &&
                                  email != "" &&
                                  birthday != null)) {
                            if (birthday!.isBefore(DateTime.now())) {
                              register(l10n); // Pass l10n
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.errorInvalidBirthday),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.errorIncompleteForm)),
                            );
                          }
                        },
                        child: Text(l10n.registerButton),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Calendar Function
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: birthday ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.teal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != birthday) {
      setState(() {
        birthday = picked;
      });
    }
  }

  // Registration Function
  Future<void> register(AppLocalizations l10n) async {
    // Indicate Loading
    setState(() => isLoading = true);

    try {
      // Create Auth User
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create Entry in Users Collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'name': name,
            'surname': surname,
            'birthday': birthday,
            'email': email,
            'phone': phone,
            'uid': credential.user!.uid,
            'created_at': FieldValue.serverTimestamp(),
            'role': 'user',
          });

      // Show Success Message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.registrationSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      // Show Error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.errorMessage}: ${e.message}")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}
