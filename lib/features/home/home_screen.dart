import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Scholar';
  String? _profileName;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final profile = await authService.getProfile();

    if (mounted) {
      setState(() {
        if (profile != null && profile['name'] != null) {
          _profileName = profile['name'];
          // Use first name for "Hey, [Name]"
          _userName = _profileName!.split(' ').first;
        } else if (user?.userMetadata?['name'] != null) {
          _userName = user!.userMetadata!['name'].split(' ').first;
        }
      });
    }
  }

  void _logout(BuildContext context) async {
    await Provider.of<AuthService>(context, listen: false).signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF051105); // Deep Dark Green
    const primaryAccent = Color(0xFFCCFF00); // Lime Green
    const cardDark = Color(0xFF1C1C1E);
    const cardWhite = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F2610), // Dark Forest Green top
              Color(0xFF000000), // Black bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=11'), // Placeholder
                      backgroundColor: Colors.grey[800],
                    ),
                    const Spacer(),
                    _buildIconButton(Icons.download_rounded, () {}),
                    const SizedBox(width: 8),
                    _buildIconButton(Icons.settings_outlined, () => _logout(context)),
                  ],
                ),
                const SizedBox(height: 20),
                
                Text(
                  "Hey, $_userName",
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                ),
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                
                const SizedBox(height: 24),

                // 2. Bento Grid
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start, // Align to top
                          children: [
                            // Left Column
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  // Notes (Large)
                                  _buildBentoCard(
                                    height: 180,
                                    color: primaryAccent,
                                    title: "Notes",
                                    icon: Icons.auto_stories,
                                    iconColor: Colors.black,
                                    textColor: Colors.black,
                                    isLargeIcon: true,
                                    decorationWidget: Positioned(
                                      bottom: 10, left: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text("Unit-wise Q&A", style: TextStyle(fontSize: 10, color: Colors.black)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Continue (Small)
                                  _buildBentoCard(
                                    height: 100,
                                    color: cardWhite,
                                    title: "Continue",
                                    icon: Icons.bar_chart,
                                    iconColor: Colors.black,
                                    textColor: Colors.black,
                                    subtitle: "DBMS - Unit 2\n40% Completed",
                                  ),
                                   const SizedBox(height: 16),
                                  // Upgrade (Small)
                                  _buildBentoCard(
                                    height: 100, 
                                    color: const Color(0xFFD4FF00), // Brighter Lime
                                    title: "Upgrade",
                                    icon: Icons.diamond,
                                    iconColor: Colors.black,
                                    textColor: Colors.black,
                                    isLargeIcon: false,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Right Column
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  // PYQ (Small Rect)
                                  _buildBentoCard(
                                    height: 100,
                                    color: cardDark,
                                    title: "PYQ",
                                    icon: Icons.history_edu,
                                    iconColor: Colors.white,
                                    textColor: Colors.white,
                                  ),
                                  const SizedBox(height: 16),
                                  // Important (Small Rect)
                                  _buildBentoCard(
                                    height: 100,
                                    color: cardWhite,
                                    title: "Important",
                                    icon: Icons.local_fire_department_rounded,
                                    iconColor: Colors.orangeAccent,
                                    textColor: Colors.black,
                                  ),
                                  const SizedBox(height: 16),
                                  // Subjects (Large)
                                  _buildBentoCard(
                                    height: 180,
                                    color: cardDark,
                                    title: "Subjects",
                                    icon: Icons.library_books_outlined,
                                    iconColor: const Color(0xFF69F0AE),
                                    textColor: Colors.white,
                                    isLargeIcon: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 3. Syllabus Banner
                        Container(
                          height: 80,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: cardWhite,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Syllabus",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "Official MAKAUT Syllabus",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.class_outlined, size: 40, color: Colors.blueAccent),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.grey[400], size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildBentoCard({
    required double height,
    required Color color,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
    bool isLargeIcon = false,
    String? subtitle,
    Widget? decorationWidget,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Title
          Positioned(
            top: 0,
            left: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w600, 
                    color: textColor,
                  ),
                ),
                if (subtitle != null) ...[
                   const SizedBox(height: 4),
                   Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withValues(alpha: 0.7),
                      height: 1.2,
                    ),
                   ),
                ]
              ],
            ),
          ),
          
          // Icon
          Positioned(
            bottom: 0,
            right: 0,
            child: isLargeIcon 
              ? Icon(icon, size: 60, color: iconColor.withValues(alpha: 0.8))
              : Icon(icon, size: 32, color: iconColor),
          ),
          
          if (decorationWidget != null) decorationWidget,
        ],
      ),
    );
  }
}