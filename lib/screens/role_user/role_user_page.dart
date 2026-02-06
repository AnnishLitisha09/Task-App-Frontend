import 'package:flutter/material.dart';

class RoleUserPage extends StatelessWidget {
  const RoleUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Role User Dashboard')),
      body: const Center(child: Text('Welcome, Role User!')),
    );
  }
}
