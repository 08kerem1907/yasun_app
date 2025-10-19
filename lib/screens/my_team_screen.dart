
import 'package:flutter/material.dart';

class MyTeamScreen extends StatelessWidget {
  const MyTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ekibim'),
      ),
      body: const Center(
        child: Text('Ekibim Ekranı'),
      ),
    );
  }
}

