// Imports ============================================================================================

// Fluter
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Localization
import 'package:test_app/l10n/app_localizations.dart';

// Appointment History Screen =========================================================================
class AppointmentsHistoryScreen extends StatefulWidget {
  const AppointmentsHistoryScreen({super.key});

  @override
  State<AppointmentsHistoryScreen> createState() =>
      _AppointmentsHistoryScreenState();
}

// Appointment History Screen - State =================================================================
class _AppointmentsHistoryScreenState extends State<AppointmentsHistoryScreen> {
  // States -----------------------------------------------------------------
  List<Map<String, dynamic>> allAppointments = [];
  List<DropdownMenuItem<String>> categories = [];
  String? selectedCategory = 'All';
  DateTime? start, end;
  bool loading = true;

  // Initialization ---------------------------------------------------------
  @override
  void initState() {
    super.initState();
    fetchCategories();
    getAppointments();
  }

  // Builder ----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Access Localization
    final l10n = AppLocalizations.of(context)!;

    // Ensure 'All' category exists
    if (categories.isEmpty || categories.first.value != 'All') {
      categories.insert(
        0,
        DropdownMenuItem(value: 'All', child: Text(l10n.filterAll)),
      );
    } else {
      // Update the label for 'All' in case language switched
      categories[0] = DropdownMenuItem(
        value: 'All',
        child: Text(l10n.filterAll),
      );
    }

    // Get appointments based on filters
    final filteredAppointments = applyFilters;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 1, 183, 207),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 49, 250, 230),
        title: Text(l10n.appointmentsHistory),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 25,
          color: Color.fromARGB(255, 82, 79, 79),
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 10),
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 1. CATEGORY DROPDOWN
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.category,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        initialValue: selectedCategory,
                        items: categories,
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      // START DATE
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: start == null
                              ? ''
                              : DateFormat(
                                  'MMM d, yyyy',
                                  Localizations.localeOf(context).toString(),
                                ).format(start!),
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.startDateLabel,
                          hintText: l10n.selectStartHint,
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            color: Colors.teal,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        onTap: () async {
                          final pick = await _selectDate(context, start);
                          if (pick != null) setState(() => start = pick);
                        },
                      ),

                      const SizedBox(height: 12),

                      // END DATE
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: end == null
                              ? ''
                              : DateFormat(
                                  'MMM d, yyyy',
                                  Localizations.localeOf(context).toString(),
                                ).format(end!),
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.endDateLabel,
                          hintText: l10n.selectEndHint,
                          suffixIcon: const Icon(
                            Icons.event,
                            color: Colors.orange,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        onTap: () async {
                          final pick = await _selectDate(context, end);
                          if (pick != null) setState(() => end = pick);
                        },
                      ),
                    ],
                  ),
                ),

                // RESULTS LIST
                Expanded(
                  child: filteredAppointments.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noAppointmentsFound,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: filteredAppointments.length,
                          itemBuilder: (context, index) {
                            final appointment = filteredAppointments[index];
                            String date =
                                DateFormat(
                                  'MMM d, yyyy',
                                  Localizations.localeOf(context).toString(),
                                ).format(
                                  (appointment['date'] as Timestamp).toDate(),
                                );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Service & Price
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            appointment['service_name'] ??
                                                l10n.unknownService,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal,
                                            ),
                                          ),
                                        ),

                                        Text(
                                          "\$${appointment['price'] ?? 0}",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),

                                    // Details
                                    Text(
                                      "${l10n.provider}: ${appointment['provider_name'] ?? 'Unknown'}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),

                                    Text(
                                      "$date  •  ${appointment['time_slot'] ?? 'No time'}",
                                      style: const TextStyle(fontSize: 16),
                                    ),

                                    if (appointment['notes'] != null &&
                                        appointment['notes']
                                            .toString()
                                            .isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 16.0,
                                        ),
                                        child: Text(
                                          "${l10n.notesLabel}: ${appointment['notes']}",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // Updated Calendar Function (Accepts an initial date)
  Future<DateTime?> _selectDate(BuildContext context, DateTime? initial) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
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
    return picked;
  }

  // Filter Logic
  List<Map<String, dynamic>> get applyFilters {
    return allAppointments.where((appointment) {
      // 1. Category
      final categoryMatches =
          selectedCategory == 'All' ||
          appointment['category'] == selectedCategory;

      // 2. Dates
      bool dateMatches = true;
      if (start != null) {
        final appDate = (appointment['date'] as Timestamp).toDate();

        // Use the selected End date, OR default to Now if not picked
        final rangeEnd = end ?? DateTime.now();

        // Inclusive check
        dateMatches =
            appDate.isAfter(start!.subtract(const Duration(seconds: 1))) &&
            appDate.isBefore(rangeEnd.add(const Duration(seconds: 1)));
      }

      return categoryMatches && dateMatches;
    }).toList();
  }

  // Fetch Categories
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

  // Fetch Appointments
  Future<void> getAppointments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => loading = false);
        return;
      }

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("appointments")
          .where('user_id', isEqualTo: user.uid)
          .where('date', isLessThanOrEqualTo: Timestamp.now())
          .orderBy('date', descending: true)
          .get();

      if (mounted) {
        setState(() {
          allAppointments = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
      if (mounted) setState(() => loading = false);
    }
  }
}
