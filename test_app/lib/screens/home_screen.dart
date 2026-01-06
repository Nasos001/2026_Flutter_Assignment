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

// Files
import 'my_profile_screen.dart';
import 'appointments_history.dart';
import 'my_appointments_screen.dart';
import '../models/user_model.dart';
import 'booking_screen.dart';

// Home Screen ========================================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Home Screen - State ================================================================================
class _HomeScreenState extends State<HomeScreen> {
  // States ------------------------------------------------------------------
  String? selectedCategory;
  String? selectedServiceName;
  String? selectedProvider;
  Map<String, dynamic>? selectedServiceData;
  Map<String, dynamic>? selectedProviderData;
  List<DropdownMenuItem<String>> categories = [];

  // Initialization ----------------------------------------------------------
  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  // Widget Builder ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Get User Data
    final userModel = Provider.of<UserModel?>(context);

    // Get Localization & Provider
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 1, 183, 207),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 49, 250, 230),
        title: Text(l10n.homeTitle),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 25,
          color: Color.fromARGB(255, 82, 79, 79),
        ),
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Menu
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.cyanAccent),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    l10n.menu,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),

            // User Profile
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(userModel?.name ?? l10n.guest),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyProfileScreen(),
                  ),
                );
              },
            ),

            // My Appointments
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text(l10n.myAppointments),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyAppointmentsScreen(),
                  ),
                );
              },
            ),

            // Appointments History
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(l10n.appointmentsHistory),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppointmentsHistoryScreen(),
                  ),
                );
              },
            ),

            // Language Switch
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.changeLanguage),
              onTap: () {
                // Check current language and toggle
                final currentLocale = Localizations.localeOf(context);
                if (currentLocale.languageCode == 'en') {
                  localeProvider.setLocale(
                    const Locale('el'),
                  ); // Switch to Greek
                } else {
                  localeProvider.setLocale(
                    const Locale('en'),
                  ); // Switch to English
                }

                // Close drawer
                Navigator.pop(context);
              },
            ),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l10n.logout),
              onTap: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.logout),
                    content: Text(l10n.logoutConfirmation),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.logout),
                      ),
                    ],
                  ),
                );

                // Do nothing
                if (shouldLogout != true) return;

                // Close Drawer
                if (context.mounted) {
                  Navigator.pop(context);
                }

                // Logout
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                l10n.bookAppointment,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              // Category Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: l10n.category,
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                initialValue: selectedCategory,
                items: categories,
                onChanged: (newValue) {
                  setState(() {
                    selectedCategory = newValue;

                    // Reset Services
                    selectedServiceName = null;
                    selectedServiceData = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Service Dropdown
              StreamBuilder<QuerySnapshot>(
                // Define Stream's Source
                stream: FirebaseFirestore.instance
                    .collection('services')
                    .where('category', isEqualTo: selectedCategory)
                    .snapshots(),

                // Build based on output
                builder: (context, snapshot) {
                  // If no category is selected, show nothing
                  if (selectedCategory == null) return const SizedBox.shrink();

                  // If no output yet, show spinner
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  // If Data is empty or no data at all, inform
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Text(
                      l10n.noServicesFound,
                      style: const TextStyle(color: Colors.white),
                    );
                  }

                  // If we have data, format them in a list
                  List<DropdownMenuItem<String>> serviceItems = snapshot
                      .data!
                      .docs
                      .map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem<String>(
                          value: data['name'],
                          child: Text(data['name'] ?? 'Unknown'),
                        );
                      })
                      .toList();

                  // Return a dropdown with the new list
                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: l10n.service,
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    initialValue: selectedServiceName,
                    items: serviceItems,
                    onChanged: (newName) {
                      setState(() {
                        selectedServiceName = newName;
                        try {
                          final selectedDoc = snapshot.data!.docs.firstWhere(
                            (doc) =>
                                (doc.data() as Map<String, dynamic>)['name'] ==
                                newName,
                          );
                          selectedServiceData =
                              selectedDoc.data() as Map<String, dynamic>;
                        } catch (e) {
                          selectedServiceData = null;
                        }
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              // Display Service Details
              if (selectedServiceData != null) ...[
                Text(
                  l10n.serviceDetails,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Service Details
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Center(
                        child: Text(
                          selectedServiceData!['name'] ?? "No Name",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),

                      // Short Analysis -------------------------------------
                      Text(
                        l10n.shortAnalysis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 20),

                      // Cost
                      Row(
                        children: [
                          const Icon(Icons.attach_money, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            "${l10n.averageCost}: \$${selectedServiceData!['Cost'] ?? '0'}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Duration
                      Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            "${l10n.averageDuration}: ${selectedServiceData!['Duration'] ?? '0'} mins",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Text(
                        l10n.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        selectedServiceData!['Short Description'] ??
                            "No description available.",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),

                      // Full Analysis -------------------------------------
                      Text(
                        l10n.fullAnalysis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 20),

                      // Full Description
                      Text(
                        l10n.fullDescription,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        selectedServiceData!['Full Description'] ??
                            "No description available.",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 10),

                      // Providers Dropdown
                      Text(
                        l10n.selectProvider,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: l10n.provider,
                          prefixIcon: const Icon(Icons.person),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        initialValue: selectedProvider,
                        items: (selectedServiceData!['providers'] as List).map((
                          providerItem,
                        ) {
                          final data = providerItem as Map<String, dynamic>;
                          final name = data['provider'] ?? 'Unknown';
                          return DropdownMenuItem<String>(
                            value: name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedProvider = newValue;
                            final List providersList =
                                selectedServiceData!['providers'];
                            try {
                              selectedProviderData =
                                  providersList.firstWhere(
                                        (p) => p['provider'] == newValue,
                                      )
                                      as Map<String, dynamic>;
                            } catch (e) {
                              selectedProviderData = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Provider Details
                      if (selectedProviderData != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blueAccent),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${l10n.provider}: ${selectedProviderData!['provider']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "${l10n.specificCost}: \$${selectedProviderData!['Cost']}",
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                "${l10n.duration}: ${selectedProviderData!['Min Duration']} - ${selectedProviderData!['Max Duration']} min",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),

                      if (selectedProvider != null) ...[
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              final bool? result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingScreen(
                                    selectedServiceData: selectedServiceData,
                                    selectedProviderData: selectedProviderData,
                                  ),
                                ),
                              );

                              if (result == true && mounted) {
                                setState(() {
                                  selectedCategory = null;
                                  selectedServiceName = null;
                                  selectedProvider = null;
                                  selectedProviderData = null;
                                  selectedServiceData = null;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(200, 48),
                            ),
                            child: Text(l10n.bookButton),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Fetch Categories -----------------------------------------------------------------
  Future<void> fetchCategories() async {
    try {
      final QuerySnapshot response = await FirebaseFirestore.instance
          .collection("categories")
          .get();

      List<DropdownMenuItem<String>> newItems = [];
      newItems.addAll(
        response.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name']?.toString() ?? 'Unknown';
          return DropdownMenuItem(value: name, child: Text(name));
        }),
      );

      if (mounted) {
        setState(() {
          categories.addAll(newItems);
        });
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }
}
