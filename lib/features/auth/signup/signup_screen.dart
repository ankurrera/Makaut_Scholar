import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../services/auth_service.dart';
import '../login/login_screen.dart'
    show AuthTheme, AuthField, AuthPrimaryButton, AuthDivider, AuthGoogleButton;

// ─────────────────────────────────────────────────────────────────────────────
// Signup Screen
// ─────────────────────────────────────────────────────────────────────────────
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isNavigating = false;
  DateTime? _lastAttempt;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isNavigating) return;
    final auth = Provider.of<AuthService>(context);
    if (auth.currentUser != null) {
      _isNavigating = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _checkProfileAndNavigate());
    }
  }

  Future<void> _checkProfileAndNavigate() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final profile = await auth.getProfile();
    if (!mounted) return;
    if (profile != null &&
        profile['college_name'] != null &&
        profile['college_name'].toString().isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/create_profile');
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    if (_lastAttempt != null && now.difference(_lastAttempt!).inSeconds < 5) {
      _showError('Please wait a moment before trying again.');
      return;
    }
    _lastAttempt = now;

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthService>(context, listen: false).signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.currentSession == null) {
        _showSuccess('Check your email to confirm your account.');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _checkProfileAndNavigate();
      }
    } catch (e) {
      if (!mounted) return;
      _showError(_friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('rate') ||
        lower.contains('too many') ||
        lower.contains('over_email')) {
      return 'Too many attempts. Please wait 1–2 minutes.';
    }
    if (lower.contains('already registered') ||
        lower.contains('user already')) {
      return 'Email already registered. Try signing in.';
    }
    if (lower.contains('timed out') ||
        lower.contains('socket') ||
        lower.contains('network')) {
      return 'Network error. Check your connection.';
    }
    return raw.replaceAll('Exception:', '').trim();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              fontFamily: 'NDOT')),
      backgroundColor: AuthTheme.accent,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              fontFamily: 'NDOT')),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AuthTheme.darkBg : AuthTheme.lightBg;
    final text = isDark ? AuthTheme.darkText : AuthTheme.lightText;
    final subtext = isDark ? AuthTheme.darkSubtext : AuthTheme.lightSubtext;
    final hintColor = isDark ? AuthTheme.darkHint : AuthTheme.lightHint;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
              .copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark
              .copyWith(statusBarColor: Colors.transparent),
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
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

                        // ── Back button ───────────────────────────────────────
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.canPop(context)
                                ? Navigator.pop(context)
                                : Navigator.pushReplacementNamed(context, '/login'),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? AuthTheme.darkBorder
                                      : AuthTheme.lightBorder,
                                  width: 1.0,
                                ),
                              ),
                              child: Icon(
                                Iconsax.arrow_left_copy,
                                color: text,
                                size: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Headline ──────────────────────────────────────────
                        Text(
                          'CREATE\nACCOUNT',
                          style: TextStyle(
                            fontFamily: 'NDOT',
                            color: text,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.0,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Join thousands of MAKAUT students',
                          style: TextStyle(
                            color: subtext,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ── Fields ────────────────────────────────────────────
                        AuthField(
                          controller: _nameController,
                          label: 'FULL NAME',
                          hint: 'Your name',
                          icon: Iconsax.user_copy,
                          isDark: isDark,
                          validator: (v) => v!.isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 28),
                        AuthField(
                          controller: _emailController,
                          label: 'EMAIL ADDRESS',
                          hint: 'you@example.com',
                          icon: Iconsax.sms_copy,
                          isDark: isDark,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              !v!.contains('@') ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 28),
                        AuthField(
                          controller: _passwordController,
                          label: 'PASSWORD',
                          hint: '••••••••',
                          icon: Iconsax.lock_1_copy,
                          isDark: isDark,
                          obscureText: !_isPasswordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Iconsax.eye_slash_copy
                                  : Iconsax.eye_copy,
                              size: 18,
                              color: hintColor,
                            ),
                            onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                          ),
                          validator: (v) =>
                              v!.length < 6 ? 'Min 6 characters' : null,
                        ),
                        const SizedBox(height: 28),
                        AuthField(
                          controller: _confirmPasswordController,
                          label: 'CONFIRM PASSWORD',
                          hint: '••••••••',
                          icon: Iconsax.lock_copy,
                          isDark: isDark,
                          obscureText: !_isConfirmPasswordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Iconsax.eye_slash_copy
                                  : Iconsax.eye_copy,
                              size: 18,
                              color: hintColor,
                            ),
                            onPressed: () => setState(() =>
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible),
                          ),
                          validator: (v) => v != _passwordController.text
                              ? 'Passwords do not match'
                              : null,
                        ),

                        const SizedBox(height: 32),

                        // ── Primary button ────────────────────────────────────
                        AuthPrimaryButton(
                          label: 'JOIN NOW',
                          isLoading: _isLoading,
                          onTap: _signup,
                        ),

                        const SizedBox(height: 28),
                        AuthDivider(isDark: isDark),
                        const SizedBox(height: 28),

                        AuthGoogleButton(
                          isDark: isDark,
                          onTap: () async {
                            try {
                              await Provider.of<AuthService>(context, listen: false)
                                  .signInWithGoogle();
                            } catch (e) {
                              if (!mounted) return;
                              _showError(e.toString());
                            }
                          },
                        ),

                        const SizedBox(height: 36),

                        // ── Footer ────────────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have one? ',
                              style: TextStyle(
                                  fontFamily: 'NDOT',
                                  color: subtext,
                                  fontSize: 13,
                                  letterSpacing: 0.3),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushReplacementNamed(context, '/login'),
                              child: const Text(
                                'SIGN IN',
                                style: TextStyle(
                                  fontFamily: 'NDOT',
                                  color: AuthTheme.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // ── Privacy Link ──────────────────────────────────────
                        Center(
                          child: Column(
                            children: [
                              Text(
                                "By creating an account, you agree to our",
                                style: TextStyle(
                                    fontFamily: 'NDOT',
                                    color: subtext.withOpacity(0.5),
                                    fontSize: 10,
                                    letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/privacy'),
                                child: const Text(
                                  'PRIVACY POLICY',
                                  style: TextStyle(
                                    fontFamily: 'NDOT',
                                    color: AuthTheme.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.0,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Re-using the same DotGridPainter from login_screen.dart (or copied here if not possible to export)
// ─────────────────────────────────────────────────────────────────────────────
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
