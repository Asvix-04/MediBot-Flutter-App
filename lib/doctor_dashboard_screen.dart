import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final List<Map<String, dynamic>> _appointments = [
    {
      'date': DateTime.now(),
      'time': '10:00 AM',
      'patient': 'John Doe',
      'status': 'Upcoming',
    },
    {
      'date': DateTime.now().subtract(Duration(days: 1)),
      'time': '2:00 PM',
      'patient': 'Alice Smith',
      'status': 'Completed',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Calendar'),
            Tab(text: 'Appointments'),
            Tab(text: 'Time Blocks'),
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

  Widget _buildCalendarView() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarFormat: CalendarFormat.month,
        ),
        const SizedBox(height: 10),
        Text(
          'Appointments on ${DateFormat.yMMMd().format(_selectedDay!)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(child: _buildAppointmentListForDay()),
      ],
    );
  }

  Widget _buildAppointmentListForDay() {
    final todayAppointments = _appointments.where((appt) =>
        isSameDay(appt['date'], _selectedDay)).toList();

    if (todayAppointments.isEmpty) {
      return const Center(child: Text('No appointments for this day'));
    }

    return ListView.builder(
      itemCount: todayAppointments.length,
      itemBuilder: (_, index) {
        final appt = todayAppointments[index];
        return ListTile(
          title: Text('${appt['patient']} - ${appt['time']}'),
          subtitle: Text(appt['status']),
          trailing: Icon(Icons.chevron_right),
          onTap: () {
            _showAppointmentDetails(appt);
          },
        );
      },
    );
  }

  Widget _buildAppointmentsView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _appointments.map((appt) {
        return Card(
          child: ListTile(
            title: Text('${appt['patient']} - ${appt['time']}'),
            subtitle: Text('${DateFormat.yMMMd().format(appt['date'])} - ${appt['status']}'),
            trailing: Icon(Icons.more_vert),
            onTap: () => _showAppointmentDetails(appt),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeBlockView() {
    return Center(
      child: Text('Time Block Management Coming Soon'),
    );
  }

  void _showAppointmentDetails(Map<String, dynamic> appt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Appointment with ${appt['patient']}'),
        content: Text(
          'Date: ${DateFormat.yMMMd().format(appt['date'])}\n'
          'Time: ${appt['time']}\n'
          'Status: ${appt['status']}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Confirm'),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Reschedule'),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}