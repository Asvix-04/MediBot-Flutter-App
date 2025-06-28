import 'package:flutter/material.dart';

class MedicoHomeScreen extends StatelessWidget {
  const MedicoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medico Dashboard'),
        backgroundColor: Colors.blueAccent,
      ),
      body: const Center(
        child: Text(
          'Welcome to Medico!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
