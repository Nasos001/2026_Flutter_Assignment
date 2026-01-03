// Imports ============================================================================================

// Flutter
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Localization
import 'package:test_app/l10n/app_localizations.dart';

// Files
import 'booking_screen.dart';

// My Appointments Screen ==============================================================================
class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

// My Appointments Screen - State ======================================================================
class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  // State Variables -----------------------------------------------------
  List<Map<String, dynamic>> allAppointments = [];
  bool loading = true;
  String _selectedFilter = 'All';
  DateTime _focusedDate = DateTime.now();

  // Init State - Fetch Appointments -------------------------------------
  @override
  void initState() {
    super.initState();
    getAppointments();
  }

  // Build Widget --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Access Localization
    final l10n = AppLocalizations.of(context)!;

    // Get Appointments based on filters
    final currentList = filteredAppointments;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 1, 183, 207),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 49, 250, 230),
        title: Text(l10n.myAppointments),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 25,
          color: Color.fromARGB(255, 82, 79, 79),
        ),

        actions: [
          // Jump to Today Button
          if (!(_selectedFilter == 'All'))
            IconButton(
              icon: const Icon(Icons.today, color: Colors.teal),
              tooltip: l10n.jumpToToday,
              onPressed: () {
                setState(() {
                  _focusedDate = DateTime.now();
                });
              },
            ),
        ],
      ),

      body: Column(
        children: [
          // --- FILTER TOGGLES ---
          Container(
            color: Colors.white.withValues(),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              children: [
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      return states.contains(WidgetState.selected)
                          ? Colors.teal
                          : Colors.white;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      return states.contains(WidgetState.selected)
                          ? Colors.white
                          : Colors.teal;
                    }),
                  ),
                  segments: [
                    ButtonSegment(value: 'All', label: Text(l10n.filterAll)),
                    ButtonSegment(value: 'Day', label: Text(l10n.filterDay)),
                    ButtonSegment(value: 'Week', label: Text(l10n.filterWeek)),
                    ButtonSegment(
                      value: 'Month',
                      label: Text(l10n.filterMonth),
                    ),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      // Switch Filter
                      _selectedFilter = newSelection.first;

                      // Reset Focus
                      _focusedDate = DateTime.now();
                    });
                  },
                ),

                // --- DATE NAVIGATION HEADER ---
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!(_selectedFilter == 'All')) ...[
                      IconButton(
                        onPressed: () => _navigateDate(-1),
                        icon: const Icon(
                          Icons.chevron_left,
                          size: 30,
                          color: Colors.teal,
                        ),
                      ),
                    ],

                    Text(
                      _getDateRangeText(l10n),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    if (!(_selectedFilter == 'All')) ...[
                      IconButton(
                        onPressed: () => _navigateDate(1),
                        icon: const Icon(
                          Icons.chevron_right,
                          size: 30,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // --- APPOINTMENT LIST ---
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : currentList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_note,
                          size: 60,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noAppointmentsFound,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: currentList.length,
                    itemBuilder: (context, index) {
                      final appointment = currentList[index];
                      // Safely format date using locale
                      String dateStr = DateFormat(
                        'MMM d, yyyy',
                        Localizations.localeOf(context).toString(),
                      ).format((appointment['date'] as Timestamp).toDate());

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
                              // Service Name & Price
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    appointment['service_name'] ??
                                        l10n.unknownService,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
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

                              // Provider
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${l10n.provider}: ${appointment['provider_name'] ?? 'Unknown'}",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Time
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "$dateStr  •  ${appointment['time_slot'] ?? 'No time'}",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Notes
                              Row(
                                children: [
                                  const Icon(
                                    Icons.notes,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${l10n.notesLabel}: ${appointment['notes'] ?? l10n.noNotes}",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),

                              // Actions
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _changeAppointment(
                                      appointment['service_name'],
                                      appointment['provider_id'],
                                      appointment['id'],
                                      l10n, // Pass l10n
                                    ),
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: Text(l10n.changeButton),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => _cancelAppointment(
                                      appointment['id'],
                                      l10n, // Pass l10n
                                    ),
                                    icon: const Icon(Icons.delete, size: 18),
                                    label: Text(l10n.cancelButton),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
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

  // Navigation Logic ----------------------------------------------------
  void _navigateDate(int step) {
    setState(() {
      if (_selectedFilter == 'Day') {
        _focusedDate = _focusedDate.add(Duration(days: step));
      } else if (_selectedFilter == 'Week') {
        _focusedDate = _focusedDate.add(Duration(days: step * 7));
      } else if (_selectedFilter == 'Month') {
        // Safely increment month (handling year rollover)
        _focusedDate = DateTime(
          _focusedDate.year,
          _focusedDate.month + step,
          1,
        );
      }
    });
  }

  // Filtered Appointments -----------------------------------------------
  List<Map<String, dynamic>> get filteredAppointments {
    // If filter is 'All', return everything
    if (_selectedFilter == 'All') {
      return allAppointments;
    }

    // Normalize focusedDate to start of day (00:00:00)
    DateTime startOfFocus = DateTime(
      _focusedDate.year,
      _focusedDate.month,
      _focusedDate.day,
    );

    // Filter based on selected filter
    return allAppointments.where((appointment) {
      DateTime appointmentDate = (appointment['date'] as Timestamp).toDate();

      if (_selectedFilter == 'Day') {
        // Match exact Day
        return appointmentDate.year == startOfFocus.year &&
            appointmentDate.month == startOfFocus.month &&
            appointmentDate.day == startOfFocus.day;
      } else if (_selectedFilter == 'Week') {
        // Calculate end of week
        DateTime endOfWeek = startOfFocus.add(const Duration(days: 7));

        return appointmentDate.isAfter(
              startOfFocus.subtract(const Duration(seconds: 1)),
            ) &&
            appointmentDate.isBefore(endOfWeek);
      } else if (_selectedFilter == 'Month') {
        // Match Year and Month
        return appointmentDate.year == startOfFocus.year &&
            appointmentDate.month == startOfFocus.month;
      }
      return true;
    }).toList();
  }

  // Header Text for Date Range ---------------------------------------------
  String _getDateRangeText(AppLocalizations l10n) {
    // Use the current locale from context implicitly via DateFormat,
    // or pass locale string if needed.
    final localeStr = Localizations.localeOf(context).toString();

    if (_selectedFilter == 'All') return l10n.allUpcoming;

    if (_selectedFilter == 'Day') {
      return DateFormat('MMM d, yyyy', localeStr).format(_focusedDate);
    } else if (_selectedFilter == 'Week') {
      DateTime end = _focusedDate.add(const Duration(days: 6));
      return "${DateFormat('MMM d', localeStr).format(_focusedDate)} - ${DateFormat('MMM d, yyyy', localeStr).format(end)}";
    } else if (_selectedFilter == 'Month') {
      return DateFormat('MMMM yyyy', localeStr).format(_focusedDate);
    }
    return "";
  }

  // Fetch Appointments from Firestore --------------------------------------
  Future<void> getAppointments() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("appointments")
          .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('status', isEqualTo: "upcoming")
          .orderBy('date')
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
      debugPrint("Error: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  // Change Appointment Logic -------------------------------------------------
  Future<void> _changeAppointment(
    String? serviceName,
    String? providerId,
    String? appId,
    AppLocalizations l10n,
  ) async {
    // If anything is null, return error
    if (serviceName == null || providerId == null || appId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot change: Missing Data")),
      );
      return;
    }

    // Indicate Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Fetch appointment's service data
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("services")
          .where('name', isEqualTo: serviceName)
          .limit(1)
          .get();

      // If the service was not found, throw error
      if (snapshot.docs.isEmpty) {
        throw "Service '$serviceName' not found";
      }

      // If it was found, save it as Map
      final serviceDoc = snapshot.docs.first;
      final serviceData = serviceDoc.data() as Map<String, dynamic>;
      serviceData['id'] = serviceDoc.id;

      List<dynamic> providers = serviceData['providers'] ?? [];
      Map<String, dynamic> selectedProviderData = {};

      for (var provider in providers) {
        if (provider['provider_id'] == providerId) {
          selectedProviderData = provider as Map<String, dynamic>;
          break;
        }
      }

      if (mounted) Navigator.pop(context);

      if (mounted) {
        final bool? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingScreen(
              selectedServiceData: serviceData,
              selectedProviderData: selectedProviderData,
            ),
          ),
        );

        if (result == true) {
          await FirebaseFirestore.instance
              .collection('appointments')
              .doc(appId)
              .delete();

          getAppointments();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.appointmentChangedSuccess)),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${l10n.errorMessage}: $e")));
      }
    }
  }

  // Cancel Appointment Logic -------------------------------------------------
  Future<void> _cancelAppointment(String appId, AppLocalizations l10n) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.cancelAppointmentTitle),
            content: Text(l10n.cancelAppointmentContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.no),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  l10n.yesCancel,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appId)
          .delete();

      getAppointments();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.appointmentCancelled)));
      }
    }
  }
}
