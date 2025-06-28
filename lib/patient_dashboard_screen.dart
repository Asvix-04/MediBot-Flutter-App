import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  String? name;
  String? email;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('patients').doc(user.uid).get();
    if (doc.exists) {
      setState(() {
        name = doc['name'] ?? 'Unknown';
        email = doc['email'] ?? 'unknown@example.com';
        isLoading = false;
      });
    }
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
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.person, size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text(name ?? '', style: const TextStyle(color: Colors.white)),
                        Text(email ?? '', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  ...["AI Chatbot", "Info Summarizer", "Appointments", "Medications", "Chat History", "My Profile", "Feedback"]
                      .map((item) => ListTile(title: Text(item), onTap: () {})),
                  const Divider(color: Colors.white12),
                  ListTile(title: const Text('Theme: Dark'), onTap: () {}),
                ],
              ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$name's Dashboard",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Welcome back, $name!\nHere's your health overview for today",
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _dashboardCard("Chat Sessions", "0\n0 total messages"),
                      _dashboardCard("Medications", "0\nNo medications"),
                      _dashboardCard("Health Score", "50\nNeeds attention"),
                      _dashboardCard("Health Records", "0\nNo records yet"),
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
                  Container(
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
                  ),
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
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(label),
    );
  }
}
