
import 'package:flutter/material.dart';

class DuyurularScreen extends StatelessWidget {
  const DuyurularScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyurular'),
      ),
      body: const Center(
        child: Text('Duyurular Ekranı'),
      ),
    );
  }
}

