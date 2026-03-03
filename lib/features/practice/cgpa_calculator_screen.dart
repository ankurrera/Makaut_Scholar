import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'dart:ui';

enum CalculationMode { semester, yearly, degree, cumulative }

class CgpaCalculatorScreen extends StatefulWidget {
  const CgpaCalculatorScreen({super.key});

  @override
  State<CgpaCalculatorScreen> createState() => _CgpaCalculatorScreenState();
}

class _CgpaCalculatorScreenState extends State<CgpaCalculatorScreen> with TickerProviderStateMixin {
  CalculationMode _mode = CalculationMode.semester;
  
  // Multi-Semester Mode State (YGPA, DGPA, CGPA)
  final List<_SemesterResult> _semesters = List.generate(8, (i) => _SemesterResult(i + 1));

  double _result = 0.0;
  double _percentage = 0.0;
  bool _hasCalculated = false;

  // -- DESIGN SYSTEM --
  final Color _accentColor = const Color(0xFF8E82FF);
  final Color _accentGlow = const Color(0xFF7C6FF6).withValues(alpha: 0.3);

  void _calculate() {
    setState(() => _hasCalculated = false);

    switch (_mode) {
      case CalculationMode.semester:
        _calculateSGPA();
        break;
      case CalculationMode.yearly:
        _calculateYGPA();
        break;
      case CalculationMode.degree:
        _calculateDGPA();
        break;
      case CalculationMode.cumulative:
        _calculateCGPA();
        break;
    }
  }

  void _calculateSGPA() {
    final double? creditPoints = _semesters[0].sgpa;
    final double? credits = _semesters[0].credits;
    if (credits != null && credits > 0 && creditPoints != null) {
      setState(() {
        _result = creditPoints / credits;
        _percentage = (_result - 0.75) * 10;
        _hasCalculated = true;
      });
    }
  }

  void _calculateYGPA() {
    double totalCreditIndex = 0;
    double totalCredits = 0;
    int count = 0;
    for (var sem in _semesters.take(2)) {
      if (sem.sgpa != null && sem.credits != null) {
        totalCreditIndex += sem.sgpa!;
        totalCredits += sem.credits!;
        count++;
      }
    }
    if (totalCredits > 0 && count == 2) {
      setState(() {
        _result = totalCreditIndex / totalCredits;
        _percentage = (_result - 0.75) * 10;
        _hasCalculated = true;
      });
    }
  }

  void _calculateDGPA() {
    final y1 = _semesters[0].sgpa;
    final y2 = _semesters[1].sgpa;
    final y3 = _semesters[2].sgpa;
    final y4 = _semesters[3].sgpa;
    if (y1 != null && y2 != null && y3 != null && y4 != null) {
      setState(() {
        _result = (y1 + y2 + (1.5 * y3) + (1.5 * y4)) / 5;
        _percentage = (_result - 0.75) * 10;
        _hasCalculated = true;
      });
    }
  }

  void _calculateCGPA() {
    double totalCreditIndex = 0;
    double totalCredits = 0;
    for (var sem in _semesters) {
      if (sem.sgpa != null && sem.credits != null) {
        totalCreditIndex += sem.sgpa!;
        totalCredits += sem.credits!;
      }
    }
    if (totalCredits > 0) {
      setState(() {
        _result = totalCreditIndex / totalCredits;
        _percentage = (_result - 0.75) * 10;
        _hasCalculated = true;
      });
    }
  }

  void _clearAll() {
    setState(() {
      for (var sem in _semesters) {
        sem.sgpa = null;
        sem.credits = null;
      }
      _hasCalculated = false;
      _result = 0.0;
      _percentage = 0.0;
    });
  }

  String _getModeLabel() {
    switch (_mode) {
      case CalculationMode.semester: return "SGPA";
      case CalculationMode.yearly: return "YGPA";
      case CalculationMode.degree: return "DGPA";
      case CalculationMode.cumulative: return "CGPA";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgPrimary = isDark ? const Color(0xFF0D0F12) : const Color(0xFFF8F9FD);

    return Scaffold(
      backgroundColor: bgPrimary,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _buildIconButton(Iconsax.arrow_left, () => Navigator.pop(context), isDark),
        centerTitle: true,
        title: Text(
          'MAKAUT Calculator',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          _buildIconButton(Iconsax.trash, _clearAll, isDark),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildModeSelector(isDark),
              const SizedBox(height: 24),
              _buildFormulaBanner(isDark),
              const SizedBox(height: 32),
              _buildMainContent(isDark),
              const SizedBox(height: 120), // Spacing for fab
            ],
          ),
        ),
      ),
      floatingActionButton: _hasCalculated ? null : _buildCalculateFAB(isDark),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 18),
        ),
      ),
    );
  }

  Widget _buildModeSelector(bool isDark) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A21) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: CalculationMode.values.map((mode) {
          final isSelected = _mode == mode;
          String label = "";
          switch (mode) {
            case CalculationMode.semester: label = "SGPA"; break;
            case CalculationMode.yearly: label = "YGPA"; break;
            case CalculationMode.degree: label = "DGPA"; break;
            case CalculationMode.cumulative: label = "CGPA"; break;
          }
          
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _mode = mode;
                _hasCalculated = false;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutExpo,
                decoration: BoxDecoration(
                  color: isSelected ? _accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.black38),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFormulaBanner(bool isDark) {
    String formula = "";
    switch (_mode) {
      case CalculationMode.semester: formula = "CREDIT POINTS / CREDITS"; break;
      case CalculationMode.yearly: formula = "(CI_ODD + CI_EVEN) / (C_ODD + C_EVEN)"; break;
      case CalculationMode.degree: formula = "(Y1 + Y2 + 1.5*Y3 + 1.5*Y4) / 5"; break;
      case CalculationMode.cumulative: formula = "Σ(CREDIT POINTS) / Σ(CREDITS)"; break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accentColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.info_circle, color: _accentColor, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "OFFICIAL FORMULA",
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  formula,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isDark) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      child: _hasCalculated 
        ? _buildResultSection(isDark) 
        : _buildInputSection(isDark),
    );
  }

  Widget _buildResultSection(bool isDark) {
    return Column(
      key: const ValueKey("result"),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _accentColor,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            children: [
              Text(
                _mode == CalculationMode.degree ? "FINAL DEGREE GPA" : "CALCULATED INDEX",
                style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              Text(
                _result.toStringAsFixed(2),
                style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900, letterSpacing: -2),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(
                  "${_percentage.toStringAsFixed(1)}% PERCENTAGE",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildGlassButton(
          "Recalculate", 
          Iconsax.refresh, 
          () => setState(() => _hasCalculated = false), 
          isDark
        ),
      ],
    );
  }

  Widget _buildInputSection(bool isDark) {
    int count = 8;
    if (_mode == CalculationMode.semester) count = 1;
    if (_mode == CalculationMode.yearly) count = 2;
    if (_mode == CalculationMode.degree) count = 4;

    return Column(
      key: const ValueKey("inputs"),
      children: List.generate(count, (i) => _buildInputTile(i, isDark)),
    );
  }

  Widget _buildInputTile(int index, bool isDark) {
    final bool isDegree = _mode == CalculationMode.degree;
    final bool isYearly = _mode == CalculationMode.yearly;
    final bool isSemester = _mode == CalculationMode.semester;

    String title = isDegree ? "Year ${index + 1}" : (isSemester ? "Current Semester" : "Sem ${index + 1}");
    if (isYearly) title = index == 0 ? "Odd Semester" : "Even Semester";

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
          ),
          ModernInputField(
            hint: isDegree ? "Yearly GPA (YGPA)" : "Total Credit Points", 
            onUpdate: (v) => _semesters[index].sgpa = double.tryParse(v),
            initialValue: _semesters[index].sgpa?.toString() ?? '',
            isDark: isDark,
            accentColor: _accentColor,
          ),
          if (!isDegree) ...[
            const SizedBox(height: 12),
            ModernInputField(
              hint: "Total Credits", 
              onUpdate: (v) => _semesters[index].credits = double.tryParse(v),
              initialValue: _semesters[index].credits?.toString() ?? '',
              isDark: isDark,
              accentColor: _accentColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalculateFAB(bool isDark) {
    return ScaleButton(
      onTap: _calculate,
      child: Container(
        height: 64,
        width: 240,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_accentColor, const Color(0xFF6E63E6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.flash, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                "CALCULATE ${_getModeLabel()}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton(String label, IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        borderRadius: BorderRadius.circular(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _accentColor, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- PREMIUM UI COMPONENTS --

class ModernInputField extends StatefulWidget {
  final String hint;
  final Function(String) onUpdate;
  final String initialValue;
  final bool isDark;
  final Color accentColor;

  const ModernInputField({
    super.key, 
    required this.hint, 
    required this.onUpdate, 
    this.initialValue = '', 
    required this.isDark,
    required this.accentColor,
  });

  @override
  State<ModernInputField> createState() => _ModernInputFieldState();
}

class _ModernInputFieldState extends State<ModernInputField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void didUpdateWidget(ModernInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text && widget.initialValue.isEmpty) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: widget.onUpdate,
      style: TextStyle(
        color: widget.isDark ? Colors.white : Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: widget.hint,
        labelStyle: TextStyle(
          color: _isFocused ? widget.accentColor : (widget.isDark ? Colors.white38 : Colors.black38),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: widget.accentColor,
          fontWeight: FontWeight.bold,
        ),
        hintText: "Enter ${widget.hint}",
        hintStyle: TextStyle(
          color: widget.isDark ? Colors.white12 : Colors.black12,
          fontSize: 14,
        ),
        filled: true,
        fillColor: widget.isDark ? const Color(0xFF1E2228) : const Color(0xFFF1F3F7),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.accentColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const GlassContainer({super.key, required this.child, this.padding, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(0),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: borderRadius,
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
        ),
        child: child,
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

class _ScaleButtonState extends State<ScaleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse().then((_) => widget.onTap()),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _SemesterResult {
  final int semester;
  double? sgpa;
  double? credits;
  _SemesterResult(this.semester);
}
