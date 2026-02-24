import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'dart:ui'; // For ImageFilter
import 'dart:async';
import '../../services/auth_service.dart';
import '../notes/semester_screen.dart';
import '../syllabus/syllabus_semester_screen.dart';
import '../pyq/pyq_semester_screen.dart';
import '../important_questions/important_questions_semester_screen.dart';
import '../search/search_results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _userName = 'Scholar';
  String? _profileName;
  String? _profileDepartment;
  String _greeting = '';
  Timer? _greetingTimer;

  // Search State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Notes',
    'Syllabus',
    'PYQs',
    'Important'
  ];

  // ── LIGHT MODE PALETTE ──
  final Color _bgPrimary = const Color(0xFFF4F5F7);
  final Color _bgSecondary = const Color(0xFFFFFFFF);
  final Color _bgTertiary = const Color(0xFFF0F1F5);
  final Color _borderSubtle = const Color(0xFFE6E8EC);

  final Color _primary500 = const Color(0xFF7C6FF6);
  final Color _primary400 = const Color(0xFF9B90FF);
  final Color _primary300 = const Color(0xFFC5BFFF);
  final Color _primaryGradientStart = const Color(0xFF8E82FF);
  final Color _primaryGradientEnd = const Color(0xFFB7AEFF);

  final Color _mintSoft = const Color(0xFFCDEBE7);
  final Color _pinkSoft = const Color(0xFFF4C7D7);
  final Color _blueSoft = const Color(0xFFD9E6FF);
  final Color _purpleSoft = const Color(0xFFE8E4FF);

  final Color _textPrimary = const Color(0xFF1E1E1E);
  final Color _textSecondary = const Color(0xFF8E8E93);
  final Color _textTertiary = const Color(0xFFB4B6BD);

  // ── DARK MODE PALETTE (backgrounds only) ──
  final Color _bgPrimaryDark = const Color(0xFF0F1115);
  final Color _bgSecondaryDark = const Color(0xFF171A21);
  final Color _borderSubtleDark = const Color(0xFF2A2F3A);

  final Color _primary500Dark = const Color(0xFF8E82FF);
  final Color _primary300Dark = const Color(0xFF6E63E6);
  final Color _primaryGlowDark = const Color(0xFF7C6FF6);

  final Color _textPrimaryDark = const Color(0xFFF5F6FA);
  final Color _textSecondaryDark = const Color(0xFF9AA0A6);
  final Color _textTertiaryDark = const Color(0xFF6C727F);

  // Animation delay
  static const int _baseDelay = 200;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _updateGreeting();
    // Update greeting every 60 seconds
    _greetingTimer =
        Timer.periodic(const Duration(seconds: 60), (_) => _updateGreeting());

    // Check for offline status after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOfflineStatus();
    });
  }

  void _checkOfflineStatus() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['isOffline'] == true) {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Iconsax.info_circle,
                  color: isDark ? _primary500Dark : _primary400, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'You are currently offline. Please review your available resources until you are back online.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor:
              isDark ? const Color(0xFF2C2C2E) : const Color(0xFF1C1C1E),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
            ),
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _updateGreeting() {
    // Use IST (UTC+5:30)
    final now =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final hour = now.hour;
    String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    if (mounted) setState(() => _greeting = greeting);
  }

  Future<void> _loadProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final profile = await authService.getProfile();

    if (mounted) {
      setState(() {
        if (profile != null && profile['name'] != null) {
          _profileName = profile['name'];
          _userName = _profileName!.split(' ').first;
        } else if (user?.userMetadata?['name'] != null) {
          _userName = user!.userMetadata!['name'].split(' ').first;
        }
        _profileDepartment = profile?['department'] as String?;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _bgPrimaryDark : _bgPrimary,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
              24, 20, 24, 120), // Bottom padding for dock
          children: [
            // 1. Header
            StaggeredSlideFade(
              delayMs: 0,
              child: _buildHeader(isDark),
            ),

            const SizedBox(height: 24),

            // 2. Search Bar
            _buildSearchBar(isDark),

            const SizedBox(height: 16),

            // 3. Filter Tags
            StaggeredSlideFade(
              delayMs: _baseDelay * 2,
              child: _buildFilterTags(isDark),
            ),

            const SizedBox(height: 24),

            // 4. Feature Grid (Mapped to ref)
            StaggeredSlideFade(
              delayMs: _baseDelay * 3,
              child: _buildFeatureGrid(isDark),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting,',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: isDark ? _textSecondaryDark : _textSecondary,
                  height: 1.2,
                ),
              ),
              Text(
                _userName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? _textPrimaryDark : _textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [_primary500Dark, _primary300Dark]
                    : [_primaryGradientStart, _primaryGradientEnd],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Hero(
      tag: 'search_bar_hero',
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? _bgSecondaryDark : _bgSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? _borderSubtleDark : _borderSubtle),
          ),
          child: TextField(
            controller: _searchController,
            readOnly: true, // Navigate on tap to a dedicated search screen for better experience
            onTap: () => _openSearch(),
            style: TextStyle(
              color: isDark ? _textPrimaryDark : _textPrimary,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'Search notes, PYQs, syllabus...',
              hintStyle: TextStyle(
                color: isDark ? _textSecondaryDark : _textSecondary,
                fontSize: 15,
              ),
              prefixIcon: Icon(
                Iconsax.search_normal_1,
                color: isDark ? _textSecondaryDark : _textSecondary,
                size: 20,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTags(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          final activeColor = isDark ? _primary500Dark : _primary500;
          final inactiveColor = isDark ? _bgSecondaryDark : _bgSecondary;
          final textColor = isDark ? _textSecondaryDark : _textSecondary;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ScaleButton(
              onTap: () {
                setState(() => _selectedFilter = filter);
                _openSearch();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: isDark ? _borderSubtleDark : _borderSubtle),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected
                        ? (isDark ? _textPrimaryDark : Colors.white)
                        : textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SearchResultsScreen(
          initialQuery: _searchController.text,
          initialFilter: _selectedFilter,
          department: _profileDepartment ?? 'CSE',
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) {
      // Clear or sync back state if needed when returning
    });
  }

  Widget _buildFeatureGrid(bool isDark) {
    // In the reference image:
    // "Empathy Writing" (Hero) is Light/White even in Dark Mode.
    // "Courses" (Pastels) are Light Pastel in Dark Mode.
    // This creates high contrast against the dark background.

    return SizedBox(
      height: 460, // Increased height for 3 items
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Column: Academic Notes (Big Hero Card)
          Expanded(
            flex: 5,
            child: ScaleButton(
              onTap: () {
                final dept = _profileDepartment ?? 'CSE';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SemesterScreen(department: dept),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _purpleSoft,
                  borderRadius: BorderRadius.circular(32),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _bgSecondary.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Iconsax.book, color: _primary500, size: 24),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Academic\nNotes",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                          height: 1.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Craft words that connect emotionally with users",
                      style: TextStyle(
                          fontSize: 14,
                          color: _textPrimary.withValues(alpha: 0.6)),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Time",
                                style: TextStyle(
                                    fontSize: 12, color: _textSecondary)),
                            Text("10:30am",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _textPrimary)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _primary500,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_outward,
                              color: Colors.white, size: 20),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Right Column: Stacked Cards
          Expanded(
            flex: 4,
            child: Column(
              children: [
                // PYQ Bank (Blue)
                Expanded(
                  child: PastelCard(
                    color: _blueSoft,
                    icon: Iconsax.archive_book,
                    title: "PYQ Bank",
                    subtitle: "2018-24",
                    onTap: () {
                      final dept = _profileDepartment ?? 'CSE';
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PyqSemesterScreen(department: dept),
                          ));
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Exam Focus (Pink)
                Expanded(
                  child: PastelCard(
                    color: _pinkSoft,
                    icon: Iconsax.flash,
                    title: "Exam Focus",
                    subtitle: "Oct 16",
                    onTap: () {
                      final dept = _profileDepartment ?? 'CSE';
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ImportantQuestionsSemesterScreen(
                                department: dept),
                          ));
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Syllabus (Green)
                Expanded(
                  child: PastelCard(
                    color: _mintSoft,
                    icon: Iconsax.book_1,
                    title: "Syllabus",
                    subtitle: "PDF",
                    onTap: () {
                      final dept = _profileDepartment ?? 'CSE';
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SyllabusSemesterScreen(department: dept),
                          ));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}

// --- Reusable Widgets ---

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const SoftCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(32),
      ),
      child: child,
    );

    if (onTap != null) {
      return ScaleButton(onTap: onTap!, child: content);
    }
    return content;
  }
}

class PastelCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const PastelCard({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.65),
                    shape: BoxShape.circle),
                child: Icon(icon, color: const Color(0xFF1E1E1E), size: 18),
              ),
            ],
          ),
          const Spacer(),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E))),
          Text(subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
        ],
      ),
    );

    if (onTap != null) {
      return ScaleButton(onTap: onTap!, child: content);
    }
    return content;
  }
}

class SoftIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const SoftIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF1E1E1E), size: 24),
      ),
    );
  }
}

class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const ScaleButton({super.key, required this.child, required this.onTap});

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}


// Keep the animation widget
class StaggeredSlideFade extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const StaggeredSlideFade(
      {super.key, required this.child, required this.delayMs});

  @override
  State<StaggeredSlideFade> createState() => _StaggeredSlideFadeState();
}

class _StaggeredSlideFadeState extends State<StaggeredSlideFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600)); // Slower, smoother
    _opacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: widget.child));
  }
}
