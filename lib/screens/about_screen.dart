import 'package:flutter/material.dart';
import '../utils/global_config.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('XStream',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(buildVersion),
          const SizedBox(height: 16),
          const Text('© 2025 svc.plus'),
        ],
      ),
    );
  }
}
