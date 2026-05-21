import 'package:flutter/material.dart';

class ParameterFormScreen extends StatelessWidget {
  const ParameterFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Parameter Air'),
      ),
      body: const Center(
        child: Text('Form Parameter Air (Skeleton)'),
      ),
    );
  }
}
