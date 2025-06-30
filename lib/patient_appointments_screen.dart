import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? patientName;
  String? patientEmail;
  bool _drawerLoading = true;
  int _selectedTabIndex = 0; // 0 = Book, 1 = My Appointments

  // Highlight confirmed days for calendar
  Set<DateTime> confirmedDays = {};

  @override
  void initState() {
    super.initState();
    _loadPatientInfo();
    _fetchConfirmedDays();
  }

  Future<void> _loadPatientInfo() async {
    setState(() => _drawerLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('patients').doc(user.uid).get();
      patientName = doc.data()?['name'] ?? 'Unknown';
      patientEmail = doc.data()?['email'] ?? 'unknown@example.com';
    }
    setState(() => _drawerLoading = false);
  }

  Future<void> _fetchConfirmedDays() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('patientId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'confirmed')
        .get();
    final days = <DateTime>{};
    for (var doc in snap.docs) {
      final data = doc.data();
      final date = (data['dateTime'] as Timestamp).toDate();
      days.add(DateTime(date.year, date.month, date.day));
    }
    setState(() {
      confirmedDays = days;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xFF161B22),
        child: _drawerLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: Color(0xFF0D1117)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey.shade800,
                          backgroundImage: AssetImage('assets/default_profile.png'),
                        ),
                        const SizedBox(height: 12),
                        Text(patientName ?? '', style: const TextStyle(color: Colors.white)),
                        Text(patientEmail ?? '', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.home, color: Colors.white),
                    title: Text('Dashboard', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      Navigator.of(context).pop(); // Go back to dashboard
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.calendar_today, color: Colors.white),
                    title: Text('My Appointments', style: TextStyle(color: Colors.white)),
                    selected: _selectedTabIndex == 1,
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      setState(() {
                        _selectedTabIndex = 1; // Switch to "My Appointments" tab
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.white),
                    title: Text('Logout', style: TextStyle(color: Colors.white)),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ],
              ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text('Appointments'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tabButton('Book', 0),
              _tabButton('My Appointments', 1),
            ],
          ),
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildBookingView()
                : _buildMyAppointmentsView(),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String text, int index) {
    return TextButton(
      onPressed: () => setState(() => _selectedTabIndex = index),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _selectedTabIndex == index ? Colors.blueAccent : Colors.white70,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildBookingView() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.all(14.0),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyle(color: Colors.redAccent),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontWeight: FontWeight.bold),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
              decoration: BoxDecoration(
                color: Color(0xFF161B22),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekendStyle: TextStyle(color: Colors.redAccent),
            ),
            calendarFormat: CalendarFormat.month,
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final isConfirmed = confirmedDays.contains(DateTime(day.year, day.month, day.day));
                if (isConfirmed) {
                  return Container(
                    margin: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: Colors.green[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return null;
              },
              todayBuilder: (context, day, focusedDay) {
                final isConfirmed = confirmedDays.contains(DateTime(day.year, day.month, day.day));
                return Container(
                  margin: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: isConfirmed ? Colors.green[400] : Colors.orange,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isConfirmed ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
              selectedBuilder: (context, day, focusedDay) {
                final isConfirmed = confirmedDays.contains(DateTime(day.year, day.month, day.day));
                return Container(
                  margin: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: isConfirmed ? Colors.green[600] : Colors.blue,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 14.0, bottom: 6.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Select a doctor:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Center(child: Text('No doctors found.'));
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: ListTile(
                    leading: GestureDetector(
                      onTap: () {
                        _showDoctorFullProfileDialog(context, data);
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.grey.shade800,
                        backgroundImage: AssetImage('assets/default_doc_profile.png'),
                      ),
                    ),
                    title: Text(data['fullName'] ?? 'Doctor'),
                    subtitle: Text('${data['specialization'] ?? ""}  |  ${data['clinicName'] ?? ""}'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _selectedDay == null
                        ? null
                        : () => _openBookingForm(context, data, docs[i].id),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 20), // Give bottom padding so last card isn't cut off
      ],
    );
  }

  // Doctor profile dialog
  void _showDoctorFullProfileDialog(BuildContext context, Map<String, dynamic> doctorData) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doctorData['fullName'] ?? 'Doctor Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (doctorData['specialization'] != null)
              Text('Specialization: ${doctorData['specialization']}'),
            if (doctorData['clinicName'] != null)
              Text('Clinic: ${doctorData['clinicName']}'),
            if (doctorData['email'] != null)
              Text('Email: ${doctorData['email']}'),
            if (doctorData['experience'] != null)
              Text('Experience: ${doctorData['experience']}'),
            if (doctorData['phone'] != null)
              Text('Phone: ${doctorData['phone']}'),
            // Add more fields as needed
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Widget _buildMyAppointmentsView() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .orderBy('dateTime', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No appointments found.'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final DateTime dateTime = (data['dateTime'] as Timestamp).toDate();
            final String doctorName = data['doctorName'] ?? '';
            final String status = data['status'] ?? '';
            final String reason = data['reason'] ?? '';
            final String notes = data['notes'] ?? '';
            final String clinicName = data['clinicName'] ?? '';
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              elevation: 4,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade800,
                  backgroundImage: AssetImage('assets/default_doc_profile.png'),
                ),
                title: Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (clinicName.isNotEmpty)
                        Text('Clinic: $clinicName', style: const TextStyle(fontSize: 13)),
                      Text('Date: ${DateFormat('EEE, MMM d, yyyy').format(dateTime)}', style: const TextStyle(fontSize: 13)),
                      Text('Time: ${DateFormat('h:mm a').format(dateTime)}', style: const TextStyle(fontSize: 13)),
                      Text('Reason: $reason', style: const TextStyle(fontSize: 13)),
                      if (notes.isNotEmpty)
                        Text('Notes: $notes', style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            status == 'pending'
                                ? 'Pending'
                                : status == 'confirmed'
                                    ? 'Confirmed'
                                    : status == 'rejected'
                                        ? 'Rejected'
                                        : status,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: status == 'pending'
                                  ? Colors.orange
                                  : status == 'confirmed'
                                      ? Colors.green
                                      : status == 'rejected'
                                          ? Colors.red
                                          : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                isThreeLine: true,
                onTap: () {
                  _showAppointmentDetails(context, data, docs[i].reference);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showAppointmentDetails(BuildContext context, Map<String, dynamic> data, DocumentReference apptRef) {
    final DateTime dateTime = (data['dateTime'] as Timestamp).toDate();
    final String status = data['status'] ?? "";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Appointment Details'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Doctor: ${data['doctorName'] ?? ""}'),
                if ((data['clinicName'] ?? "").toString().isNotEmpty)
                  Text('Clinic: ${data['clinicName']}'),
                Text('Date: ${DateFormat('EEE, MMM d, yyyy').format(dateTime)}'),
                Text('Time: ${DateFormat('h:mm a').format(dateTime)}'),
                Text('Reason: ${data['reason'] ?? ""}'),
                Text('Status: $status'),
                if (data['notes'] != null && data['notes'].toString().isNotEmpty)
                  Text('Notes: ${data['notes']}'),
              ],
            ),
          ),
        ),
        actions: [
          if (status == 'rejected') ...[
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                await apptRef.delete();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rejected appointment removed.')));
              },
            ),
          ] else if (status == 'pending') ...[
            TextButton(
              child: const Text('Reject'),
              onPressed: () async {
                await apptRef.delete();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rescheduled appointment declined and removed.')));
              },
            ),
            TextButton(
              child: const Text('Accept'),
              onPressed: () async {
                await apptRef.update({'status': 'confirmed'});
                await _fetchConfirmedDays();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment confirmed!')));
              },
            ),
          ] else ...[
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ]
        ],
      ),
    );
  }

  void _openBookingForm(BuildContext context, Map<String, dynamic> doctorData, String doctorId) {
    final reasonController = TextEditingController();
    final notesController = TextEditingController();
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Book with ${doctorData['fullName'] ?? "Doctor"}'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Specialization: ${doctorData['specialization'] ?? ""}'),
                  Text('Clinic: ${doctorData['clinicName'] ?? ""}'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        selectedTime == null
                            ? 'Select Time'
                            : selectedTime!.format(context),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton(
                        child: const Text('Pick Time'),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) setStateDialog(() => selectedTime = picked);
                        },
                      ),
                    ],
                  ),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(labelText: 'Reason for visit'),
                  ),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Additional notes (optional)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              child: const Text('Book Appointment'),
              onPressed: () async {
                if (_selectedDay == null || selectedTime == null || reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                  return;
                }
                final patient = FirebaseAuth.instance.currentUser;
                if (patient == null) return;

                // Get patient name
                final patientDoc = await FirebaseFirestore.instance.collection('patients').doc(patient.uid).get();
                final patientName = patientDoc.data()?['name'] ?? '';

                final appointmentDateTime = DateTime(
                  _selectedDay!.year,
                  _selectedDay!.month,
                  _selectedDay!.day,
                  selectedTime!.hour,
                  selectedTime!.minute,
                );

                // Add appointment with status "pending"
                final appointmentRef = await FirebaseFirestore.instance.collection('appointments').add({
                  'doctorId': doctorId,
                  'doctorName': doctorData['fullName'] ?? '',
                  'clinicName': doctorData['clinicName'] ?? '',
                  'patientId': patient.uid,
                  'patientName': patientName,
                  'dateTime': appointmentDateTime,
                  'status': 'pending', // <-- pending initially
                  'reason': reasonController.text,
                  'notes': notesController.text,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                // Add in-app notification for doctor
                await FirebaseFirestore.instance
                    .collection('doctor_notifications')
                    .doc(doctorId)
                    .collection('notifications')
                    .add({
                  'type': 'appointment',
                  'message': 'New appointment from $patientName',
                  'appointmentId': appointmentRef.id,
                  'appointmentDateTime': appointmentDateTime,
                  'patientName': patientName,
                  'createdAt': FieldValue.serverTimestamp(),
                  'seen': false,
                });

                Navigator.pop(ctx);
                setState(() {
                  _selectedTabIndex = 1; // Switch to "My Appointments" tab after booking
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment booked!')));
              },
            ),
          ],
        ),
      ),
    );
  }
}