import 'package:flutter/material.dart';

class RunScreen extends StatelessWidget {
  const RunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Run')),
      body: const Center(child: Text('Run')),
    );
  }
}
