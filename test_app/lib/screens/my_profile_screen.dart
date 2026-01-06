// Imports ============================================================================================

// Flutter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Firebase
import 'package:cloud_firestore/cloud_firestore.dart';

// Localization
import 'package:test_app/l10n/app_localizations.dart';

// Files
import 'package:test_app/models/user_model.dart';

// My Profile Screen ==================================================================================
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

// My Profile Screen - State ==========================================================================
class _MyProfileScreenState extends State<MyProfileScreen> {
  // States --------------------------------------------------------------
  DateTime? selectedBirthday;
  bool isLoading = false;
  bool isInit = true;

  // Controllers ---------------------------------------------------------
  TextEditingController? _nameController;
  TextEditingController? _surnameController;
  TextEditingController? _phoneController;
  TextEditingController? _emailController;

  // Initialize controllers once------------------------------------------
  // Context doesn't exist before, so we need didChangeDependencies()
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final userModel = Provider.of<UserModel?>(context);

    // Only initialize once AND only if we have valid user data
    if (isInit && userModel != null) {
      _nameController = TextEditingController(text: userModel.name);
      _surnameController = TextEditingController(text: userModel.surname);
      _phoneController = TextEditingController(text: userModel.phone ?? '');
      _emailController = TextEditingController(text: userModel.email);
      selectedBirthday = userModel.birthday;
      isInit = false;
    }
  }

  // Disposal of controllers when exiting ---------------------------------
  @override
  void dispose() {
    _nameController?.dispose();
    _surnameController?.dispose();
    _phoneController?.dispose();
    _emailController?.dispose();
    super.dispose();
  }

  // Widget Builder --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel?>(context);
    // Access Localization
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 1, 183, 207),

      appBar: AppBar(
        title: Text(l10n.myProfile),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 49, 250, 230),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 25,
          color: Color.fromARGB(255, 82, 79, 79),
        ),
      ),

      body: userModel == null || _nameController == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),

                    child: Column(
                      children: [
                        // User Icon
                        const Icon(
                          Icons.account_circle,
                          size: 80,
                          color: Colors.teal,
                        ),
                        const SizedBox(height: 20),

                        // Name
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: l10n.nameLabel,
                            prefixIcon: const Icon(
                              Icons.person,
                              color: Colors.teal,
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Surname
                        TextField(
                          controller: _surnameController,
                          decoration: InputDecoration(
                            labelText: l10n.surnameLabel,
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: Colors.teal,
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: l10n.phoneLabel,
                            prefixIcon: const Icon(
                              Icons.phone,
                              color: Colors.teal,
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Birthday
                        TextField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: selectedBirthday == null
                                ? ''
                                : DateFormat(
                                    'MMM d, yyyy',
                                    // Use local locale for date formatting if desired
                                    Localizations.localeOf(context).toString(),
                                  ).format(selectedBirthday!),
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.birthdayLabel,
                            prefixIcon: const Icon(
                              Icons.cake,
                              color: Colors.teal,
                            ),
                            suffixIcon: const Icon(Icons.calendar_today),
                            border: const OutlineInputBorder(),
                          ),
                          onTap: () => _selectDate(context),
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextField(
                          controller: _emailController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: l10n.emailLabel,
                            prefixIcon: const Icon(
                              Icons.email,
                              color: Colors.grey,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () => saveProfile(l10n), // Pass l10n
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    l10n.saveChanges,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Calendar Function -----------------------------------------------------
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedBirthday ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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

    if (picked != null && picked != selectedBirthday) {
      setState(() {
        selectedBirthday = picked;
      });
    }
  }

  // Save Profile ------------------------------------------------------------
  Future<void> saveProfile(AppLocalizations l10n) async {
    final userModel = Provider.of<UserModel?>(context, listen: false);
    if (userModel == null || _nameController == null) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userModel.uid)
          .set({
            'name': _nameController!.text,
            'surname': _surnameController!.text,
            'birthday': selectedBirthday != null
                ? Timestamp.fromDate(selectedBirthday!)
                : null,
            'phone': _phoneController!.text,
            'email': _emailController!.text,
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.successProfileUpdate),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
