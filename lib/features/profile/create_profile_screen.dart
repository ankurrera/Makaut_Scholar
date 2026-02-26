import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _collegeController = TextEditingController();
  String? _selectedDepartment;
  bool _isLoading = false;

  final List<String> _departments = ['CSE', 'IT', 'ECE', 'EE', 'ME', 'CE'];

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    _loadExistingData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final profile = await authService.getProfile();
    if (mounted) {
      if (profile != null && profile['name'] != null) {
        _nameController.text = profile['name'];
      } else if (user?.userMetadata?['name'] != null) {
        _nameController.text = user!.userMetadata!['name'];
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthService>(context, listen: false).updateProfile(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        collegeName: _collegeController.text.trim(),
        department: _selectedDepartment!,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.redAccent.shade400,
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

    // ── Adaptive colour tokens — same palette as login/signup ──
    const accent     = Color(0xFF8E82FF);
    final bg         = isDark ? const Color(0xFF0B0D11) : const Color(0xFFF5F5FA);
    final surface    = isDark ? const Color(0xFF131720) : Colors.white;
    final border     = isDark ? const Color(0xFF1F2433) : const Color(0xFFE0E0EE);
    final textColor  = isDark ? Colors.white             : const Color(0xFF0D0D1A);
    final textDim    = isDark ? const Color(0xFF8A92A6)  : const Color(0xFF6B7280);
    final fieldFill  = isDark ? const Color(0xFF0B0D11)  : const Color(0xFFF0F0F8);
    final fieldBorder= isDark ? const Color(0xFF1F2433)  : const Color(0xFFD1D5DB);
    final hintColor  = isDark ? const Color(0xFF4A5568)  : const Color(0xFFADB5BD);
    final glowOp     = isDark ? 0.13 : 0.07;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            // ── Ambient glow ──
            Positioned(top: -100, right: -80,
              child: _Glow(color: accent.withOpacity(glowOp), size: 340)),
            Positioned(bottom: -80, left: -60,
              child: _Glow(color: const Color(0xFF3B6FFF).withOpacity(glowOp * 0.7), size: 280)),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Avatar icon ──
                        Center(
                          child: Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8E82FF), Color(0xFF6C63FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: accent.withOpacity(0.35), blurRadius: 24, spreadRadius: 2)],
                            ),
                            child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text('Complete Your Profile',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 8),
                        Text('Tell us a bit about yourself to get started',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textDim, fontSize: 14)),

                        const SizedBox(height: 36),

                        // ── Form card ──
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: surface.withOpacity(isDark ? 0.85 : 0.95),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: border, width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Full Name
                                  _FieldLabel('Full Name', textDim),
                                  const SizedBox(height: 8),
                                  _ProfileField(
                                    controller: _nameController,
                                    hint: 'Your full name',
                                    prefixIcon: Icons.person_outline_rounded,
                                    accent: accent, fieldFill: fieldFill,
                                    fieldBorder: fieldBorder, hintColor: hintColor, textColor: textColor,
                                    validator: (v) => v!.isEmpty ? 'Name is required' : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Phone
                                  _FieldLabel('Phone Number', textDim),
                                  const SizedBox(height: 8),
                                  _ProfileField(
                                    controller: _phoneController,
                                    hint: '+91 00000 00000',
                                    prefixIcon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    accent: accent, fieldFill: fieldFill,
                                    fieldBorder: fieldBorder, hintColor: hintColor, textColor: textColor,
                                    validator: (v) => v!.isEmpty ? 'Phone number is required' : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // College
                                  _FieldLabel('College Name', textDim),
                                  const SizedBox(height: 8),
                                  _ProfileField(
                                    controller: _collegeController,
                                    hint: 'e.g. RCC Institute of Technology',
                                    prefixIcon: Icons.school_outlined,
                                    accent: accent, fieldFill: fieldFill,
                                    fieldBorder: fieldBorder, hintColor: hintColor, textColor: textColor,
                                    validator: (v) => v!.isEmpty ? 'College name is required' : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Department dropdown
                                  _FieldLabel('Department', textDim),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedDepartment,
                                    dropdownColor: isDark ? const Color(0xFF131720) : Colors.white,
                                    style: TextStyle(color: textColor, fontSize: 15),
                                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: hintColor),
                                    decoration: InputDecoration(
                                      hintText: 'Select your branch',
                                      hintStyle: TextStyle(color: hintColor, fontSize: 14),
                                      prefixIcon: Icon(Icons.category_outlined, color: hintColor, size: 20),
                                      filled: true, fillColor: fieldFill,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: fieldBorder, width: 1.5)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accent.withOpacity(0.7), width: 1.5)),
                                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                                      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                                    ),
                                    items: _departments.map((dept) => DropdownMenuItem(
                                      value: dept,
                                      child: Text(dept, style: TextStyle(color: textColor)),
                                    )).toList(),
                                    onChanged: (val) => setState(() => _selectedDepartment = val),
                                    validator: (val) => val == null ? 'Please select your department' : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Save button ──
                        GestureDetector(
                          onTap: _isLoading ? null : _saveProfile,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8E82FF), Color(0xFF6C63FF)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [BoxShadow(color: accent.withOpacity(0.32), blurRadius: 20, offset: const Offset(0, 6))],
                            ),
                            child: Center(
                              child: _isLoading
                                ? const SizedBox(width: 24, height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Save & Continue',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.3)),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                    ],
                                  ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
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
}

// ─────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────

class _Glow extends StatelessWidget {
  final Color color; final double size;
  const _Glow({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent])));
}

class _FieldLabel extends StatelessWidget {
  final String label; final Color color;
  const _FieldLabel(this.label, this.color);
  @override
  Widget build(BuildContext context) => Text(label,
    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5));
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final Color accent, fieldFill, fieldBorder, hintColor, textColor;
  final String? Function(String?)? validator;

  const _ProfileField({
    required this.controller, required this.hint, required this.prefixIcon,
    required this.accent, required this.fieldFill, required this.fieldBorder,
    required this.hintColor, required this.textColor,
    this.keyboardType, this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller, keyboardType: keyboardType,
    style: TextStyle(color: textColor, fontSize: 15),
    validator: validator,
    decoration: InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: hintColor, fontSize: 14),
      filled: true, fillColor: fieldFill,
      prefixIcon: Icon(prefixIcon, color: hintColor, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: fieldBorder, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accent.withOpacity(0.7), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    ),
  );
}
