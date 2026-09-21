import 'package:flutter/material.dart';

/// A widget that reveals its child with a smooth slide-up and fade-in animation
/// as soon as it scrolls into the viewport.
/// Works seamlessly on both desktop browsers and mobile touch screens.
class ScrollReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;
  final bool fadeOnly;

  const ScrollReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.offset = const Offset(0, 28),
    this.curve = Curves.easeOutCubic,
    this.fadeOnly = false,
  });

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  ScrollPosition? _scrollPosition;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.fadeOnly ? Offset.zero : widget.offset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_checkVisibility);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_checkVisibility);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkVisibility();
    });
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_checkVisibility);
    _controller.dispose();
    super.dispose();
  }

  void _checkVisibility() {
    if (_revealed || !mounted) return;

    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      try {
        final position = renderObject.localToGlobal(Offset.zero);
        final screenHeight = MediaQuery.of(context).size.height;

        // Triggers smoothly when top enters within 92% of viewport height
        if (position.dy < screenHeight * 0.92 &&
            (position.dy + renderObject.size.height) > 0) {
          _revealed = true;
          _scrollPosition?.removeListener(_checkVisibility);

          if (widget.delay == Duration.zero) {
            _controller.forward();
          } else {
            Future.delayed(widget.delay, () {
              if (mounted) _controller.forward();
            });
          }
        }
      } catch (_) {
        // Safe fallback during transient layout passes
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: widget.fadeOnly
              ? child
              : Transform.translate(
                  offset: _slideAnimation.value,
                  child: child,
                ),
        );
      },
      child: widget.child,
    );
  }
}

/// A wrapper that elevates cards slightly with a smooth transform on mouse hover.
/// On desktop it provides tactile elevation feedback; on mobile devices it is passive.
class HoverCard extends StatefulWidget {
  final Widget child;
  final double translateY;
  final Duration duration;

  const HoverCard({
    super.key,
    required this.child,
    this.translateY = -6.0,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          0.0,
          _isHovered ? widget.translateY : 0.0,
          0.0,
        ),
        child: widget.child,
      ),
    );
  }
}
