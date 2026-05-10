import 'package:flutter/material.dart';

class MatchResultScreen extends StatelessWidget {
  const MatchResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Result'),
      ),
      body: const Center(
        child: Text('MatchResultScreen'),
      ),
    );
  }
}
