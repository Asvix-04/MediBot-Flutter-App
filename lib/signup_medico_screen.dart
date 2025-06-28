import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'home_screen.dart';

class MedicoSignUpScreen extends StatefulWidget {
  const MedicoSignUpScreen({super.key});
  @override
  State<MedicoSignUpScreen> createState() => _MedicoSignUpScreenState();
}

class _MedicoSignUpScreenState extends State<MedicoSignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _specializationController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _locationController = TextEditingController();

  bool agreeToTerms = false;
  bool isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _regNumberController.dispose();
    _specializationController.dispose();
    _clinicNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _signUpDoctor() async {
    if (!_formKey.currentState!.validate()) return;
    if (!agreeToTerms) {
      _showSnack("❗ You must agree to the terms");
      return;
    }

    setState(() => isLoading = true);
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = credential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection('doctors').doc(user.uid).set({
          'uid': user.uid,
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'registrationNumber': _regNumberController.text.trim(),
          'specialization': _specializationController.text.trim(),
          'clinicName': _clinicNameController.text.trim(),
          'location': _locationController.text.trim(),
          'role': 'doctor',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await user.sendEmailVerification();
      }

      _showVerificationDialog();

      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      });
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? "❌ Signup failed");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text("📧 Verify Your Email", style: TextStyle(color: Colors.white)),
        content: const Text(
          "We sent a verification link to your email. Please verify it to continue.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    String? hint,
    bool obscure = false,
    TextInputType? type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: type,
          obscureText: obscure,
          decoration: InputDecoration(hintText: hint),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Doctor Signup"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField("Full Name", _nameController,
                  validator: (v) => v == null || v.isEmpty ? "Required" : null,
                  hint: "Enter full name"),
              _buildField("Email", _emailController,
                  type: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Required";
                    if (!EmailValidator.validate(v.trim())) return "Invalid email";
                    return null;
                  },
                  hint: "Enter email"),
              _buildField("Password", _passwordController,
                  obscure: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Required";
                    if (v.length < 6) return "Minimum 6 characters";
                    return null;
                  },
                  hint: "Create password"),
              _buildField("Confirm Password", _confirmPasswordController,
                  obscure: true,
                  validator: (v) {
                    if (v != _passwordController.text) return "Passwords do not match";
                    return null;
                  },
                  hint: "Re-enter password"),
              _buildField("Medical Reg. Number", _regNumberController,
                  validator: (v) => v == null || v.isEmpty ? "Required" : null,
                  hint: "Enter medical registration number"),
              _buildField("Specialization", _specializationController,
                  validator: (v) => v == null || v.isEmpty ? "Required" : null,
                  hint: "e.g. Cardiologist, Dentist"),
              _buildField("Hospital/Clinic Name", _clinicNameController,
                  validator: (v) => v == null || v.isEmpty ? "Required" : null,
                  hint: "Enter hospital or clinic name"),
              _buildField("Location", _locationController,
                  validator: (v) => v == null || v.isEmpty ? "Required" : null,
                  hint: "City / Address"),
              Row(
                children: [
                  Checkbox(
                    value: agreeToTerms,
                    onChanged: (val) => setState(() => agreeToTerms = val ?? false),
                  ),
                  const Expanded(
                    child: Text('I agree to Terms and Privacy Policy',
                        style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _signUpDoctor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Create Account"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}