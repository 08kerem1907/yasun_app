
import 'package:flutter/material.dart';

class TaskManagementScreen extends StatelessWidget {
  const TaskManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Görev Yönetimi'),
      ),
      body: const Center(
        child: Text('Görev Yönetimi Ekranı'),
      ),
    );
  }
}

