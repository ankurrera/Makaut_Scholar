import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Keeping specifically for validation
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _isNavigating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isNavigating) return;

    final authService = Provider.of<AuthService>(context);
    if (authService.currentUser != null) {
      _isNavigating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkProfileAndNavigate();
      });
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
  
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Provider.of<AuthService>(context, listen: false).signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      // If email confirmation is required, session might be null, so we show message
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentSession == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please check your email to confirm your account.')),
          );
          Navigator.pushReplacementNamed(context, '/login');
      } else {
          // If session is not null, it means auto-login happened, check profile and navigate
          _checkProfileAndNavigate();
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(e.toString())),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  String _cleanError(String error) {
    if (error.contains("Exception:")) {
      return error.replaceAll("Exception:", "").trim();
    }
    return error;
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF0A0A0A);
    const primaryAccent = Color(0xFFCCFF00);
    const inputFill = Color(0xFF1C1C1E);
    const hintText = Color(0xFFAAAAAA);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               // 1. Back Button & Header Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleButton(Icons.arrow_back, () {
                     // If pushed from login, we can pop. If from direct route, maybe pushNamed login
                     if (Navigator.canPop(context)) {
                       Navigator.pop(context);
                     } else {
                       Navigator.pushReplacementNamed(context, '/login');
                     }
                  }),
                  _buildCircleButton(Icons.refresh, () {}),
                ],
              ),
              
              const SizedBox(height: 30),

               // 2. Glowing Orb Animation
              Center(
                child: Container(
                  width: 100, // Slightly smaller on signup to save space? or keep same.
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF2A2A2A),
                        Colors.black,
                      ],
                      stops: [0.2, 1.0],
                      center: Alignment(-0.3, -0.3),
                    ),
                  ),
                  child: Container(
                     decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryAccent.withValues(alpha: 0.5), width: 1),
                    ),
                    child: const Icon(Icons.public, color: primaryAccent, size: 40),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 3. Create Account Text
              const Text(
                'Create Your Account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24, // Slightly smaller than login
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your account to explore exciting travel\ndestinations and adventures.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              // 4. Signup Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Full Name
                    _buildLabel('Full Name*'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        hint: 'Alex Smith',
                        fillColor: inputFill,
                        hintColor: hintText,
                      ),
                      validator: (v) => v!.isEmpty ? 'Name required' : null,
                    ),

                    const SizedBox(height: 16),

                    // Email
                    _buildLabel('Email address*'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        hint: 'example@gmail.com',
                        fillColor: inputFill,
                        hintColor: hintText,
                      ),
                      validator: (v) => !v!.contains('@') ? 'Invalid email' : null,
                    ),

                    const SizedBox(height: 16),

                    // Password
                    _buildLabel('Password*'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        hint: 'Min 6 characters',
                        fillColor: inputFill,
                        hintColor: hintText,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                      validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
                    ),
                    
                    const SizedBox(height: 16),
                    
                     // Confirm Password (to ensure correctness)
                    _buildLabel('Confirm Password*'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        hint: 'Re-enter Password',
                        fillColor: inputFill,
                        hintColor: hintText,
                         suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                        ),
                      ),
                      validator: (v) => v != _passwordController.text ? 'Passwords mismatch' : null,
                    ),

                    const SizedBox(height: 24),

                    // Register Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Text(
                              'Register',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),

               // 5. "Or continue with" Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[800])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Or continue with', style: TextStyle(color: Colors.grey[500])),
                  ),
                  Expanded(child: Divider(color: Colors.grey[800])),
                ],
              ),

              const SizedBox(height: 24),

              // 6. Social Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildSocialButton(
                      Icons.g_mobiledata, 
                      'Google',
                      () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        try {
                          await Provider.of<AuthService>(context, listen: false).signInWithGoogle();
                        } catch (e) {
                          if (!mounted) return;
                          scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSocialButton(
                      Icons.facebook, 
                      'Facebook',
                      () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        try {
                          await Provider.of<AuthService>(context, listen: false).signInWithFacebook();
                        } catch (e) {
                          if (!mounted) return;
                          scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

               // 7. Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ", style: TextStyle(color: Colors.grey[500])),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets (Duplicated for now) ---

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required Color fillColor,
    required Color hintColor,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade800, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 1),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
     return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 24),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFF1C1C1E),
        side: BorderSide(color: Colors.grey.shade800),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}