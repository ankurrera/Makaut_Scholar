import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/auth_service.dart';
import '../../core/widgets/dot_loading.dart';
import '../auth/login/login_screen.dart' show AuthTheme;

// ─────────────────────────────────────────────────────────────────────────────
// Create Profile Screen
// ─────────────────────────────────────────────────────────────────────────────
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
        vsync: this, duration: const Duration(milliseconds: 600));
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
          content: Text('Error saving profile: $e',
              style: const TextStyle(fontFamily: 'NDOT')),
          backgroundColor: AuthTheme.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AuthTheme.darkBg : AuthTheme.lightBg;
    final textP = isDark ? AuthTheme.darkText : AuthTheme.lightText;
    final textS = isDark ? AuthTheme.darkSubtext : AuthTheme.lightSubtext;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            // ── Nothing OS dot-matrix grid texture ──
            Positioned.fill(
              child: CustomPaint(painter: _DotGridPainter(isDark: isDark)),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 56),

                        // ── Header Section ──
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BUILD YOUR\nPROFILE',
                                style: TextStyle(
                                    fontFamily: 'NDOT',
                                    color: textP,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3.0,
                                    height: 1.0)),
                            const SizedBox(height: 12),
                            Text('Complete your student record',
                                style: TextStyle(
                                    color: textS,
                                    fontSize: 14,
                                    letterSpacing: 0.3)),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // ── Avatar Section ──
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Main Avatar Box — Nothing OS Square style
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: isDark ? AuthTheme.darkSurface : AuthTheme.lightSurface,
                                    borderRadius: BorderRadius.circular(12),
                                    image: _avatarFile != null
                                        ? DecorationImage(
                                            image: FileImage(_avatarFile!),
                                            fit: BoxFit.cover)
                                        : null,
                                    border: Border.all(
                                        color: isDark ? AuthTheme.darkBorder : AuthTheme.lightBorder,
                                        width: 1.5),
                                  ),
                                  child: _avatarFile == null
                                      ? Icon(Iconsax.user_add_copy,
                                          color: textS,
                                          size: 40)
                                      : null,
                                ),
                                // Edit Badge
                                Positioned(
                                  bottom: -8,
                                  right: -8,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AuthTheme.accent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: bg, width: 2),
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

                        // ── Form Section ──
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PERSONAL DETAILS',
                                style: TextStyle(
                                    fontFamily: 'NDOT',
                                    color: textS,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5)),
                            const SizedBox(height: 28),

                            _ProfileField(
                              controller: _nameController,
                              label: 'FULL NAME',
                              hint: 'Enter your name',
                              icon: Iconsax.personalcard,
                              isDark: isDark,
                              validator: (v) => v!.trim().isEmpty
                                  ? 'Name is required'
                                  : null,
                            ),
                            const SizedBox(height: 28),

                            _ProfileField(
                              controller: _collegeController,
                              label: 'COLLEGE NAME',
                              hint: 'Search or type college',
                              icon: Iconsax.building_3,
                              isDark: isDark,
                              validator: (v) => v!.trim().isEmpty
                                  ? 'College name is required'
                                  : null,
                            ),
                            const SizedBox(height: 28),

                            // Department Dropdown
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 0, bottom: 8),
                                  child: Text('DEPARTMENT',
                                      style: TextStyle(
                                          fontFamily: 'NDOT',
                                          color: textS,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.5)),
                                ),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedDepartment,
                                  dropdownColor: isDark ? AuthTheme.darkSurface : AuthTheme.lightSurface,
                                  style: TextStyle(
                                      fontFamily: 'NDOT',
                                      color: textP,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500),
                                  icon: Icon(Iconsax.arrow_down_copy,
                                      color: textS, size: 16),
                                  decoration: _fieldDecoration(
                                      Iconsax.category,
                                      'Select branch',
                                      isDark),
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

                        const SizedBox(height: 48),

                        // ── Action Button ──
                        GestureDetector(
                          onTap: _isLoading ? null : _saveProfile,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: AuthTheme.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text('COMPLETE PROFILE',
                                            style: TextStyle(
                                                fontFamily: 'NDOT',
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                                letterSpacing: 2.0)),
                                        SizedBox(width: 12),
                                        Icon(Iconsax.arrow_right_copy,
                                            color: Colors.white, size: 18),
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

  InputDecoration _fieldDecoration(IconData icon, String hint, bool isDark) {
    final borderColor = isDark ? AuthTheme.darkBorder : AuthTheme.lightBorder;
    final hintColor = isDark ? AuthTheme.darkHint : AuthTheme.lightHint;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: hintColor,
          fontSize: 14,
          fontFamily: 'NDOT'),
      prefixIcon: Icon(icon, color: hintColor, size: 18),
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1.0)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1.0)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthTheme.accent, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthTheme.accent, width: 1)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Support Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool isDark;
  final String? Function(String?)? validator;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final textS = isDark ? AuthTheme.darkSubtext : AuthTheme.lightSubtext;
    final textP = isDark ? AuthTheme.darkText : AuthTheme.lightText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 0, bottom: 8),
          child: Text(label,
              style: TextStyle(
                  fontFamily: 'NDOT',
                  color: textS,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          style: TextStyle(
              fontFamily: 'NDOT',
              color: textP,
              fontSize: 15,
              fontWeight: FontWeight.w500),
          decoration: _fieldDecoration(icon, hint, isDark),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(IconData icon, String hint, bool isDark) {
    final borderColor = isDark ? AuthTheme.darkBorder : AuthTheme.lightBorder;
    final hintColor = isDark ? AuthTheme.darkHint : AuthTheme.lightHint;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: hintColor,
          fontSize: 14,
          fontFamily: 'NDOT'),
      prefixIcon: Icon(icon, color: hintColor, size: 18),
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1.0)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1.0)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthTheme.accent, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthTheme.accent, width: 1)),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final bool isDark;
  const _DotGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.04)
      ..style = PaintingStyle.fill;
    const spacing = 20.0;
    const radius = 1.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.isDark != isDark;
}
