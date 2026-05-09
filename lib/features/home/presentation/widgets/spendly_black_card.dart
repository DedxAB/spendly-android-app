import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/theme/app_icons.dart';
import 'package:spendly/core/theme/app_typography.dart';
import 'package:spendly/core/utils/formatters.dart';

class SpendlyBlackCard extends StatefulWidget {
  const SpendlyBlackCard({
    super.key,
    required this.balance,
    required this.availableAmount,
    required this.cardholderName,
    this.onTap,
  });

  final double balance;
  final double availableAmount;
  final String cardholderName;
  final VoidCallback? onTap;

  @override
  State<SpendlyBlackCard> createState() => _SpendlyBlackCardState();
}

class _SpendlyBlackCardState extends State<SpendlyBlackCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  bool _showBalance = true;
  late final AnimationController _sheenController;

  @override
  void initState() {
    super.initState();
    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat();
  }

  @override
  void dispose() {
    _sheenController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final lift = _isHovered && !_isPressed;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          scale: _isPressed ? 0.984 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, lift ? -1.5 : 0, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.premiumCard),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: lift ? 0.62 : 0.45),
                  blurRadius: lift
                      ? AppElevation.premiumCard + 20
                      : AppElevation.premiumCard + 8,
                  offset: Offset(0, lift ? 20 : 14),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: lift ? 0.08 : 0.04),
                  blurRadius: lift ? 18 : 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.premiumCard),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final cardHeight = (width / 1.76).clamp(188.0, 320.0);
                  const radius = AppRadii.premiumCard;

                  return SizedBox(
                    height: cardHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF151519),
                            Color(0xFF08080A),
                            Color(0xFF010101),
                          ],
                          stops: [0, 0.48, 1],
                        ),
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(color: const Color(0xFF3A3942)),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _sheenController,
                              builder: (context, _) => CustomPaint(
                                painter: _BlackCardPainter(
                                  sheenProgress: _sheenController.value,
                                  isLifted: lift,
                                ),
                              ),
                            ),
                          ),
                          _CardContent(
                            balance: widget.balance,
                            availableAmount: widget.availableAmount,
                            cardholderName: widget.cardholderName,
                            showBalance: _showBalance,
                            onToggleBalance: () =>
                                setState(() => _showBalance = !_showBalance),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.balance,
    required this.availableAmount,
    required this.cardholderName,
    required this.showBalance,
    required this.onToggleBalance,
  });

  final double balance;
  final double availableAmount;
  final String cardholderName;
  final bool showBalance;
  final VoidCallback onToggleBalance;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final w = size.width;
        final h = size.height;
        final compact = w < 390;
        final left = w * 0.065;
        final right = w * 0.055;

        double scaled(double value, {double min = 8, double max = 44}) =>
            (h * value).clamp(min, max).toDouble();

        return Stack(
          children: [
            Positioned(
              left: left,
              top: h * 0.105,
              child: Text(
                'TOTAL BALANCE',
                style: AppTypography.metadata(context).copyWith(
                  color: Colors.white.withValues(alpha: 0.54),
                  fontSize: scaled(0.038, min: 8, max: 13),
                  letterSpacing: compact ? 1.1 : 1.7,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Positioned(
              left: left,
              top: h * 0.19,
              width: w * 0.43,
              child: _BalanceLine(
                amount: balance,
                showBalance: showBalance,
                fontSize: scaled(0.105, min: 23, max: 38),
                onToggle: onToggleBalance,
              ),
            ),
            Positioned(
              top: h * 0.09,
              right: right + w * 0.01,
              child: Icon(
                Icons.contactless,
                size: scaled(0.105, min: 24, max: 37),
                color: Colors.white.withValues(alpha: 0.94),
              ),
            ),
            Positioned(
              top: h * 0.355,
              right: w * 0.105,
              child: _Chip(width: scaled(0.175, min: 45, max: 68)),
            ),
            Positioned(
              left: left,
              top: h * 0.425,
              width: w * 0.46,
              child: _BrandLine(
                fontSize: scaled(0.118, min: 23, max: 43),
                compact: compact,
              ),
            ),
            Positioned(
              left: left,
              top: h * 0.625,
              width: w * 0.44,
              child: Text(
                '\u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022  4092',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    AppTypography.amount(
                      context,
                      fontSize: scaled(0.052, min: 13, max: 21),
                      color: Colors.white.withValues(alpha: 0.80),
                    ).copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: compact ? 1.7 : 2.8,
                    ),
              ),
            ),
            Positioned(
              left: left,
              right: right + w * 0.055,
              top: h * 0.775,
              child: _ReferenceMetadataRow(
                name: cardholderName,
                availableAmount: availableAmount,
                labelSize: scaled(0.031, min: 7.5, max: 11.5),
                valueSize: scaled(0.043, min: 10.5, max: 16.5),
                compact: compact,
              ),
            ),
            Positioned(
              right: right,
              top: h * 0.805,
              child: Icon(
                AppIcons.chevronRight,
                size: scaled(0.084, min: 20, max: 30),
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BalanceLine extends StatelessWidget {
  const _BalanceLine({
    required this.amount,
    required this.showBalance,
    required this.fontSize,
    required this.onToggle,
  });

  final double amount;
  final bool showBalance;
  final double fontSize;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: FittedBox(
              key: ValueKey(showBalance),
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                showBalance ? Formatters.currency(amount) : '******',
                maxLines: 1,
                style: AppTypography.amount(
                  context,
                  fontSize: fontSize,
                  color: Colors.white,
                ).copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2),
              ),
            ),
          ),
        ),
        SizedBox(width: fontSize * 0.22),
        IconButton(
          visualDensity: VisualDensity.compact,
          constraints: BoxConstraints.tightFor(
            width: fontSize * 0.74,
            height: fontSize * 0.74,
          ),
          padding: EdgeInsets.zero,
          tooltip: showBalance ? 'Hide balance' : 'Show balance',
          onPressed: onToggle,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              showBalance
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              key: ValueKey(showBalance),
              size: fontSize * 0.52,
              color: Colors.white.withValues(alpha: 0.58),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandLine extends StatelessWidget {
  const _BrandLine({required this.fontSize, required this.compact});

  final double fontSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      height: 1,
      letterSpacing: compact ? 3.2 : 5.4,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.62),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE2E2E5),
          const Color(0xFFAAAAB0),
          const Color(0xFFE9E9EB),
          const Color(0xFF8B8B92),
          const Color(0xFF414247),
        ],
        stops: const [0, 0.36, 0.50, 0.70, 1],
      ).createShader(bounds),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          'SPENDLY',
          maxLines: 1,
          style: style?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _ReferenceMetadataRow extends StatelessWidget {
  const _ReferenceMetadataRow({
    required this.name,
    required this.availableAmount,
    required this.labelSize,
    required this.valueSize,
    required this.compact,
  });

  final String name;
  final double availableAmount;
  final double labelSize;
  final double valueSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final available = Formatters.currency(availableAmount);
    final baseValueStyle = AppTypography.amount(
      context,
      fontSize: valueSize,
      color: Colors.white.withValues(alpha: 0.88),
    ).copyWith(fontWeight: FontWeight.w500);
    final availableStyle = baseValueStyle.copyWith(
      color: Colors.white.withValues(alpha: 0.96),
      fontWeight: FontWeight.w600,
    );

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _MetaItem(
            label: 'CARDHOLDER',
            value: _cardholder(name),
            labelSize: labelSize,
            valueStyle: baseValueStyle,
          ),
        ),
        _MetadataDivider(labelSize: labelSize),
        Expanded(
          flex: 4,
          child: _MetaItem(
            label: 'VALID THRU',
            value: '12/28',
            labelSize: labelSize,
            valueStyle: baseValueStyle,
          ),
        ),
        _MetadataDivider(labelSize: labelSize),
        Expanded(
          flex: 5,
          child: _MetaItem(
            label: compact ? 'AVAILABLE' : 'AVAILABLE LIMIT',
            value: available,
            labelSize: labelSize,
            valueStyle: availableStyle,
          ),
        ),
      ],
    );
  }

  static String _cardholder(String name) {
    final clean = name.trim().isEmpty ? 'SPENDLY USER' : name.trim();
    return clean.toUpperCase();
  }
}

class _MetadataDivider extends StatelessWidget {
  const _MetadataDivider({required this.labelSize});

  final double labelSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: labelSize * 4.8,
      margin: EdgeInsets.only(right: labelSize * 2.8),
      color: Colors.white.withValues(alpha: 0.11),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.label,
    required this.value,
    required this.labelSize,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final double labelSize;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.metadata(context).copyWith(
            color: Colors.white.withValues(alpha: 0.42),
            fontSize: labelSize,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: labelSize * 0.45),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, maxLines: 1, style: valueStyle),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 0.68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE1E1E1),
            Color(0xFF9A9A9A),
            Color(0xFFEDEDED),
            Color(0xFF777777),
          ],
          stops: [0, 0.36, 0.66, 1],
        ),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CustomPaint(painter: _ChipPainter()),
    );
  }
}

class _BlackCardPainter extends CustomPainter {
  const _BlackCardPainter({
    required this.sheenProgress,
    required this.isLifted,
  });

  final double sheenProgress;
  final bool isLifted;

  @override
  void paint(Canvas canvas, Size size) {
    final purpleGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.76, 0.20),
        radius: 0.55,
        colors: [
          const Color(0xFF5D42BE).withValues(alpha: isLifted ? 0.28 : 0.22),
          const Color(0xFF2D1E61).withValues(alpha: isLifted ? 0.11 : 0.08),
          Colors.transparent,
        ],
        stops: const [0, 0.38, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, purpleGlow);

    final diagonal = Path()
      ..moveTo(size.width * 0.82, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.58, size.height)
      ..close();
    canvas.drawPath(
      diagonal,
      Paint()..color = Colors.black.withValues(alpha: 0.50),
    );

    final purpleStreak = Path()
      ..moveTo(size.width * 0.86, 0)
      ..lineTo(size.width * 0.94, 0)
      ..lineTo(size.width * 0.74, size.height)
      ..lineTo(size.width * 0.62, size.height)
      ..close();
    canvas.drawPath(
      purpleStreak,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.white.withValues(alpha: 0.045),
            const Color(0xFF5032AE).withValues(alpha: 0.19),
            Colors.transparent,
          ],
          stops: const [0, 0.52, 1],
        ).createShader(Offset.zero & size),
    );

    final reflection = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.78, size.height * 0.11)
      ..lineTo(size.width * 0.08, size.height * 0.15)
      ..close();
    canvas.drawPath(
      reflection,
      Paint()..color = Colors.white.withValues(alpha: 0.032),
    );

    final materialVeil = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.030),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.30),
        ],
        stops: const [0, 0.46, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, materialVeil);

    final sheenX = size.width * (-0.35 + sheenProgress * 1.55);
    final sheen = Path()
      ..moveTo(sheenX, 0)
      ..lineTo(sheenX + size.width * 0.12, 0)
      ..lineTo(sheenX - size.width * 0.08, size.height)
      ..lineTo(sheenX - size.width * 0.20, size.height)
      ..close();
    canvas.drawPath(
      sheen,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.000),
            Colors.white.withValues(alpha: 0.026),
            Colors.white.withValues(alpha: 0.000),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Offset.zero & size),
    );

    final bottomShade = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomRight,
        radius: 1.1,
        colors: [Colors.white.withValues(alpha: 0.032), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bottomShade);

    final topLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * 0.04, 1),
      Offset(size.width * 0.96, 1),
      topLine,
    );
  }

  @override
  bool shouldRepaint(covariant _BlackCardPainter oldDelegate) {
    return oldDelegate.sheenProgress != sheenProgress ||
        oldDelegate.isLifted != isLifted;
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black.withValues(alpha: 0.34);

    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = math.min(size.width, size.height) * 0.25;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: radius * 1.75,
          height: radius * 2.25,
        ),
        Radius.circular(radius * 0.35),
      ),
      paint,
    );

    for (final y in [0.25, 0.5, 0.75]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width * 0.32, size.height * y),
        paint,
      );
      canvas.drawLine(
        Offset(size.width * 0.68, size.height * y),
        Offset(size.width, size.height * y),
        paint,
      );
    }
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height * 0.24),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.76),
      Offset(size.width * 0.5, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
