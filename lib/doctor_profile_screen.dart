import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  bool isEditing = false;
  bool isLoading = true;
  bool isSaving = false;

  // Profile fields
  String fullName = "";
  String specialization = "";
  String clinicName = "";
  String location = "";
  String email = "";
  String phone = "";
  String gender = "";
  String dob = ""; // Date of Birth
  String regNumber = "";
  String experience = "";
  String qualification = "";
  String consultationFee = "";
  String available = "";
  String languages = "";
  String bio = "";

  // For editing
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    for (var field in [
      'fullName', 'specialization', 'clinicName', 'location', 'email', 'phone', 'gender', 'dob',
      'regNumber', 'experience', 'qualification', 'consultationFee', 'available', 'languages', 'bio'
    ]) {
      _controllers[field] = TextEditingController();
    }
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance.collection('doctors').doc(user.uid).get();
    if (snap.exists) {
      final data = snap.data()!;
      setState(() {
        fullName        = data['fullName'] ?? '';
        specialization  = data['specialization'] ?? '';
        clinicName      = data['clinicName'] ?? '';
        location        = data['location'] ?? '';
        email           = data['email'] ?? '';
        phone           = data['phone'] ?? '';
        gender          = data['gender'] ?? '';
        dob             = data['dob'] ?? '';
        regNumber       = data['registrationNumber'] ?? '';
        experience      = data['experience'] ?? '';
        qualification   = data['qualification'] ?? '';
        consultationFee = data['consultationFee'] ?? '';
        available       = data['available'] ?? '';
        languages       = data['languages'] ?? '';
        bio             = data['bio'] ?? '';

        // Set controllers for editing
        _controllers['fullName']!.text        = fullName;
        _controllers['specialization']!.text  = specialization;
        _controllers['clinicName']!.text      = clinicName;
        _controllers['location']!.text        = location;
        _controllers['email']!.text           = email;
        _controllers['phone']!.text           = phone;
        _controllers['gender']!.text          = gender;
        _controllers['dob']!.text             = dob;
        _controllers['regNumber']!.text       = regNumber;
        _controllers['experience']!.text      = experience;
        _controllers['qualification']!.text   = qualification;
        _controllers['consultationFee']!.text = consultationFee;
        _controllers['available']!.text       = available;
        _controllers['languages']!.text       = languages;
        _controllers['bio']!.text             = bio;

        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('doctors').doc(user.uid).update({
      'fullName': _controllers['fullName']!.text.trim(),
      'specialization': _controllers['specialization']!.text.trim(),
      'clinicName': _controllers['clinicName']!.text.trim(),
      'location': _controllers['location']!.text.trim(),
      'email': _controllers['email']!.text.trim(),
      'phone': _controllers['phone']!.text.trim(),
      'gender': _controllers['gender']!.text.trim(),
      'dob': _controllers['dob']!.text.trim(),
      'registrationNumber': _controllers['regNumber']!.text.trim(),
      'experience': _controllers['experience']!.text.trim(),
      'qualification': _controllers['qualification']!.text.trim(),
      'consultationFee': _controllers['consultationFee']!.text.trim(),
      'available': _controllers['available']!.text.trim(),
      'languages': _controllers['languages']!.text.trim(),
      'bio': _controllers['bio']!.text.trim(),
    });
    setState(() {
      isEditing = false;
      isSaving = false;
    });
    _fetchProfile();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated")));
  }

  void _showChangePasswordDialog() {
    final _pwController = TextEditingController();
    final _newPwController = TextEditingController();
    final _formKeyPw = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: _formKeyPw,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _pwController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _newPwController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 6) return 'Min 6 chars';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (!_formKeyPw.currentState!.validate()) return;
              try {
                final user = FirebaseAuth.instance.currentUser;
                final cred = EmailAuthProvider.credential(
                  email: email,
                  password: _pwController.text,
                );
                await user?.reauthenticateWithCredential(cred);
                await user?.updatePassword(_newPwController.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password changed successfully.")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx, false)),
          TextButton(child: const Text('Delete'), onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        await FirebaseFirestore.instance.collection('doctors').doc(user!.uid).delete();
        await user.delete();
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => isEditing = true),
              tooltip: "Edit Profile",
            ),
          if (isEditing)
            IconButton(
              icon: isSaving ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Icon(Icons.save),
              onPressed: isSaving ? null : _saveProfile,
              tooltip: "Save Profile",
            ),
        ],
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
                    radius: 32,
                    backgroundImage: AssetImage('assets/default_doc_profile.png'),
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    fullName.isNotEmpty ? fullName : 'Doctor',
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    specialization.isNotEmpty ? specialization : '',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              onTap: () {
                Navigator.pop(context);
                _showChangePasswordDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Account'),
              onTap: () async {
                Navigator.pop(context);
                await _deleteAccount();
              },
            ),
          ],
        ),
      ),
      body: isEditing ? _buildEditForm() : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: Profile Avatar and Headline
          Row(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundImage: AssetImage('assets/default_doc_profile.png'),
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    if (specialization.isNotEmpty) Text(specialization, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    if (clinicName.isNotEmpty || location.isNotEmpty)
                      Text(
                        [clinicName, location].where((e) => e.isNotEmpty).join(", "),
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Personal Info Section
          sectionHeader("Personal Info"),
          profileRow("Email", email),
          profileRow("Phone", phone),
          profileRow("Gender", gender),
          profileRow("DOB", dob),
          const SizedBox(height: 12),
          // Professional Info Section
          sectionHeader("Professional Info"),
          profileRow("Registration No.", regNumber),
          profileRow("Specialization", specialization),
          profileRow("Experience", experience.isNotEmpty ? "$experience years" : ""),
          profileRow("Qualifications", qualification),
          profileRow("Consultation Fee", consultationFee),
          profileRow("Available", available),
          profileRow("Languages", languages),
          const SizedBox(height: 12),
          // About
          sectionHeader("About/Bio"),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(bio.isNotEmpty ? bio : "-", style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget sectionHeader(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.blue)),
      );

  Widget profileRow(String label, String value) => value.isEmpty
      ? const SizedBox()
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 145, child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.w500))),
              Expanded(child: Text(value)),
            ],
          ),
        );

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundImage: AssetImage('assets/default_doc_profile.png'),
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _buildTextField("Full Name", "fullName", required: true),
                ),
              ],
            ),
            const SizedBox(height: 14),
            sectionHeader("Personal Info"),
            _buildTextField("Email", "email", inputType: TextInputType.emailAddress, required: true),
            _buildTextField("Phone", "phone"),
            _buildTextField("Gender", "gender"),
            _buildTextField("DOB", "dob"),
            sectionHeader("Professional Info"),
            _buildTextField("Registration No.", "regNumber", required: true),
            _buildTextField("Specialization", "specialization", required: true),
            _buildTextField("Experience (years)", "experience", inputType: TextInputType.number),
            _buildTextField("Qualifications", "qualification"),
            _buildTextField("Consultation Fee", "consultationFee"),
            _buildTextField("Available", "available"),
            _buildTextField("Languages", "languages"),
            sectionHeader("About/Bio"),
            _buildTextField("About/Bio", "bio", maxLines: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String key,
      {bool required = false, TextInputType? inputType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: TextFormField(
        controller: _controllers[key],
        validator: required ? (v) => v == null || v.isEmpty ? "Required" : null : null,
        keyboardType: inputType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}