// Imports ============================================================================================

// Flutter
import 'package:flutter/material.dart';

// Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Localization
import 'package:test_app/l10n/app_localizations.dart';

// Book Screen ========================================================================================
class BookingScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedServiceData;
  final Map<String, dynamic>? selectedProviderData;

  const BookingScreen({
    super.key,
    this.selectedServiceData,
    this.selectedProviderData,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

// Book Screen - State =================================================================================
class _BookingScreenState extends State<BookingScreen> {
  // States ----------------------------------------------------------------
  DateTime? selectedDate;
  String? selectedTimeSlot;
  List<Map<String, dynamic>> existingAppointments = [];

  // Controllers -----------------------------------------------------------
  final TextEditingController _notesController = TextEditingController();

  // Future for Provider Details -------------------------------------------
  late Future<DocumentSnapshot<Map<String, dynamic>>> providerFuture;

  // Controller Disposal when exiting --------------------------------------
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Initialization --------------------------------------------------------
  @override
  void initState() {
    super.initState();

    // Fetch Provider Details
    providerFuture = FirebaseFirestore.instance
        .collection('providers')
        .doc(widget.selectedProviderData?['provider_id'])
        .get();

    // Trigger the fetch for existing bookings immediately
    _fetchExistingAppointments();
  }

  // Widget Builder --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Access Localization & Provider
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 1, 183, 207),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 49, 250, 230),
        title: Text(l10n.bookingTitle),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 25,
          color: Color.fromARGB(255, 82, 79, 79),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Get Provider Details
              FutureBuilder<DocumentSnapshot>(
                // Fetch
                future: providerFuture,

                // Build based on output
                builder: (context, snapshot) {
                  // If awaiting answer, show spinner
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  // If there was an error, inform
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "${l10n.errorMessage}: ${snapshot.error}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  // If the Provider was not found, inform
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Center(
                      child: Text(
                        l10n.providerNotFound,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;

                  return Container(
                    width: double.infinity,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- SERVICE DETAILS ---
                        Center(
                          child: Text(
                            l10n.service,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(height: 20),

                        Text(
                          widget.selectedServiceData?['name'] ??
                              l10n.unknownService,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            const Icon(Icons.attach_money, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              "${l10n.cost}: \$${widget.selectedServiceData?['price'] ?? widget.selectedServiceData?['Cost'] ?? '0'}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(Icons.timer, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              "${l10n.duration}: ${widget.selectedServiceData?['duration'] ?? widget.selectedServiceData?['Min Duration'] ?? '0'} mins",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Text(
                          l10n.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.selectedServiceData?['description'] ??
                              widget.selectedServiceData?['Full Description'] ??
                              l10n.noDescription,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Divider(height: 20),

                        // --- PROVIDER DETAILS (Use 'data') ---
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            l10n.provider,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(height: 20),

                        Text(
                          data['name'] ?? l10n.providerName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildInfoRow(
                          Icons.email,
                          l10n.emailLabel,
                          data['email'] ?? 'N/A',
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          Icons.phone,
                          l10n.phoneLabel,
                          data['phone'] ?? 'N/A',
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          Icons.location_on,
                          l10n.addressLabel,
                          data['address'] ?? 'N/A',
                        ),
                        const SizedBox(height: 10),

                        Text(
                          l10n.bio,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(data['bio'] ?? l10n.noBio),
                        const Divider(),

                        // --- APPOINTMENT SECTION ---
                        const SizedBox(height: 40),
                        Center(
                          child: Text(
                            l10n.appointment,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(height: 20),

                        // Notes TextField
                        Text(
                          l10n.notesLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: l10n.notesHint,
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // DateTime Picker
                        Text(
                          l10n.selectDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: selectedDate == null
                                ? ''
                                : "${selectedDate!.toLocal()}".split(' ')[0],
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.selectDateHint,
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

                        // Time Slots
                        if (selectedDate != null) ...[
                          const SizedBox(height: 20),
                          Text(
                            l10n.availableSlots,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),

                          Builder(
                            builder: (context) {
                              // Generate slots based on filtered list
                              final slots = _generateTimeSlots(
                                selectedDate!,
                                data,
                              );

                              if (slots.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.event_busy,
                                        color: Colors.red.shade400,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(l10n.noAvailability),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: slots.map((slot) {
                                  final isSelected = selectedTimeSlot == slot;
                                  return ChoiceChip(
                                    label: Text(slot),
                                    selected: isSelected,
                                    selectedColor: Colors.teal,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    onSelected: (bool selected) {
                                      setState(() {
                                        selectedTimeSlot = selected
                                            ? slot
                                            : null;
                                      });
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],

                        // Confirm Button
                        if (selectedDate != null &&
                            selectedTimeSlot != null) ...[
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(200, 48),
                              ),
                              onPressed: () async {
                                // Show Loading Indicator
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                // Final Check before submission
                                try {
                                  // Get start of today
                                  final startOfDay = DateTime(
                                    selectedDate!.year,
                                    selectedDate!.month,
                                    selectedDate!.day,
                                  );

                                  // Get end of today
                                  final endOfDay = startOfDay.add(
                                    const Duration(days: 1),
                                  );

                                  // Find all submissions with the same time slot today
                                  final QuerySnapshot
                                  collisionCheck = await FirebaseFirestore
                                      .instance
                                      .collection('appointments')
                                      .where(
                                        'provider_id',
                                        isEqualTo: widget
                                            .selectedProviderData!['provider_id'],
                                      )
                                      .where(
                                        'time_slot',
                                        isEqualTo: selectedTimeSlot,
                                      )
                                      .where(
                                        'date',
                                        isGreaterThanOrEqualTo: startOfDay,
                                      )
                                      .where('date', isLessThan: endOfDay)
                                      .get();

                                  // If an appointment was found, inform the user
                                  if (collisionCheck.docs.isNotEmpty) {
                                    if (!context.mounted) return;
                                    Navigator.pop(context); // Close Loader

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.errorSlotBooked),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );

                                    // Refresh the Appointments
                                    _fetchExistingAppointments();
                                    return;
                                  }

                                  // If no same time slot was found, book the appointment
                                  await FirebaseFirestore.instance
                                      .collection('appointments')
                                      .add({
                                        'user_id': FirebaseAuth
                                            .instance
                                            .currentUser
                                            ?.uid,
                                        'date': selectedDate,
                                        'provider_id': widget
                                            .selectedProviderData!['provider_id'],
                                        'provider_name':
                                            data['name'] ??
                                            widget
                                                .selectedProviderData!['provider'],
                                        'service_name':
                                            widget.selectedServiceData?['name'],
                                        'price':
                                            widget
                                                .selectedServiceData?['price'] ??
                                            widget.selectedServiceData?['Cost'],
                                        'time_slot': selectedTimeSlot,
                                        'notes': _notesController.text.trim(),
                                        'status': 'upcoming',
                                        'created_at':
                                            FieldValue.serverTimestamp(),
                                      });

                                  if (!context.mounted) return;
                                  Navigator.pop(context);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.successBooking),
                                      backgroundColor: Colors.green,
                                    ),
                                  );

                                  Navigator.pop(context, true); // Pop Screen
                                } catch (e) {
                                  if (!context.mounted) return;
                                  Navigator.pop(context); // Pop Loader
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "${l10n.errorBookingFailed}: $e",
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(l10n.confirmButton),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fetch Appointments for Provider ---------------------------------------
  Future<void> _fetchExistingAppointments() async {
    try {
      // Fetch
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where(
            'provider_id',
            isEqualTo: widget.selectedProviderData?['provider_id'],
          )
          .where('date', isGreaterThanOrEqualTo: DateTime.now())
          .get();

      // Format response in a list
      if (mounted) {
        setState(() {
          existingAppointments = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching existing appointments: $e");
    }
  }

  // Calendar Function ------------------------------------------------------
  Future<void> _selectDate(BuildContext context) async {
    // The DatePicker automatically uses the context's Locale!
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
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

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        selectedTimeSlot = null; // Reset slot if date changes
      });
    }
  }

  // Get week Day ------------------------------------------------------------
  String _getDayName(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
  }

  // Helper: Check if two dates are exactly the same day ---------------------
  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  // Helper: Convert string to time
  DateTime _parseTime(DateTime baseDate, String timeString) {
    final parts = timeString.split(':');
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  // Helper: Convert time to String
  String _formatTime(DateTime date) {
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  // Generate Chips -----------------------------------------------------------
  List<String> _generateTimeSlots(
    DateTime date,
    Map<String, dynamic> providerData,
  ) {
    // Initialize the List
    List<String> slots = [];

    // Check if the selected date is Today
    bool isToday = _isSameDay(date, DateTime.now());
    DateTime now = DateTime.now();

    // Get week Day
    String dayName = _getDayName(date);

    // Get Provider's Schedule
    final scheduleForDay = providerData['Schedule']?[dayName];
    if (scheduleForDay == null ||
        (scheduleForDay is List && scheduleForDay.isEmpty)) {
      return [];
    }

    // Get appointment Duration
    int appointmentDuration = 40;
    var rawDuration = widget.selectedProviderData?['Max Duration'];
    if (rawDuration != null) {
      appointmentDuration = int.tryParse(rawDuration.toString()) ?? 40;
    }

    // Parse through the Provider's Schedule
    for (var shift in scheduleForDay) {
      final String startString = shift['Start'];
      final String endString = shift['End'];

      DateTime shiftStart = _parseTime(date, startString);
      DateTime shiftEnd = _parseTime(date, endString);
      DateTime currentSlot = shiftStart;

      while (currentSlot
              .add(Duration(minutes: appointmentDuration))
              .isBefore(shiftEnd) ||
          currentSlot
              .add(Duration(minutes: appointmentDuration))
              .isAtSameMomentAs(shiftEnd)) {
        DateTime endSlot = currentSlot.add(
          Duration(minutes: appointmentDuration),
        );

        // Check time, if the appointment is for today
        if (isToday && currentSlot.isBefore(now)) {
          // Skip this slot, move to the next time increment
          currentSlot = endSlot;
          continue;
        }

        // Create a time slot
        String formattedSlot =
            "${_formatTime(currentSlot)} - ${_formatTime(endSlot)}";
        slots.add(formattedSlot);
        currentSlot = endSlot;
      }
    }

    // Filter out slot that are reserved by other appointments
    slots.removeWhere((slotString) {
      for (var appointment in existingAppointments) {
        DateTime appointmentDate = (appointment['date'] as Timestamp).toDate();

        if (_isSameDay(appointmentDate, date) &&
            appointment['time_slot'] == slotString) {
          return true;
        }
      }
      return false;
    });

    return slots;
  }

  // Build Row
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 20),
        const SizedBox(width: 10),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }
}
