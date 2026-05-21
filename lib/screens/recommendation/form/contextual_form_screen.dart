import 'package:flutter/material.dart';

class ContextualFormScreen extends StatelessWidget {
  const ContextualFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Observasi Kolam'),
      ),
      body: const Center(
        child: Text('Form Observasi Kontekstual (Skeleton)'),
      ),
    );
  }
}
