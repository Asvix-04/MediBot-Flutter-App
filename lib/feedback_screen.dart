import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController feedbackController = TextEditingController();
  int rating = 0;

  void submitFeedback() async {
  final email = emailController.text.trim();
  final message = feedbackController.text.trim();
  final user = FirebaseAuth.instance.currentUser;

  if (email.isEmpty || message.isEmpty || rating == 0 || user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all fields and select a rating.')),
    );
    return;
  }

  try {
    final uid = user.uid;
    String name = 'User';
    String userType = 'unknown';

    // Check if the user is a doctor
    final doctorDoc = await FirebaseFirestore.instance.collection('doctors').doc(uid).get();
    if (doctorDoc.exists) {
      final data = doctorDoc.data()!;
      name = data['fullName'] ?? 'Doctor';
      userType = 'doctor';
    } else {
      // Else check if the user is a patient
      final patientDoc = await FirebaseFirestore.instance.collection('patients').doc(uid).get();
      if (patientDoc.exists) {
        final data = patientDoc.data()!;
        name = data['name'] ?? 'Patient';
        userType = 'patient';
      }
    }

    // Save feedback
    await FirebaseFirestore.instance.collection('feedbacks').add({
      'name': name,
      'email': email,
      'message': message,
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': uid,
      'userType': userType,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback submitted successfully!')),
    );

    emailController.clear();
    feedbackController.clear();
    setState(() {
      rating = 0;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error submitting feedback: $e')),
    );
  }
}


  void contactOnWhatsApp() async {
    const phoneNumber = '916393830921'; // Replace with your actual WhatsApp number
    final message = Uri.encodeComponent("Hi, I need help with the app");
    final whatsappUri = Uri.parse("whatsapp://send?phone=$phoneNumber&text=$message");
    final webUri = Uri.parse("https://api.whatsapp.com/send?phone=$phoneNumber&text=$message");

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send Us Your Feedback', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            const Text('Your Email'),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'you@example.com',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Text('Feedback'),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Your message...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Text('Your Rating'),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: index < rating ? Colors.orange : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      rating = index + 1;
                    });
                  },
                );
              }),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Submit Feedback'),
                onPressed: submitFeedback,
              ),
            ),

            const SizedBox(height: 30),
            const Divider(),

            const SizedBox(height: 10),
            const Text('Need help or want to share something directly?'),

            TextButton.icon(
              icon: const Icon(Icons.chat, color: Colors.green),
              label: const Text('Contact on WhatsApp'),
              onPressed: contactOnWhatsApp,
            ),
          ],
        ),
      ),
    );
  }
}
