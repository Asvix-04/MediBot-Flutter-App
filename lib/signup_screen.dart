import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'signin_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool agreeToTerms = false;
  bool isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    if (!agreeToTerms) {
      _showSnack("❗ You must agree to the terms");
      return;
    }

    setState(() => isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        if (!user.emailVerified) {
          await user.sendEmailVerification();
        }

        await FirebaseFirestore.instance.collection('patients').doc(user.uid).set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'patient',
          'createdAt': FieldValue.serverTimestamp(),
        });

        _showVerificationDialog();

        Future.delayed(const Duration(seconds: 3), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        });
      }
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? "❌ Sign up failed");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("📨 Verify Email", style: TextStyle(color: Colors.white)),
        content: const Text(
          "We’ve sent a verification link to your email.\nPlease check your inbox before logging in.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Got it", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/logo_circular.png',
                      height: 80,
                      width: 80,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('MediBot', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Create Account', style: TextStyle(fontSize: 22)),
                  const SizedBox(height: 8),
                  const Text(
                    'Join MediBot to get personalized medical assistance',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 32),
                  _buildTextField("Full Name", _nameController,
                      validator: (value) => value == null || value.trim().isEmpty
                          ? "Name is required"
                          : null,
                      hint: 'Enter your full name'),
                  _buildTextField("Email", _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final email = value?.trim() ?? "";
                        if (email.isEmpty) return "Email is required";
                        if (!EmailValidator.validate(email)) {
                          return "Enter a valid email address";
                        }
                        final allowedDomains = ['gmail.com', 'yahoo.com', 'outlook.com'];
                        final parts = email.split('@');
                        if (parts.length != 2 || !allowedDomains.contains(parts[1])) {
                          return "Use a valid Gmail, Yahoo, or Outlook email";
                        }
                        return null;
                      },
                      hint: 'Enter your email'),
                  _buildTextField("Password", _passwordController,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Password is required";
                        if (value.length < 6) return "Password must be at least 6 characters";
                        return null;
                      },
                      hint: 'Create a password'),
                  _buildTextField("Confirm Password", _confirmPasswordController,
                      obscureText: true,
                      validator: (value) {
                        if (value != _passwordController.text) return "Passwords do not match";
                        return null;
                      },
                      hint: 'Confirm your password'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Checkbox(
                        value: agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            agreeToTerms = value ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'I agree to the Terms of Service and Privacy Policy',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _signUpWithEmail,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Create Account'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('or continue with', style: TextStyle(color: Colors.white60)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.g_mobiledata, color: Colors.white),
                        label: const Text('Google'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.facebook, color: Colors.white),
                        label: const Text('Facebook'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const SignInScreen()),
                          );
                        },
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    String? hint,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}