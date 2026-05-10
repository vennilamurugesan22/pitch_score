import 'package:flutter/material.dart';

class MatchHistoryScreen extends StatelessWidget {
  const MatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match History'),
      ),
      body: const Center(
        child: Text('MatchHistoryScreen'),
      ),
    );
  }
}
