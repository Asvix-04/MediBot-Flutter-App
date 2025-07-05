import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'doctor_profile_screen.dart';
import 'feedback_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String fullName = '';
  String specialization = '';
  String clinicName = '';
  String email = '';
  String photoUrl = '';
  bool loadingDoctor = true;

  Set<DateTime> confirmedDays = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedDay = _focusedDay;
    _loadDoctorInfo();
    _fetchConfirmedDays();
  }

  Future<void> _loadDoctorInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { loadingDoctor = false; });
      return;
    }
    final snap = await FirebaseFirestore.instance.collection('doctors').doc(user.uid).get();
    if (snap.exists) {
      final data = snap.data()!;
      setState(() {
        fullName = data['fullName'] ?? '';
        specialization = data['specialization'] ?? '';
        clinicName = data['clinicName'] ?? '';
        email = data['email'] ?? '';
        photoUrl = data['photoUrl'] ?? '';
        loadingDoctor = false;
      });
    } else {
      setState(() { loadingDoctor = false; });
    }
  }

  Future<void> _fetchConfirmedDays() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: user.uid)
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
    if (loadingDoctor) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : const AssetImage('assets/default_doc_profile.png') as ImageProvider,
              radius: 18,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(width: 10),
            Text(
              fullName.isNotEmpty ? fullName : 'Doctor',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
              .collection('appointments')
              .where('doctorId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
              .where('status', isEqualTo: 'pending')
              .snapshots(),
            builder: (context, snapshot) {
              final hasPending = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      // Navigate to notification/appointment list page
                      _buildAppointmentsView();
                    },
                    tooltip: 'Notifications',
                  ),
                  if (hasPending)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Calendar'),
            Tab(text: 'Appointments'),
            Tab(text: 'Time Blocks'),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue[700]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : const AssetImage('assets/default_doc_profile.png') as ImageProvider,
                    radius: 24,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fullName.isNotEmpty ? fullName : 'Doctor',
                    style: const TextStyle(color: Colors.white, fontSize: 17),
                  ),
                  Text(
                    specialization.isNotEmpty ? specialization : '',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    clinicName.isNotEmpty ? clinicName : '',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Flexible(
                    child: Text(
                      email,
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Calendar'),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_note),
              title: const Text('Appointments'),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Time Blocks'),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('My Profile'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorProfileScreen(),
                  ),
                );
                _loadDoctorInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Feedback'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FeedbackScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarView(),
          _buildAppointmentsView(),
          _buildTimeBlockView(),
        ],
      ),
    );
  }

  /// FIXED: Prevent overflow by making calendar view scrollable and appointment list bounded.
  Widget _buildCalendarView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
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
                    color: isConfirmed ? Colors.green[400] : Colors.blue[200],
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
          const SizedBox(height: 10),
          Center(
            child: Column(
              children: [
                Text(
                  "Welcome, ${fullName.isNotEmpty ? fullName : 'Doctor'}!",
                  style: TextStyle(fontSize: 18, color: Colors.blue[800], fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                _selectedDay == null
                    ? const SizedBox.shrink()
                    : Text(
                        'Appointments on ${DateFormat.yMMMd().format(_selectedDay!)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
              ],
            ),
          ),
          if (_selectedDay != null)
            SizedBox(
              height: 350, // Set a fixed height for the appointments list to prevent overflow
              child: _buildFirestoreAppointmentListForDay(),
            ),
        ],
      ),
    );
  }

  Widget _buildFirestoreAppointmentListForDay() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedDay == null) {
      return const Center(child: Text('No appointments for this day'));
    }
    final dayStart = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, 0, 0, 0);
    final dayEnd = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, 23, 59, 59);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: user.uid)
          .where('dateTime', isGreaterThanOrEqualTo: dayStart)
          .where('dateTime', isLessThanOrEqualTo: dayEnd)
          .where('status', isNotEqualTo: 'rejected')
          .orderBy('dateTime')
          .orderBy('status')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No appointments for this day'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, index) {
            final appt = docs[index].data() as Map<String, dynamic>;
            final dateTime = (appt['dateTime'] as Timestamp).toDate();
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: ListTile(
                leading: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('patients').doc(appt['patientId']).get(),
                  builder: (context, snapshot) {
                    String imageUrl = 'assets/default_profile.png';
                    Map<String, dynamic>? data;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      data = snapshot.data!.data() as Map<String, dynamic>;
                      if (data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty) {
                        imageUrl = data['photoUrl'];
                      }
                    }
                    return GestureDetector(
                      onTap: () {
                        if (data != null) {
                          _showPatientProfileDialog(context, appt['patientId']);
                        }
                      },
                      child: CircleAvatar(
                        backgroundImage: imageUrl.startsWith('http')
                          ? NetworkImage(imageUrl)
                          : AssetImage(imageUrl) as ImageProvider,
                        backgroundColor: Colors.grey[300],
                      ),
                    );
                  },
                ),
                title: Text('${appt['patientName']} - ${DateFormat.jm().format(dateTime)}'),
                subtitle: Text(appt['status'] ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showFirestoreAppointmentDetails(appt, docs[index].reference);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAppointmentsView() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: user.uid)
          .where('status', isNotEqualTo: 'rejected')
          .orderBy('dateTime')
          .orderBy('status')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No appointments found.'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, index) {
            final appt = docs[index].data() as Map<String, dynamic>;
            final dateTime = (appt['dateTime'] as Timestamp).toDate();
            return Card(
              child: ListTile(
                leading: FutureBuilder<DocumentSnapshot>(
  future: FirebaseFirestore.instance.collection('patients').doc(appt['patientId']).get(),
  builder: (context, snapshot) {
    String imageUrl = 'assets/default_profile.png';
    Map<String, dynamic>? data;

    if (snapshot.hasData && snapshot.data!.exists) {
      data = snapshot.data!.data() as Map<String, dynamic>;
      if (data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty) {
        imageUrl = data['photoUrl'];
      }
    }

    return GestureDetector(
      onTap: () {
        if (data != null) {
          _showPatientProfileDialog(context, appt['patientId']);
        }
      },
      child: CircleAvatar(
        backgroundImage: imageUrl.startsWith('http')
            ? NetworkImage(imageUrl)
            : AssetImage(imageUrl) as ImageProvider,
        backgroundColor: Colors.grey[300],
      ),
    );
  },
),

                title: Text('${appt['patientName']} - ${DateFormat.jm().format(dateTime)}'),
                subtitle: Text('${DateFormat.yMMMd().format(dateTime)} - ${appt['status'] ?? ''}'),
                trailing: const Icon(Icons.more_vert),
                onTap: () => _showFirestoreAppointmentDetails(appt, docs[index].reference),
              ),
            );
          },
        );
      },
    );
  }

  // ---- TIME BLOCK MANAGEMENT ----
  Widget _buildTimeBlockView() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not logged in'));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Time Block'),
            onPressed: () => _showAddTimeBlockDialog(context, user.uid),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildTimeBlockList(user.uid)),
        ],
      ),
    );
  }

  void _showAddTimeBlockDialog(BuildContext context, String doctorId) {
    DateTime? start, end;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Time Block'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(start == null
                      ? 'Select Start'
                      : DateFormat('yyyy-MM-dd HH:mm').format(start!)),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          start = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(end == null
                      ? 'Select End'
                      : DateFormat('yyyy-MM-dd HH:mm').format(end!)),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: start ?? DateTime.now(),
                      firstDate: start ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          end = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Reason (optional)'),
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
            child: const Text('Save'),
            onPressed: () async {
              if (start == null || end == null || start!.isAfter(end!)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select valid start and end times.'))
                );
                return;
              }
              await FirebaseFirestore.instance
                  .collection('doctors')
                  .doc(doctorId)
                  .collection('time_blocks')
                  .add({
                'start': Timestamp.fromDate(start!),
                'end': Timestamp.fromDate(end!),
                'reason': reasonController.text,
              });
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBlockList(String doctorId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .collection('time_blocks')
          .orderBy('start')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No time blocks set.'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final start = (data['start'] as Timestamp).toDate();
            final end = (data['end'] as Timestamp).toDate();
            final reason = data['reason'] ?? '';
            return Card(
              child: ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: Text('${DateFormat.yMMMd().add_jm().format(start)} - ${DateFormat.yMMMd().add_jm().format(end)}'),
                subtitle: reason.isNotEmpty ? Text(reason) : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await docs[index].reference.delete();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Time block deleted.')));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
  // ---- END TIME BLOCK MANAGEMENT ----

  String _formatDob(dynamic dob) {
    if (dob == null) return '';
    if (dob is Timestamp) {
      final dt = dob.toDate();
      return DateFormat('yyyy-MM-dd').format(dt);
    } else if (dob is DateTime) {
      return DateFormat('yyyy-MM-dd').format(dob);
    } else if (dob is String) {
      return dob;
    } else {
      return dob.toString();
    }
  }

  void _showPatientProfileDialog(BuildContext context, String patientId) async {
    final doc = await FirebaseFirestore.instance.collection('patients').doc(patientId).get();
    if (!doc.exists) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Patient Profile'),
          content: const Text('No profile found.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
        ),
      );
      return;
    }
    final data = doc.data()!;
    final String name = data['name'] ?? 'Patient';
    final String email = data['email'] ?? '';
    final String phone = data['phone'] ?? '';
    final String gender = data['gender'] ?? '';
    final String dob = _formatDob(data['dob']);
    final String photoUrl = data['photoUrl'] ?? '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : const AssetImage('assets/default_Profile.png') as ImageProvider,
              radius: 24,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email.isNotEmpty) Text('Email: $email'),
            if (phone.isNotEmpty) Text('Phone: $phone'),
            if (gender.isNotEmpty) Text('Gender: $gender'),
            if (dob.isNotEmpty) Text('DOB: $dob'),
            // Add any other fields you store for patients here
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showFirestoreAppointmentDetails(Map<String, dynamic> appt, DocumentReference apptRef) async {
    final dateTime = (appt['dateTime'] as Timestamp).toDate();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Appointment with ${appt['patientName']}'),
        content: Text(
          'Date: ${DateFormat.yMMMd().format(dateTime)}\n'
          'Time: ${DateFormat.jm().format(dateTime)}\n'
          'Status: ${appt['status'] ?? ''}\n'
          'Reason: ${appt['reason'] ?? ''}\n'
          'Notes: ${appt['notes'] ?? ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (appt['status'] == 'pending') ...[
            TextButton(
              onPressed: () async {
                await apptRef.update({'status': 'confirmed'});
                Navigator.pop(context);
                await _fetchConfirmedDays();
              },
              child: const Text('Confirm'),
            ),
            TextButton(
              onPressed: () async {
                await apptRef.update({'status': 'rejected'});
                Navigator.pop(context);
                await _fetchConfirmedDays();
              },
              child: const Text('Reject'),
            ),
            TextButton(
              onPressed: () async {
                DateTime? newDate = await showDatePicker(
                  context: context,
                  initialDate: dateTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (newDate != null) {
                  TimeOfDay? newTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(dateTime),
                  );
                  if (newTime != null) {
                    final newDateTime = DateTime(
                      newDate.year, newDate.month, newDate.day,
                      newTime.hour, newTime.minute,
                    );
                    await apptRef.update({
                      'dateTime': Timestamp.fromDate(newDateTime),
                      'status': 'pending',
                    });
                  }
                }
                Navigator.pop(context);
                await _fetchConfirmedDays();
              },
              child: const Text('Reschedule'),
            ),
          ]
        ],
      ),
    );
    await _fetchConfirmedDays();
  }
}