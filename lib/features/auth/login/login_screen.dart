import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isNavigating = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isNavigating) return;
    final authService = Provider.of<AuthService>(context);
    if (authService.currentUser != null) {
      _isNavigating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkProfileAndNavigate());
    }
  }

  Future<void> _checkProfileAndNavigate() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profile = await authService.getProfile();
    if (!mounted) return;
    if (profile != null && profile['college_name'] != null && profile['college_name'].toString().isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/create_profile');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthService>(context, listen: false).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(_friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent.shade400,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid') || lower.contains('credentials') || lower.contains('password')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (lower.contains('timed out') || lower.contains('socket') || lower.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    }
    return raw.replaceAll('Exception:', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Adaptive colour tokens ──
    const accent = Color(0xFF8E82FF);
    final bg         = isDark ? const Color(0xFF0B0D11) : const Color(0xFFF5F5FA);
    final surface    = isDark ? const Color(0xFF131720) : Colors.white;
    final border     = isDark ? const Color(0xFF1F2433) : const Color(0xFFE0E0EE);
    final textColor  = isDark ? Colors.white            : const Color(0xFF0D0D1A);
    final textDim    = isDark ? const Color(0xFF8A92A6) : const Color(0xFF6B7280);
    final fieldFill  = isDark ? const Color(0xFF0B0D11) : const Color(0xFFF0F0F8);
    final fieldBorder= isDark ? const Color(0xFF1F2433) : const Color(0xFFD1D5DB);
    final hintColor  = isDark ? const Color(0xFF4A5568) : const Color(0xFFADB5BD);
    final glowOpacity = isDark ? 0.15 : 0.08;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            // ── Ambient glows (subtle in light mode) ──
            Positioned(top: -120, right: -80,
              child: _Glow(color: accent.withOpacity(glowOpacity), size: 350)),
            Positioned(bottom: -100, left: -60,
              child: _Glow(color: const Color(0xFF3B6FFF).withOpacity(glowOpacity * 0.7), size: 300)),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        // ── Logo ──
                        Center(
                          child: Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8E82FF), Color(0xFF6C63FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: accent.withOpacity(0.35), blurRadius: 24, spreadRadius: 2)],
                            ),
                            child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('MAKAUT Scholar',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 6),
                        Text('Your academic companion',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textDim, fontSize: 13, letterSpacing: 0.2)),

                        const SizedBox(height: 40),

                        // ── Card ──
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: surface.withOpacity(isDark ? 0.85 : 0.95),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: border, width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Welcome back 👋',
                                    style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                                  const SizedBox(height: 6),
                                  Text('Sign in to continue learning',
                                    style: TextStyle(color: textDim, fontSize: 14)),
                                  const SizedBox(height: 28),

                                  // Email
                                  _FieldLabel('Email address', textDim),
                                  const SizedBox(height: 8),
                                  _ScholarField(
                                    controller: _emailController,
                                    hint: 'you@example.com',
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icons.alternate_email_rounded,
                                    accent: accent,
                                    fieldFill: fieldFill,
                                    fieldBorder: fieldBorder,
                                    hintColor: hintColor,
                                    textColor: textColor,
                                    validator: (v) => v!.isEmpty ? 'Email required' : null,
                                  ),
                                  const SizedBox(height: 20),

                                  // Password
                                  _FieldLabel('Password', textDim),
                                  const SizedBox(height: 8),
                                  _ScholarField(
                                    controller: _passwordController,
                                    hint: 'Enter your password',
                                    obscureText: !_isPasswordVisible,
                                    prefixIcon: Icons.lock_outline_rounded,
                                    accent: accent,
                                    fieldFill: fieldFill,
                                    fieldBorder: fieldBorder,
                                    hintColor: hintColor,
                                    textColor: textColor,
                                    suffixIcon: IconButton(
                                      icon: Icon(_isPasswordVisible
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                        color: hintColor, size: 20),
                                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                    ),
                                    validator: (v) => v!.isEmpty ? 'Password required' : null,
                                  ),
                                  const SizedBox(height: 12),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => _showError('Password reset coming soon'),
                                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                      child: Text('Forgot password?', style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  _GradientButton(label: 'Sign In', isLoading: _isLoading, onTap: _login, accent: accent),

                                  const SizedBox(height: 24),
                                  _OrDivider(textDim: textDim, border: fieldBorder),
                                  const SizedBox(height: 20),

                                  _SocialButton(
                                    label: 'Continue with Google',
                                    iconPath: Icons.g_mobiledata,
                                    textColor: textColor,
                                    fieldFill: fieldFill,
                                    fieldBorder: fieldBorder,
                                    onTap: () async {
                                      try {
                                        await Provider.of<AuthService>(context, listen: false).signInWithGoogle();
                                      } catch (e) {
                                        if (!mounted) return;
                                        _showError(e.toString());
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ", style: TextStyle(color: textDim, fontSize: 14)),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
                              child: Text('Sign up', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 14))),
                          ],
                        ),
                        const SizedBox(height: 24),
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
// Shared sub-widgets
// ─────────────────────────────────────────

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent])));
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _FieldLabel(this.label, this.color);
  @override
  Widget build(BuildContext context) => Text(label,
    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5));
}

class _ScholarField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final Color accent, fieldFill, fieldBorder, hintColor, textColor;
  final String? Function(String?)? validator;

  const _ScholarField({
    required this.controller, required this.hint, required this.prefixIcon,
    required this.accent, required this.fieldFill, required this.fieldBorder,
    required this.hintColor, required this.textColor,
    this.obscureText = false, this.keyboardType, this.suffixIcon, this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller, obscureText: obscureText, keyboardType: keyboardType,
    style: TextStyle(color: textColor, fontSize: 15),
    validator: validator,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
      filled: true, fillColor: fieldFill,
      prefixIcon: Icon(prefixIcon, color: hintColor, size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: fieldBorder, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accent.withOpacity(0.7), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    ),
  );
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  final Color accent;
  const _GradientButton({required this.label, required this.isLoading, required this.onTap, required this.accent});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent, const Color(0xFF6C63FF)], begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: accent.withOpacity(0.30), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Center(child: isLoading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
        : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.3))),
    ),
  );
}

class _OrDivider extends StatelessWidget {
  final Color textDim, border;
  const _OrDivider({required this.textDim, required this.border});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Divider(color: border, height: 1)),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text('or', style: TextStyle(color: textDim, fontSize: 13))),
    Expanded(child: Divider(color: border, height: 1)),
  ]);
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData iconPath;
  final Color textColor, fieldFill, fieldBorder;
  final VoidCallback onTap;
  const _SocialButton({required this.label, required this.iconPath, required this.textColor, required this.fieldFill, required this.fieldBorder, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 52,
      decoration: BoxDecoration(color: fieldFill, borderRadius: BorderRadius.circular(14), border: Border.all(color: fieldBorder, width: 1.5)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(iconPath, color: textColor, size: 22),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
      ]),
    ),
  );
}