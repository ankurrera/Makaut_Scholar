import 'package:flutter/material.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E2C), Color(0xFF121212)],
          stops: [0.0, 0.8],
        ),
      ),
      child: const SafeArea(
        bottom: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open_rounded, color: Colors.white54, size: 64),
              SizedBox(height: 16),
              Text(
                'Resources',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Coming Soon',
                style: TextStyle(fontSize: 14, color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
