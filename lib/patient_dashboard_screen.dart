import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient_profile_screen.dart';
import 'patient_appointments_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  String? name;
  String? email;
  String? photoUrl;
  bool isLoading = true;

  // Dynamic dashboard data
  int chatSessions = 0;
  int totalMessages = 0;
  int medications = 0;
  int healthScore = 50;
  int healthRecords = 0;
  List<Map<String, dynamic>> recentActivity = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Load user info
    final doc = await FirebaseFirestore.instance.collection('patients').doc(user.uid).get();
    if (doc.exists) {
      name = doc['name'] ?? 'Unknown';
      email = doc['email'] ?? 'unknown@example.com';
      healthScore = doc.data()?['healthScore'] ?? 50;
      photoUrl = doc['photoUrl'] ?? null;
    }

    final patientRef = FirebaseFirestore.instance.collection('patients').doc(user.uid);

    // Load chats (sessions & messages)
    final chatsQuery = await patientRef.collection('chats').get();
    chatSessions = chatsQuery.docs.length;

    // Efficient message counting (in parallel)
    final messageFutures = chatsQuery.docs.map((chatDoc) async {
      final messages = await chatDoc.reference.collection('messages').get();
      return messages.docs.length;
    }).toList();
    final messageCounts = await Future.wait(messageFutures);
    totalMessages = messageCounts.fold(0, (a, b) => a + b);

    // Load medications
    final medsQuery = await patientRef.collection('medications').get();
    medications = medsQuery.docs.length;

    // Load health records
    final recordsQuery = await patientRef.collection('health_records').get();
    healthRecords = recordsQuery.docs.length;

    // Recent Activity: last 5 messages from all chats
    List<Map<String, dynamic>> recent = [];
    for (var chatDoc in chatsQuery.docs) {
      final messages = await chatDoc.reference.collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      for (var msg in messages.docs) {
        recent.add({
          'chatId': chatDoc.id,
          'text': msg.data()['text'] ?? '',
          'timestamp': msg.data()['timestamp'],
        });
      }
    }
    // Sort and keep only last 5
    recent.sort((a, b) {
      final aTime = a['timestamp'] is DateTime
          ? a['timestamp']
          : (a['timestamp'] is Timestamp ? (a['timestamp'] as Timestamp).toDate() : DateTime.fromMillisecondsSinceEpoch(0));
      final bTime = b['timestamp'] is DateTime
          ? b['timestamp']
          : (b['timestamp'] is Timestamp ? (b['timestamp'] as Timestamp).toDate() : DateTime.fromMillisecondsSinceEpoch(0));
      return bTime.compareTo(aTime);
    });
    if (recent.length > 5) recent = recent.sublist(0, 5);

    setState(() {
      recentActivity = recent;
      isLoading = false;
    });
  }

  Widget _buildDashboardAvatar() {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 46,
        backgroundColor: Colors.grey.shade800,
        backgroundImage: NetworkImage(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 46,
      backgroundColor: Colors.grey.shade800,
      backgroundImage: const AssetImage('assets/default_profile.png'),
    );
  }

  Widget _buildDrawerAvatar() {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade800,
        backgroundImage: NetworkImage(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey.shade800,
      backgroundImage: const AssetImage('assets/default_profile.png'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: Row(
          children: [
            Image.asset('assets/images/logo_circular.png', height: 32),
            const SizedBox(width: 12),
            const Text(
              'MediBot',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            tooltip: 'Sign Out',
          )
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF161B22),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: Color(0xFF0D1117)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDrawerAvatar(),
                        const SizedBox(height: 12),
                        Text(name ?? '', style: const TextStyle(color: Colors.white)),
                        Text(email ?? '', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  ...[
                    "AI Chatbot",
                    "Info Summarizer",
                    "Appointments",
                    "Medications",
                    "Chat History",
                    "My Profile",
                    "Feedback"
                  ].map((item) {
                    return ListTile(
                      title: Text(item),
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        if (item == "My Profile") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PatientProfileScreen()),
                          ).then((_) => _loadAllData());
                        } else if (item == "Appointments") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PatientAppointmentsScreen()),
                          );
                        }
                        // Add navigation for other items if needed
                      },
                    );
                  }),
                  const Divider(color: Colors.white12),
                  ListTile(title: const Text('Theme: Dark'), onTap: () {}),
                ],
              ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Center avatar, title, and welcome line
                    Center(
                      child: Column(
                        children: [
                          _buildDashboardAvatar(),
                          const SizedBox(height: 16),
                          Text(
                            "${name ?? 'User'}'s Dashboard",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Welcome back, ${name ?? 'User'}!\nHere's your health overview for today",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _dashboardCard("Chat Sessions", "$chatSessions\n$totalMessages total messages"),
                        _dashboardCard("Medications", "$medications\n${medications == 0 ? "No medications" : "$medications active"}"),
                        _dashboardCard("Health Score", "$healthScore\n${healthScore < 70 ? "Needs attention" : "Good"}"),
                        _dashboardCard("Health Records", "$healthRecords\n${healthRecords == 0 ? "No records yet" : "$healthRecords records"}"),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _quickActionButton("Start New Chat"),
                        _quickActionButton("Add Medication"),
                        _quickActionButton("Search Medical Info"),
                        _quickActionButton("Appointments Record"),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _recentActivityWidget(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text("Start Your First Chat"),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _dashboardCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _quickActionButton(String label) {
    return ElevatedButton(
      onPressed: () {
        if (label == "Appointments Record") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PatientAppointmentsScreen()),
          );
        }
        // You can add logic for other quick actions as needed
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(label),
    );
  }

  Widget _recentActivityWidget() {
    if (recentActivity.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("No recent activity", style: TextStyle(color: Colors.white70)),
            SizedBox(height: 8),
            Text("Start a conversation to see your activity here",
                style: TextStyle(fontSize: 13, color: Colors.white38)),
          ],
        ),
      );
    }
    return Column(
      children: recentActivity.map((activity) {
        final date = activity['timestamp'] != null
            ? (activity['timestamp'] is DateTime
                ? activity['timestamp']
                : (activity['timestamp'] is Timestamp
                    ? (activity['timestamp'] as Timestamp).toDate()
                    : null))
            : null;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          leading: const Icon(Icons.message, color: Colors.blueAccent),
          title: Text(
            activity['text'] ?? 'Message',
            style: const TextStyle(color: Colors.white70),
          ),
          subtitle: date != null
              ? Text(
                  '${date.toLocal()}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                )
              : null,
        );
      }).toList(),
    );
  }
}