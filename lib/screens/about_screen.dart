import 'package:flutter/material.dart';
import '../utils/global_config.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('XStream',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(buildVersion),
              SizedBox(height: 16),
              Text('© 2025 svc.plus'),
              SizedBox(height: 16),
              Text(
                'XStream is licensed under the GNU General Public License v3.0.\n\n'
                'This application includes components from:\n'
                '• Xray-core v25.3.6 – https://github.com/XTLS/Xray-core\n'
                '  Licensed under the Mozilla Public License 2.0',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
