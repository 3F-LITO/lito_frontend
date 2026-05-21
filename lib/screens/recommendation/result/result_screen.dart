import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Rekomendasi ML'),
      ),
      body: const Center(
        child: Text('Tampilan Rekomendasi & Dosis Pakan (Skeleton)'),
      ),
    );
  }
}
