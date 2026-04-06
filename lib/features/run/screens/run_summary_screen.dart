import 'package:flutter/material.dart';

class RunSummaryScreen extends StatelessWidget {
  const RunSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Run summary')),
      body: const Center(child: Text('Run summary')),
    );
  }
}
