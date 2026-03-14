import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'dart:ui';
import 'dart:math';

enum CalculationMode { semester, yearly, degree, cumulative }

class CgpaCalculatorScreen extends StatefulWidget {
  const CgpaCalculatorScreen({super.key});

  @override
  State<CgpaCalculatorScreen> createState() => _CgpaCalculatorScreenState();
}

class _CgpaCalculatorScreenState extends State<CgpaCalculatorScreen>
    with TickerProviderStateMixin {
  CalculationMode _mode = CalculationMode.semester;

  // Multi-Semester Mode State (YGPA, DGPA, CGPA)
  final List<_SemesterResult> _semesters =
      List.generate(8, (i) => _SemesterResult(i + 1));

  double _result = 0.0;
  double _percentage = 0.0;
  bool _hasCalculated = false;

  // NumPad State
  String? _activeFieldId; // e.g., 'sem_0_sgpa'
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // -- DESIGN SYSTEM --
  final Color _accentColor = const Color(0xFFE5252A);
  final Color _accentGlow = const Color(0xFFE5252A).withValues(alpha: 0.3);

  void _onNumpadPress(String key) {
    if (_activeFieldId == null) return;

    final parts = _activeFieldId!.split('_');
    final index = int.parse(parts[1]);
    final isSgpa = parts[2] == 'sgpa';

    String currentText =
        isSgpa ? _semesters[index].sgpaText : _semesters[index].creditsText;

    if (key == 'DEL') {
      if (currentText.isNotEmpty) {
        currentText = currentText.substring(0, currentText.length - 1);
      }
    } else if (key == '.') {
      if (!currentText.contains('.')) {
        currentText += currentText.isEmpty ? '0.' : '.';
      }
    } else {
      // Limit length to prevent overflow
      if (currentText.length < 5) currentText += key;
    }

    setState(() {
      if (isSgpa) {
        _semesters[index].sgpaText = currentText;
      } else {
        _semesters[index].creditsText = currentText;
      }
    });
  }

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
        _percentage = _result * 10;
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
        _percentage = _result * 10;
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
        _percentage = _result * 10;
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
        _percentage = _result * 10;
        _hasCalculated = true;
      });
    }
  }

  void _clearAll() {
    setState(() {
      for (var sem in _semesters) {
        sem.sgpaText = '';
        sem.creditsText = '';
      }
      _hasCalculated = false;
      _result = 0.0;
      _percentage = 0.0;
      _activeFieldId = null;
    });
  }

  String _getModeLabel() {
    switch (_mode) {
      case CalculationMode.semester:
        return "SGPA";
      case CalculationMode.yearly:
        return "YGPA";
      case CalculationMode.degree:
        return "DGPA";
      case CalculationMode.cumulative:
        return "CGPA";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Nothing OS True Black and Pure White
    final Color bgPrimary =
        isDark ? const Color(0xFF000000) : const Color(0xFFF4F5F7);

    return Scaffold(
      backgroundColor: bgPrimary,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _buildIconButton(
            Iconsax.arrow_left, () => Navigator.pop(context), isDark),
        centerTitle: true,
        title: Text(
          'CGPA CALCULATOR',
          style: TextStyle(
            fontFamily: 'NDOT',
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          _buildIconButton(Iconsax.trash, _clearAll, isDark),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: _hasCalculated,
              child: _buildMainContent(isDark),
            ),
          ),
          if (!_hasCalculated)
            _buildNumpad(isDark),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child:
              Icon(icon, color: isDark ? Colors.white : Colors.black, size: 18),
        ),
      ),
    );
  }

  Widget _buildModeSelector(bool isDark) {
    return _NothingModeSelector(
      mode: _mode,
      onModeChanged: (mode) {
        setState(() {
          _mode = mode;
          _hasCalculated = false;
          _activeFieldId = null;
        });
      },
    );
  }

  Widget _buildFormulaBanner(bool isDark) {
    String formula = "";
    switch (_mode) {
      case CalculationMode.semester:
        formula = "CREDIT POINTS / CREDITS";
        break;
      case CalculationMode.yearly:
        formula = "(CP_ODD + CP_EVEN) / (C_ODD + C_EVEN)";
        break;
      case CalculationMode.degree:
        formula = "(YGPA1 + YGPA2 + 1.5*YGPA3 + 1.5*YGPA4) / 5";
        break;
      case CalculationMode.cumulative:
        formula = "Σ(CREDIT POINTS) / Σ(CREDITS)";
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF222222) : const Color(0xFFE6E8EC),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222222) : const Color(0xFFF4F5F7),
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.info_circle,
                color: isDark ? Colors.white : Colors.black, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "OFFICIAL FORMULA",
                  style: TextStyle(
                    fontFamily: 'NDOT',
                    color: _accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  formula,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 12,
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
          ? SingleChildScrollView(
              key: const ValueKey("resultScroll"),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildModeSelector(isDark),
                  const SizedBox(height: 24),
                  _buildFormulaBanner(isDark),
                  const SizedBox(height: 32),
                  _buildResultSection(isDark),
                  const SizedBox(height: 40),
                ],
              ),
            )
          : Column(
              key: const ValueKey("inputCol"),
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: _buildModeSelector(isDark),
                ),
                Expanded(
                  child: _buildInputSection(isDark),
                ),
              ],
            ),
    );
  }

  Widget _buildResultSection(bool isDark) {
    return Column(
      key: const ValueKey("result"),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF222222) : const Color(0xFFE6E8EC),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                "${_getModeLabel()} SCORE",
                style: TextStyle(
                    fontFamily: 'NDOT',
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _result.toStringAsFixed(2),
                  style: TextStyle(
                      fontFamily: 'NDOT',
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2),
                ),
              ),
              const SizedBox(height: 32),
              Divider(
                color:
                    isDark ? const Color(0xFF222222) : const Color(0xFFE6E8EC),
                thickness: 1.5,
                height: 1.5,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.chart_21, color: _accentColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "${_percentage.toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontFamily: 'NDOT',
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "PERCENTAGE",
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Nothing OS styled Recalculate Button
        ScaleButton(
          onTap: () => setState(() => _hasCalculated = false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222222) : const Color(0xFFE6E8EC),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.refresh,
                    color: isDark ? Colors.white : Colors.black, size: 18),
                const SizedBox(width: 12),
                Text(
                  "RECALCULATE",
                  style: TextStyle(
                    fontFamily: 'NDOT',
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
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
      children: [
        Expanded(
            child: PageView.builder(
          controller: _pageController,
          onPageChanged: (idx) {
            setState(() {
              _currentPage = idx;
              _activeFieldId = 'sem_${idx}_sgpa';
            });
          },
          itemCount: count,
          itemBuilder: (context, index) => _buildSplitWidget(index, isDark),
        )),
        if (count > 1) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.white24 : Colors.black26),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
        ]
      ],
    );
  }

  Widget _buildSplitWidget(int index, bool isDark) {
    final bool isDegree = _mode == CalculationMode.degree;
    final bool isYearly = _mode == CalculationMode.yearly;
    final bool isSemester = _mode == CalculationMode.semester;

    String title = isDegree
        ? "YEAR ${index + 1}"
        : (isSemester ? "CURRENT SEMESTER" : "SEMESTER ${index + 1}");
    if (isYearly) title = index == 0 ? "ODD SEMESTER" : "EVEN SEMESTER";

    final topId = 'sem_${index}_sgpa';
    final bottomId = 'sem_${index}_credits';
    bool isTopActive = _activeFieldId == topId;
    bool isBottomActive = _activeFieldId == bottomId;

    if (_activeFieldId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _activeFieldId = topId);
      });
    }

    String topVal = _semesters[index].sgpaText;
    String bottomVal = _semesters[index].creditsText;

    Color primaryColor = isDark ? Colors.white : Colors.black;
    Color secondaryColor = isDark ? Colors.white54 : Colors.black54;
    Color dividerColor = isDark ? Colors.white24 : Colors.black12;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(title,
              style: TextStyle(
                  fontFamily: 'NDOT',
                  color: secondaryColor,
                  fontSize: 14,
                  letterSpacing: 1.5)),
          const Spacer(flex: 1),
          // SGPA / YGPA Section
          GestureDetector(
            onTap: () => setState(() => _activeFieldId = topId),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(topVal.isEmpty ? "0.00" : topVal,
                          style: TextStyle(
                            fontFamily: 'NDOT',
                            fontSize: isTopActive ? 64 : 52,
                            color: isTopActive ? primaryColor : secondaryColor,
                            height: 1.0,
                            letterSpacing: 2.0,
                          )),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isTopActive)
                          Icon(Iconsax.arrow_up_2,
                              color: primaryColor, size: 12),
                        if (isTopActive)
                          Icon(Iconsax.arrow_down_1,
                              color: primaryColor, size: 12),
                        const SizedBox(height: 2),
                        Text(isDegree ? "YGPA" : "SGPA",
                            style: TextStyle(
                                fontFamily: 'NDOT',
                                fontSize: 12,
                                color:
                                    isTopActive ? primaryColor : secondaryColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isDegree) ...[
            const Spacer(flex: 1),
            // The faint split line
            Container(height: 1, color: dividerColor),
            const Spacer(flex: 1),
            // Credits Section
            GestureDetector(
              onTap: () => setState(() => _activeFieldId = bottomId),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(bottomVal.isEmpty ? "0" : bottomVal,
                            style: TextStyle(
                              fontFamily: 'NDOT',
                              fontSize: isBottomActive ? 64 : 52,
                              color:
                                  isBottomActive ? primaryColor : secondaryColor,
                              height: 1.0,
                              letterSpacing: 2.0,
                            )),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isBottomActive)
                            Icon(Iconsax.arrow_up_2,
                                color: primaryColor, size: 12),
                          if (isBottomActive)
                            Icon(Iconsax.arrow_down_1,
                                color: primaryColor, size: 12),
                          const SizedBox(height: 2),
                          Text("CRD",
                              style: TextStyle(
                                  fontFamily: 'NDOT',
                                  fontSize: 12,
                                  color: isBottomActive
                                      ? primaryColor
                                      : secondaryColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  void _clearCurrentField() {
    if (_activeFieldId == null) return;
    final parts = _activeFieldId!.split('_');
    final index = int.parse(parts[1]);
    final isSgpa = parts[2] == 'sgpa';
    setState(() {
      if (isSgpa)
        _semesters[index].sgpaText = '';
      else
        _semesters[index].creditsText = '';
    });
  }

  Widget _buildNumpad(bool isDark) {
    return Container(
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF9F9FB),
          border: Border(
              top: BorderSide(
                  color: isDark
                      ? const Color(0xFF222222)
                      : const Color(0xFFE6E8EC),
                  width: 1.5))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding:
              const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNumBtn('7', isDark),
                        _buildNumBtn('8', isDark),
                        _buildNumBtn('9', isDark),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNumBtn('4', isDark),
                        _buildNumBtn('5', isDark),
                        _buildNumBtn('6', isDark),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNumBtn('1', isDark),
                        _buildNumBtn('2', isDark),
                        _buildNumBtn('3', isDark),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNumBtn('.', isDark, isAction: true),
                        _buildNumBtn('0', isDark),
                        _buildNumBtn('00', isDark, isAction: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildNumBtn('DEL', isDark, isAction: true),
                    const SizedBox(height: 12),
                    _buildNumBtn('C', isDark, isAction: true),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _calculate,
                      child: Container(
                        width: 72,
                        height: 72 * 2 + 12, // match Nothing OS tall equal button
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(36),
                        ),
                        child: const Center(
                          child: Icon(Iconsax.calculator,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumBtn(String label, bool isDark, {bool isAction = false}) {
    return GestureDetector(
        onTap: () {
          if (label == 'C') {
            _clearCurrentField();
          } else {
            _onNumpadPress(label);
          }
        },
        child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isAction
                  ? (isDark ? const Color(0xFF222222) : const Color(0xFFE6E8EC))
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
                child: Text(label,
                    style: TextStyle(
                      fontFamily: 'NDOT',
                      fontSize: isAction ? 18 : 28,
                      color: isDark ? Colors.white : Colors.black,
                    )))));
  }

  Widget _buildGlassButton(
      String label, IconData icon, VoidCallback onTap, bool isDark) {
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

class DottedIcon extends StatelessWidget {
  final List<String> pattern;
  final Color color;
  final double dotSize;
  final double spacing;

  const DottedIcon({
    super.key,
    required this.pattern,
    required this.color,
    this.dotSize = 4.0,
    this.spacing = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: pattern.map((row) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.split('').map((char) {
            final isDot = char == '#' || char == 'O';
            return Container(
              width: dotSize,
              height: dotSize,
              margin: EdgeInsets.all(spacing / 2),
              decoration: BoxDecoration(
                color: isDot ? color : Colors.transparent,
                shape: BoxShape.circle,
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const GlassContainer(
      {super.key, required this.child, this.padding, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(0),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: borderRadius,
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05)),
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

class _ScaleButtonState extends State<ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
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

class _NothingModeSelector extends StatelessWidget {
  final CalculationMode mode;
  final ValueChanged<CalculationMode> onModeChanged;

  const _NothingModeSelector({
    required this.mode,
    required this.onModeChanged,
  });

  String _getLabelForMode(CalculationMode mode) {
    switch (mode) {
      case CalculationMode.semester:
        return "SGPA";
      case CalculationMode.yearly:
        return "YGPA";
      case CalculationMode.degree:
        return "DGPA";
      case CalculationMode.cumulative:
        return "CGPA";
    }
  }

  Widget _buildDottedIcon(CalculationMode mode, Color color) {
    List<String> pattern;
    switch (mode) {
      case CalculationMode.semester: // Abstract Open Book / Document
        pattern = [
          ".......",
          ".##.##.",
          ".#.#.#.",
          ".#.#.#.",
          ".##.##.",
          ".......",
          ".......",
        ];
        break;
      case CalculationMode.yearly: // Abstract Calendar Grid
        pattern = [
          ".......",
          ".#####.",
          ".#.#.#.",
          ".#####.",
          ".#.#.#.",
          ".#####.",
          ".......",
        ];
        break;
      case CalculationMode.degree: // Abstract Cap / Diamond target
        pattern = [
          ".......",
          "...#...",
          "..#.#..",
          ".#...#.",
          "..#.#..",
          "...#...",
          "...#...",
        ];
        break;
      case CalculationMode.cumulative: // Abstract Ascending Trend Line
        pattern = [
          "......#",
          ".....#.",
          "....#..",
          ".#.#...",
          "#.#....",
          ".......",
          ".......",
        ];
        break;
    }
    return DottedIcon(
        pattern: pattern, color: color, dotSize: 3.0, spacing: 1.5);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modes = CalculationMode.values;    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: modes.map((m) {
          final isActive = m == mode;

          return Expanded(
            child: GestureDetector(
              onTap: () => onModeChanged(m),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark
                                ? const Color(0xFF222222)
                                : const Color(0xFFE6E8EC)),
                      ),
                      child: Center(
                        child: _buildDottedIcon(
                          m,
                          isActive
                              ? (isDark ? Colors.black : Colors.white)
                              : (isDark ? Colors.white : Colors.black),
                        ),
                      )),
                  const SizedBox(height: 12),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontFamily: 'NDOT',
                      fontSize: 12,
                      letterSpacing: 1.0,
                      color: isActive
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                    textAlign: TextAlign.center,
                    child: Text(_getLabelForMode(m)),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SemesterResult {
  final int semester;
  String sgpaText = '';
  String creditsText = '';

  double? get sgpa => double.tryParse(sgpaText);
  double? get credits => double.tryParse(creditsText);

  _SemesterResult(this.semester);
}
