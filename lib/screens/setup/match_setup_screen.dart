import 'package:flutter/material.dart';

class MatchSetupScreen extends StatelessWidget {
  const MatchSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Setup'),
      ),
      body: const Center(
        child: Text('MatchSetupScreen'),
      ),
    );
  }
}
