// Imports ============================================================================================

// Flutter
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
    final l10n = AppLocalizations.of(context)!;

    // Ensure 'All' category exists
    if (categories.isEmpty || categories.first.value != 'All') {
      categories.insert(
        0,
        DropdownMenuItem(value: 'All', child: Text(l10n.filterAll)),
      );
    } else {
      categories[0] = DropdownMenuItem(
        value: 'All',
        child: Text(l10n.filterAll),
      );
    }

    // Get filtered appointments
    final filteredAppointments = applyFilters;
    final appointmentsPerMonth = getPerMonth(filteredAppointments);
    final appointmentsPerYear = getPerYear(filteredAppointments);

    // Sort keys
    final sortedMonthKeys = appointmentsPerMonth.keys.toList()..sort();
    final sortedYearKeys = appointmentsPerYear.keys.toList()..sort();

    // Find total time
    int totalMinutes = 0;
    for (final appointment in filteredAppointments) {
      final slot = appointment['time_slot']?.toString() ?? '';
      totalMinutes += calculateDurationMinutes(slot);
    }

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
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildFilters(context, l10n)),

                SliverToBoxAdapter(
                  child: _buildSummary(
                    filteredAppointments,
                    totalMinutes,
                    sortedMonthKeys,
                    appointmentsPerMonth,
                    sortedYearKeys,
                    appointmentsPerYear,
                    l10n,
                  ),
                ),

                filteredAppointments.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              l10n.noAppointmentsFound,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final appointment = filteredAppointments[index];
                          return _buildAppointmentCard(
                            appointment,
                            context,
                            l10n,
                          );
                        }, childCount: filteredAppointments.length),
                      ),
              ],
            ),
    );
  }

  // Filters -------------------------------------------------------------
  Widget _buildFilters(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),

      child: Column(
        children: [
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
            onChanged: (value) => setState(() => selectedCategory = value),
          ),

          const SizedBox(height: 12),
          _buildDateField(
            context,
            l10n.startDateLabel,
            l10n.selectStartHint,
            start,
            (d) => setState(() => start = d),
            Icons.calendar_today,
            Colors.teal,
          ),
          const SizedBox(height: 12),
          _buildDateField(
            context,
            l10n.endDateLabel,
            l10n.selectEndHint,
            end,
            (d) => setState(() => end = d),
            Icons.event,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  // Date Field -----------------------------------------------------------
  Widget _buildDateField(
    BuildContext context,
    String label,
    String hint,
    DateTime? value,
    Function(DateTime) onPick,
    IconData icon,
    Color color,
  ) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(
        text: value == null
            ? ''
            : DateFormat(
                'MMM d, yyyy',
                Localizations.localeOf(context).toString(),
              ).format(value),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      onTap: () async {
        final pick = await _selectDate(context, value);
        if (pick != null) onPick(pick);
      },
    );
  }

  // Summary ----------------------------------------------------------------
  Widget _buildSummary(
    List<Map<String, dynamic>> filteredAppointments,
    int totalMinutes,
    List<String> sortedMonthKeys,
    Map<String, int> appointmentsPerMonth,
    List<String> sortedYearKeys,
    Map<String, int> appointmentsPerYear,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              l10n.appointmentsSummaryTitle,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            "${l10n.totalAppointmentsLabel}: ${filteredAppointments.length}",
          ),
          Text(
            "${l10n.totalAppointmentTimeLabel}: "
            "$totalMinutes ${l10n.minutesLabel}",
          ),
          const SizedBox(height: 8),
          Text(
            l10n.monthlyTotalsLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final key in sortedMonthKeys)
            Text("$key: ${l10n.currencySymbol}${appointmentsPerMonth[key]}"),
          const SizedBox(height: 8),
          Text(
            l10n.yearlyTotalsLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final key in sortedYearKeys)
            Text("$key: ${l10n.currencySymbol}${appointmentsPerYear[key]}"),
        ],
      ),
    );
  }

  // Appointment Card ------------------------------------------------------
  Widget _buildAppointmentCard(
    Map<String, dynamic> appointment,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final date = DateFormat(
      'MMM d, yyyy',
      Localizations.localeOf(context).toString(),
    ).format((appointment['date'] as Timestamp).toDate());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    appointment['service_name'] ?? l10n.unknownService,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
                Text(
                  "${l10n.currencySymbol}${appointment['price'] ?? 0}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              "${l10n.provider}: "
              "${appointment['provider_name'] ?? l10n.unknownProvider}",
            ),
            const SizedBox(height: 8),
            Text(
              "$date${l10n.dateTimeSeparator}"
              "${appointment['time_slot'] ?? l10n.noTimeLabel}",
            ),
            if (appointment['notes'] != null &&
                appointment['notes'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  "${l10n.notesLabel}: ${appointment['notes']}",
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 8),
            Text("${l10n.statusLabel}: ${appointment['status']}"),
          ],
        ),
      ),
    );
  }

  // Get Appointments per month ----------------------------------------------
  Map<String, int> getPerMonth(List<Map<String, dynamic>> apps) {
    final results = <String, int>{};
    for (final a in apps) {
      final d = (a['date'] as Timestamp).toDate();
      final key = "${d.year}-${d.month.toString().padLeft(2, '0')}";
      results[key] = (results[key] ?? 0) + int.parse(a['price']);
    }
    return results;
  }

  // Get Appointments per year -----------------------------------------------
  Map<String, int> getPerYear(List<Map<String, dynamic>> apps) {
    final results = <String, int>{};
    for (final a in apps) {
      final y = (a['date'] as Timestamp).toDate().year.toString();
      results[y] = (results[y] ?? 0) + int.parse(a['price']);
    }
    return results;
  }

  // Calculate duration of an appointment -------------------------------------
  int calculateDurationMinutes(String slot) {
    final p = slot.split('-');
    if (p.length != 2) return 0;
    final s = p[0].split(':');
    final e = p[1].split(':');
    final sm = int.parse(s[0]) * 60 + int.parse(s[1]);
    final em = int.parse(e[0]) * 60 + int.parse(e[1]);
    return (em - sm).clamp(0, 1440);
  }

  // Calendar ------------------------------------------------------------------
  Future<DateTime?> _selectDate(BuildContext context, DateTime? initial) {
    return showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  // Apply Filters --------------------------------------------------------------
  List<Map<String, dynamic>> get applyFilters {
    return allAppointments.where((appointment) {
      // Inspect the category
      final categoryOk =
          selectedCategory == 'All' ||
          appointment['category'] == selectedCategory;

      // If no start date, then just check based on category
      if (start == null) return categoryOk;

      // Otherwise, get appointment's date
      final date = (appointment['date'] as Timestamp).toDate();

      // If end date is stated, use it, otherwise, use current time
      final endTime = end ?? DateTime.now();

      return categoryOk &&
          date.isAfter(start!.subtract(const Duration(seconds: 1))) &&
          date.isBefore(endTime.add(const Duration(seconds: 1)));
    }).toList();
  }

  // Fetch Categories from database ----------------------------------------------
  Future<void> fetchCategories() async {
    final snap = await FirebaseFirestore.instance
        .collection("categories")
        .get();

    if (!mounted) return;
    setState(() {
      categories.addAll(
        snap.docs.map(
          (d) => DropdownMenuItem(value: d['name'], child: Text(d['name'])),
        ),
      );
    });
  }

  // Get Appointment of the User --------------------------------------------------
  Future<void> getAppointments() async {
    // Get current user
    final user = FirebaseAuth.instance.currentUser;

    // Safety check
    if (user == null) return setState(() => loading = false);

    // Fetch
    final snap = await FirebaseFirestore.instance
        .collection("appointments")
        .where('user_id', isEqualTo: user.uid)
        .where('date', isLessThanOrEqualTo: Timestamp.now())
        .orderBy('date', descending: true)
        .get();

    if (!mounted) return;
    setState(() {
      allAppointments = snap.docs
          .map((d) => {...d.data(), 'id': d.id})
          .toList();
      loading = false;
    });
  }
}
