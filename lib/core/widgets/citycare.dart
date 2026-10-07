import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// CityCare component library. Screens compose these instead of styling
/// raw Material widgets, so the brand stays consistent everywhere.

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

/// Primary action: blue gradient pill, white label, optional trailing arrow.
/// Handles pressed (scale), disabled and loading states.
class CityCareButton extends StatefulWidget {
  const CityCareButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingArrow = false,
    this.busy = false,
    this.accentRing = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool trailingArrow;
  final bool busy;

  /// A thin lime ring — reserved for the single most important CTA on a
  /// screen (e.g. Book Appointment).
  final bool accentRing;

  @override
  State<CityCareButton> createState() => _CityCareButtonState();
}

class _CityCareButtonState extends State<CityCareButton> {
  bool _down = false;

  bool get _enabled => widget.onPressed != null && !widget.busy;

  @override
  Widget build(BuildContext context) {
    final content = widget.busy
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.trailingArrow) ...[
                const SizedBox(width: 10),
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: CityCareColors.lime,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: CityCareColors.navy,
                  ),
                ),
              ],
            ],
          );

    final button = AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: const Duration(milliseconds: 110),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: widget.onPressed == null ? 0.45 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: CityCareGradients.button,
            borderRadius: BorderRadius.circular(CityCareRadius.pill),
            boxShadow: _enabled ? CityCareShadows.glow : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(CityCareRadius.pill),
              onTap: _enabled ? widget.onPressed : null,
              onHighlightChanged: (v) => setState(() => _down = v),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 54),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  child: Center(child: content),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        child: widget.accentRing
            ? DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(CityCareRadius.pill),
                  border: Border.all(color: CityCareColors.lime, width: 3),
                ),
                child: Padding(padding: const EdgeInsets.all(2), child: button),
              )
            : button,
      ),
    );
  }
}

/// Secondary action: white pill with a blue outline.
class CityCareOutlinedButton extends StatelessWidget {
  const CityCareOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: icon == null
          ? OutlinedButton(onPressed: onPressed, child: Text(label))
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Surfaces
// ---------------------------------------------------------------------------

/// White rounded card with a hairline border and generous padding.
class CityCareCard extends StatelessWidget {
  const CityCareCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(CityCareSpacing.lg),
    this.color = CityCareColors.surface,
    this.elevated = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(CityCareRadius.lg);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: elevated ? CityCareShadows.soft : null,
      ),
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: CityCareColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Very light blue page wash with soft mint and lime glows, like daylight
/// behind the content. Purely decorative.
class CityCareBackground extends StatelessWidget {
  const CityCareBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: CityCareGradients.soft),
      child: Stack(
        children: [
          const Positioned(
            top: -120,
            right: -100,
            child: _Glow(color: CityCareColors.mint, size: 320),
          ),
          const Positioned(
            bottom: -140,
            left: -120,
            child: _Glow(color: Color(0x99E8FF6A), size: 300),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

/// Large white rounded search field with a soft shadow and a clear button.
class CityCareSearchBar extends StatefulWidget {
  const CityCareSearchBar({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  State<CityCareSearchBar> createState() => _CityCareSearchBarState();
}

class _CityCareSearchBarState extends State<CityCareSearchBar> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(CityCareRadius.pill),
      borderSide: BorderSide.none,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CityCareRadius.pill),
        boxShadow: CityCareShadows.soft,
      ),
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.search,
        onChanged: (v) {
          setState(() {});
          widget.onChanged?.call(v);
        },
        onSubmitted: widget.onSubmitted,
        style: const TextStyle(fontSize: 15, color: CityCareColors.ink),
        decoration: InputDecoration(
          hintText: widget.hint,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 18, right: 10),
            child: Icon(Icons.search_rounded, color: CityCareColors.primary),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _controller.clear();
                    setState(() {});
                    widget.onChanged?.call('');
                    widget.onSubmitted?.call('');
                  },
                ),
          border: border,
          enabledBorder: border,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CityCareRadius.pill),
            borderSide: const BorderSide(
              color: CityCareColors.primary,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

/// Selectable pill (filters, choices). Selected = soft blue with a tiny lime
/// dot, so state never relies on colour alone.
class CityCareChip extends StatelessWidget {
  const CityCareChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.busy = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? CityCareColors.primarySoft : CityCareColors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? CityCareColors.primary : CityCareColors.border,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      icon,
                      size: 17,
                      color: selected
                          ? CityCareColors.primaryDark
                          : CityCareColors.inkMuted,
                    ),
                  ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? CityCareColors.primaryDark
                        : CityCareColors.ink,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: CityCareColors.lime,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0x3312324A), blurRadius: 2),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Motion
// ---------------------------------------------------------------------------

/// Gentle entrance: fade + slight upward slide. [index] staggers lists.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 40 * math.min(widget.index, 6));
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _t,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(_t),
        child: widget.child,
      ),
    );
  }
}

/// Pulsing "live" dot for the queue.
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, this.color = CityCareColors.lime, this.size = 10});

  final Color color;
  final double size;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 2.4,
      height: s * 2.4,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: s * (1 + 1.4 * _c.value),
              height: s * (1 + 1.4 * _c.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.5 * (1 - _c.value)),
              ),
            ),
            Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Brand
// ---------------------------------------------------------------------------

/// The CityCare mark: a location pin (place) holding a small city skyline
/// (city) under a lime sun (care, warmth). Works without the wordmark, so it
/// doubles as the app icon artwork.
class CityCareLogo extends StatelessWidget {
  const CityCareLogo({super.key, this.size = 40, this.onDark = false});

  final double size;

  /// White pin with blue skyline, for gradient backgrounds.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'CityCare',
      image: true,
      child: CustomPaint(
        size: Size(size * 0.82, size),
        painter: _LogoPainter(onDark: onDark),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.onDark});

  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 0.48;
    final c = Offset(w / 2, r + h * 0.02);
    final tip = Offset(w / 2, h * 0.98);

    // Pin silhouette: circle + two tangents meeting at the tip.
    final d = (tip - c).distance;
    final phi = math.acos(r / d);
    final rect = Rect.fromCircle(center: c, radius: r);
    final pin = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        c.dx + r * math.cos(math.pi / 2 + phi),
        c.dy + r * math.sin(math.pi / 2 + phi),
      )
      ..arcTo(rect, math.pi / 2 + phi, 2 * math.pi - 2 * phi, false)
      ..close();

    final pinPaint = Paint();
    if (onDark) {
      pinPaint.color = Colors.white;
    } else {
      pinPaint.shader = CityCareGradients.hero.createShader(Offset.zero & size);
    }
    canvas.drawPath(pin, pinPaint);

    // Inner window.
    final inner = r * 0.66;
    final windowPaint = Paint()
      ..color = onDark ? CityCareColors.primarySoft : Colors.white;
    canvas.drawCircle(c, inner, windowPaint);

    // Skyline, clipped to the window.
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: inner)));
    final base = c.dy + inner * 0.62;
    final bar = Paint()..color = CityCareColors.primary;
    final barW = inner * 0.36;
    void building(double x, double height) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, base - height, barW, height + inner),
          topLeft: Radius.circular(barW * 0.25),
          topRight: Radius.circular(barW * 0.25),
        ),
        bar,
      );
    }

    building(c.dx - barW * 1.6, inner * 0.62);
    building(c.dx - barW * 0.5, inner * 1.0);
    building(c.dx + barW * 0.6, inner * 0.78);
    canvas.restore();

    // Lime sun — the "care" accent.
    canvas.drawCircle(
      Offset(c.dx + inner * 0.52, c.dy - inner * 0.5),
      inner * 0.2,
      Paint()..color = CityCareColors.lime,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.onDark != onDark;
}

/// Logo + "CityCare" wordmark.
class CityCareWordmark extends StatelessWidget {
  const CityCareWordmark({super.key, this.size = 34, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CityCareLogo(size: size, onDark: onDark),
        SizedBox(width: size * 0.28),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'City',
                style: TextStyle(
                  color: onDark ? Colors.white : CityCareColors.ink,
                ),
              ),
              TextSpan(
                text: 'Care',
                style: TextStyle(
                  color: onDark ? CityCareColors.lime : CityCareColors.primary,
                ),
              ),
            ],
          ),
          style: TextStyle(
            fontSize: size * 0.62,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
