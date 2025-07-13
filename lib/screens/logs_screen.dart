import 'package:flutter/material.dart';
import '../widgets/log_console.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: LogConsole(),
    );
  }
}
