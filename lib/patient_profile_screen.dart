import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Add this import for your CloudinaryUploader (adjust the path as needed)
import 'package:medibot/utils/cloudinary_uploader.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();

  DateTime? _dob;
  String? _gender;
  String? _bloodType;

  // Profile photo
  String photoUrl = "";

  // Toggles
  bool medReminder = false;
  bool apptReminder = false;
  bool healthTips = false;
  bool emailNotif = false;
  bool pushNotif = false;
  bool shareData = false;
  bool saveChat = false;

  User? get user => _auth.currentUser;

  static const int maxImageSizeInBytes = 5 * 1024 * 1024; // 5MB

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  String _capitalize(String? s) =>
      (s == null || s.isEmpty) ? '' : s[0].toUpperCase() + s.substring(1).toLowerCase();

  Future<void> _loadProfile() async {
    if (user == null) return;
    final doc = await _firestore.collection('patients').doc(user!.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _emergencyNameController.text = data['emergencyName'] ?? '';
        _emergencyPhoneController.text = data['emergencyPhone'] ?? '';
        _emergencyRelationController.text = data['emergencyRelation'] ?? '';
        _allergiesController.text = data['allergies'] ?? '';
        _conditionsController.text = data['conditions'] ?? '';
        photoUrl = data['photoUrl'] ?? '';

        // Robust DOB parsing
        final dobValue = data['dob'];
        if (dobValue is Timestamp) {
          _dob = dobValue.toDate();
        } else if (dobValue is String) {
          try {
            _dob = DateFormat('dd/MM/yyyy').parseStrict(dobValue);
          } catch (_) {
            try {
              _dob = DateFormat('yyyy-MM-dd').parseStrict(dobValue);
            } catch (_) {
              _dob = null;
            }
          }
        } else {
          _dob = null;
        }

        // Gender robust fix
        final genderValue = data['gender'];
        if (genderValue != null) {
          _gender = _capitalize(genderValue);
        } else {
          _gender = null;
        }

        _bloodType = data['bloodType'];

        medReminder = data['medReminder'] ?? false;
        apptReminder = data['apptReminder'] ?? false;
        healthTips = data['healthTips'] ?? false;
        emailNotif = data['emailNotif'] ?? false;
        pushNotif = data['pushNotif'] ?? false;
        shareData = data['shareData'] ?? false;
        saveChat = data['saveChat'] ?? false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      await _firestore.collection('patients').doc(user!.uid).set({
        'name': _nameController.text,
        'email': user!.email,
        'dob': _dob,
        'gender': _gender,
        'phone': _phoneController.text,
        'emergencyName': _emergencyNameController.text,
        'emergencyPhone': _emergencyPhoneController.text,
        'emergencyRelation': _emergencyRelationController.text,
        'allergies': _allergiesController.text,
        'conditions': _conditionsController.text,
        'bloodType': _bloodType,
        'photoUrl': photoUrl,
        'medReminder': medReminder,
        'apptReminder': apptReminder,
        'healthTips': healthTips,
        'emailNotif': emailNotif,
        'pushNotif': pushNotif,
        'shareData': shareData,
        'saveChat': saveChat,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
    }
  }

  Future<void> _pickDOB() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _changeProfilePhoto() async {
    final url = await CloudinaryUploader.uploadAndSaveProfilePhoto(role: "patient");
    if (url != null) {
      setState(() => photoUrl = url);
    }
  }

  Future<void> _exportData() async {
    if (user == null) return;
    final doc = await _firestore.collection('patients').doc(user!.uid).get();
    if (doc.exists) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          title: const Text('Export Data', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Text(doc.data().toString(), style: const TextStyle(color: Colors.white70)),
          ),
          actions: [
            TextButton(
              child: const Text('Close', style: TextStyle(color: Colors.green)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _clearData() async {
    if (user == null) return;
    await _firestore.collection('patients').doc(user!.uid).delete();
    setState(() {
      _nameController.clear();
      _phoneController.clear();
      _emergencyNameController.clear();
      _emergencyPhoneController.clear();
      _emergencyRelationController.clear();
      _allergiesController.clear();
      _conditionsController.clear();
      _gender = null;
      _bloodType = null;
      _dob = null;
      photoUrl = "";
      medReminder = false;
      apptReminder = false;
      healthTips = false;
      emailNotif = false;
      pushNotif = false;
      shareData = false;
      saveChat = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile data cleared!')),
    );
  }

  // --- DELETE ACCOUNT LOGIC STARTS HERE ---

  Future<AuthCredential?> _showReauthDialog() async {
    String email = user?.email ?? '';
    String password = '';
    return await showDialog<AuthCredential>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verify Your Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your password to verify your identity before deleting your account.'),
              TextFormField(
                initialValue: email,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                onChanged: (value) => password = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Continue'),
              onPressed: () {
                if (email.isNotEmpty && password.isNotEmpty) {
                  final cred = EmailAuthProvider.credential(email: email, password: password);
                  Navigator.pop(context, cred);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    if (user == null) return;

    // Prompt for re-authentication first
    final credential = await _showReauthDialog();
    if (credential == null) return;

    try {
      // Reauthenticate
      await user!.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Re-authentication failed: ${e.message}')),
      );
      return;
    }

    final uid = user!.uid;
    final patientRef = _firestore.collection('patients').doc(uid);

    // 1. Delete all subcollections (chats, medications, health_records, etc.)
    final List<String> subcollections = [
      'chats',
      'medications',
      'health_records',
      // Add other subcollections here if needed
    ];
    for (final coll in subcollections) {
      final snapshot = await patientRef.collection(coll).get();
      for (final doc in snapshot.docs) {
        // If this subcollection has its own subcollections, handle them recursively here
        // For example, for chats > messages:
        if (coll == 'chats') {
          final messages = await doc.reference.collection('messages').get();
          for (final msg in messages.docs) {
            await msg.reference.delete();
          }
        }
        await doc.reference.delete();
      }
    }

    // 2. Delete the patient document
    await patientRef.delete();

    // 3. Delete the Firebase Auth user
    try {
      await user!.delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account deletion failed: $e')),
      );
      return;
    }

    // 4. Navigate user to login or home
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully!')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  // --- DELETE ACCOUNT LOGIC ENDS HERE ---

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) =>
      SwitchListTile(
        title: Text(label, style: const TextStyle(color: Colors.white)),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
      );

  Widget _buildProfileAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 46,
          backgroundColor: Colors.grey.shade800,
          backgroundImage: photoUrl.isNotEmpty
              ? NetworkImage(photoUrl)
              : const AssetImage('assets/default_profile.png') as ImageProvider,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: _changeProfilePhoto,
            child: CircleAvatar(
              backgroundColor: Colors.green,
              radius: 15,
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget drawerHeader = DrawerHeader(
      decoration: const BoxDecoration(color: Color(0xFF0D1117)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade800,
            backgroundImage: photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : const AssetImage('assets/default_profile.png') as ImageProvider,
          ),
          const SizedBox(height: 12),
          Text(
            _nameController.text.isNotEmpty ? _nameController.text : 'User',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            user?.email ?? 'unknown@example.com',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Profile Settings'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.green),
            tooltip: 'Export Data',
            onPressed: _exportData,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            tooltip: 'Clear All Data',
            onPressed: () async {
              final confirm = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF161B22),
                  title: const Text('Clear Profile Data', style: TextStyle(color: Colors.white)),
                  content: const Text('Are you sure you want to clear all your profile data?', style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                      child: const Text('Cancel', style: TextStyle(color: Colors.green)),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      child: const Text('Yes, Clear', style: TextStyle(color: Colors.redAccent)),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );
              if (confirm == true) _clearData();
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF161B22),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            drawerHeader,
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
                  Navigator.pop(context);
                  if (item == "My Profile") {
                    // Already here, no navigation needed
                  }
                  // TODO: Add navigation for other items if needed
                },
              );
            }),
            const Divider(color: Colors.white12),
            ListTile(
              title: const Text('Theme: Dark'),
              onTap: () {},
            ),
            // --- DELETE ACCOUNT BUTTON IN SIDEBAR ---
            ListTile(
              title: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              onTap: () async {
                final confirm = await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF161B22),
                    title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent)),
                    content: const Text(
                      'This will permanently delete your account and all data. Are you sure?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Cancel', style: TextStyle(color: Colors.green)),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      TextButton(
                        child: const Text('Yes, Delete', style: TextStyle(color: Colors.redAccent)),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ],
                  ),
                );
                if (confirm == true) _deleteAccount();
              },
            ),
            // -----------------------------------------
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildProfileAvatar()),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Display Name'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                initialValue: user?.email,
                style: const TextStyle(color: Colors.white54),
                decoration: const InputDecoration(labelText: 'Email Address'),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(
                  _dob != null ? DateFormat('dd-MM-yyyy').format(_dob!) : 'Select DOB',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.white),
                onTap: _pickDOB,
              ),
              DropdownButtonFormField<String>(
                value: _gender,
                style: const TextStyle(color: Colors.white),
                dropdownColor: Colors.black,
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white24),
              const Text('Emergency Contact', style: TextStyle(color: Colors.white)),
              TextFormField(
                controller: _emergencyNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Contact Name'),
              ),
              TextFormField(
                controller: _emergencyPhoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Contact Phone'),
              ),
              TextFormField(
                controller: _emergencyRelationController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Relationship'),
              ),
              const Divider(color: Colors.white24),
              const Text('Medical Information', style: TextStyle(color: Colors.white)),
              TextFormField(
                controller: _allergiesController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Allergies'),
              ),
              TextFormField(
                controller: _conditionsController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Medical Conditions'),
              ),
              DropdownButtonFormField<String>(
                value: _bloodType,
                style: const TextStyle(color: Colors.white),
                dropdownColor: Colors.black,
                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => setState(() => _bloodType = v),
                decoration: const InputDecoration(labelText: 'Blood Type'),
              ),
              const Divider(color: Colors.white24),
              const Text('Notifications', style: TextStyle(color: Colors.white)),
              _buildSwitch('Medication Reminders', medReminder, (v) => setState(() => medReminder = v)),
              _buildSwitch('Appointment Reminders', apptReminder, (v) => setState(() => apptReminder = v)),
              _buildSwitch('Health Tips', healthTips, (v) => setState(() => healthTips = v)),
              _buildSwitch('Email Notifications', emailNotif, (v) => setState(() => emailNotif = v)),
              _buildSwitch('Push Notifications', pushNotif, (v) => setState(() => pushNotif = v)),
              const Divider(color: Colors.white24),
              const Text('Privacy & Security', style: TextStyle(color: Colors.white)),
              _buildSwitch('Share Data for Research', shareData, (v) => setState(() => shareData = v)),
              _buildSwitch('Save Conversations', saveChat, (v) => setState(() => saveChat = v)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}