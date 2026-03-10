import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/auth_service.dart';
import '../../core/widgets/dot_loading.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _collegeController = TextEditingController();
  String? _selectedDepartment;
  File? _avatarFile;
  bool _isLoading = false;

  final List<String> _departments = ['CSE', 'IT', 'ECE', 'EE', 'ME', 'CE'];

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _fadeController.forward();
    _loadExistingData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final profile = await authService.getProfile();
    if (mounted) {
      setState(() {
        if (profile != null && profile['name'] != null) {
          _nameController.text = profile['name'];
        } else if (user?.userMetadata?['name'] != null) {
          _nameController.text = user!.userMetadata!['name'];
        }
        if (profile != null && profile['college_name'] != null) {
          _collegeController.text = profile['college_name'];
        }
        if (profile != null && profile['department'] != null) {
          _selectedDepartment = profile['department'];
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      if (mounted) {
        setState(() => _avatarFile = File(pickedFile.path));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      String? avatarUrl;
      if (_avatarFile != null) {
        avatarUrl = await authService.uploadAvatar(_avatarFile!.path);
      }

      await authService.updateProfile(
        name: _nameController.text.trim(),
        collegeName: _collegeController.text.trim(),
        department: _selectedDepartment!,
        avatarUrl: avatarUrl,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.redAccent.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Refined Palette ──
    const accent = Color(0xFFE5252A);
    final bg = isDark ? const Color(0xFF121512) : const Color(0xFFF7F8FA);
    final card = isDark ? const Color(0xFF1C2020) : Colors.white;
    final border = isDark ? const Color(0xFF2A3030) : const Color(0xFFE6E8EC);
    final textP = isDark ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);
    final textS = isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
    final glowOp = isDark ? 0.2 : 0.1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            // ── Background Aesthetic ──
            Positioned(
                top: -120,
                right: -60,
                child:
                    _Glow(color: accent.withValues(alpha: glowOp), size: 400)),
            Positioned(
                bottom: -100,
                left: -80,
                child: _Glow(
                    color:
                        const Color(0xFF3B6FFF).withValues(alpha: glowOp * 0.8),
                    size: 350)),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

                        // ── Header Section ──
                        Center(
                          child: Column(
                            children: [
                              Text('Build your profile',
                                  style: TextStyle(
                                      color: textP,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6)),
                              const SizedBox(height: 8),
                              Text('This helps us personalize your experience',
                                  style: TextStyle(color: textS, fontSize: 15)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 48),

                        // ── Avatar Section ──
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Main Avatar Circle
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: card,
                                    shape: BoxShape.circle,
                                    image: _avatarFile != null
                                        ? DecorationImage(
                                            image: FileImage(_avatarFile!),
                                            fit: BoxFit.cover)
                                        : null,
                                    border: Border.all(color: border, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withValues(
                                              alpha: isDark ? 0.4 : 0.06),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8)),
                                    ],
                                  ),
                                  child: _avatarFile == null
                                      ? Icon(Iconsax.profile_circle_copy,
                                          color: accent.withValues(alpha: 0.8),
                                          size: 44)
                                      : null,
                                ),
                                // Edit Badge
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: accent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: bg, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                            color:
                                                accent.withValues(alpha: 0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4))
                                      ],
                                    ),
                                    child: const Icon(Iconsax.camera_copy,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // ── Form Card ──
                        _GlassCard(
                          isDark: isDark,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('PERSONAL DETAILS', textS),
                                const SizedBox(height: 20),

                                _ProfileField(
                                  controller: _nameController,
                                  label: 'Full Name',
                                  hint: 'Enter your name',
                                  icon: Iconsax.user_copy,
                                  isDark: isDark,
                                  accent: accent,
                                  validator: (v) => v!.trim().isEmpty
                                      ? 'Name is required'
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                _ProfileField(
                                  controller: _collegeController,
                                  label: 'College',
                                  hint: 'Search or type college',
                                  icon: Iconsax.teacher_copy,
                                  isDark: isDark,
                                  accent: accent,
                                  validator: (v) => v!.trim().isEmpty
                                      ? 'College name is required'
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                // Department Dropdown
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 4, bottom: 8),
                                      child: Text('Department',
                                          style: TextStyle(
                                              color: textS,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedDepartment,
                                      dropdownColor: card,
                                      style: TextStyle(
                                          color: textP,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500),
                                      icon: Icon(Iconsax.arrow_down_copy,
                                          color: textS, size: 16),
                                      decoration: _fieldDecoration(
                                          Iconsax.hierarchy_copy,
                                          'Select branch',
                                          isDark,
                                          accent),
                                      items: _departments
                                          .map((d) => DropdownMenuItem(
                                              value: d, child: Text(d)))
                                          .toList(),
                                      onChanged: (v) => setState(
                                          () => _selectedDepartment = v),
                                      validator: (v) => v == null
                                          ? 'Selection required'
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── Action Button ──
                        GestureDetector(
                          onTap: _isLoading ? null : _saveProfile,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE5252A), Color(0xFFE5252A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color: accent.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8))
                              ],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: DotLoadingIndicator(
                                          color: Colors.white, size: 6))
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text('Save & Continue',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 17,
                                                letterSpacing: 0.2)),
                                        SizedBox(width: 10),
                                        Icon(Iconsax.arrow_right_copy,
                                            color: Colors.white, size: 20),
                                      ],
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(text,
        style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2));
  }

  InputDecoration _fieldDecoration(
      IconData icon, String hint, bool isDark, Color accent) {
    final borderCol =
        isDark ? const Color(0xFF2A3030) : const Color(0xFFE6E8EC);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: isDark ? const Color(0xFF4A5568) : const Color(0xFFADB5BD),
          fontSize: 14),
      prefixIcon: Icon(icon,
          color: isDark ? const Color(0xFF535F77) : const Color(0xFF94A3B8),
          size: 20),
      filled: true,
      fillColor: isDark
          ? const Color(0xFF121512).withValues(alpha: 0.5)
          : const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderCol, width: 1)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
    );
  }
}

// ─────────────────────────────────────────
// Support Widgets
// ─────────────────────────────────────────

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent])));
}

class _GlassCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _GlassCard({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 40,
              offset: const Offset(0, 10))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), child: child),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool isDark;
  final Color accent;
  final String? Function(String?)? validator;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    required this.accent,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final textS = isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
    final textP = isDark ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label,
              style: TextStyle(
                  color: textS, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          style: TextStyle(
              color: textP, fontSize: 15, fontWeight: FontWeight.w500),
          decoration: _fieldDecoration(icon, hint, isDark, accent),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(
      IconData icon, String hint, bool isDark, Color accent) {
    final borderCol =
        isDark ? const Color(0xFF2A3030) : const Color(0xFFE6E8EC);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: isDark ? const Color(0xFF4A5568) : const Color(0xFFADB5BD),
          fontSize: 14),
      prefixIcon: Icon(icon,
          color: isDark ? const Color(0xFF535F77) : const Color(0xFF94A3B8),
          size: 20),
      filled: true,
      fillColor: isDark
          ? const Color(0xFF121512).withValues(alpha: 0.5)
          : const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderCol, width: 1)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
    );
  }
}
