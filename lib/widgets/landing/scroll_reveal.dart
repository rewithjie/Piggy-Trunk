import 'package:flutter/material.dart';

/// A widget that reveals its child with a smooth slide-up and fade-in animation
/// as soon as it scrolls into the viewport.
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
    this.duration = const Duration(milliseconds: 650),
    this.offset = const Offset(0, 32),
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

        // If top of widget enters within 90% of screen height
        // and hasn't completely scrolled past the top
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
        // Safe catch during transient layout phases
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

/// A subtle continuous floating breathing animation widget for mockups and badges
class FloatingWidget extends StatefulWidget {
  final Widget child;
  final double offsetY;
  final Duration duration;

  const FloatingWidget({
    super.key,
    required this.child,
    this.offsetY = 6.0,
    this.duration = const Duration(milliseconds: 3200),
  });

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -widget.offsetY,
      end: widget.offsetY,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A wrapper that elevates cards slightly with a smooth transform and shadow on mouse hover
class HoverCard extends StatefulWidget {
  final Widget child;
  final double translateY;
  final double hoverScale;
  final Duration duration;

  const HoverCard({
    super.key,
    required this.child,
    this.translateY = -6.0,
    this.hoverScale = 1.0,
    this.duration = const Duration(milliseconds: 220),
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
      cursor: SystemMouseCursors.basic,
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

/// A sleek gradient progress bar fixed below the navigation bar tracking scroll progress
class ScrollProgressBar extends StatefulWidget {
  final ScrollController scrollController;
  final List<Color>? gradientColors;
  final double height;

  const ScrollProgressBar({
    super.key,
    required this.scrollController,
    this.gradientColors,
    this.height = 3.0,
  });

  @override
  State<ScrollProgressBar> createState() => _ScrollProgressBarState();
}

class _ScrollProgressBarState extends State<ScrollProgressBar> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_updateProgress);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_updateProgress);
    super.dispose();
  }

  void _updateProgress() {
    if (!widget.scrollController.hasClients) return;
    final maxScroll = widget.scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    final currentScroll = widget.scrollController.offset.clamp(0.0, maxScroll);
    final newProgress = currentScroll / maxScroll;
    if ((newProgress - _progress).abs() > 0.003) {
      setState(() {
        _progress = newProgress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_progress <= 0.001) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        return Container(
          width: double.infinity,
          height: widget.height,
          color: Colors.transparent,
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            curve: Curves.easeOut,
            width: totalWidth * _progress,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.gradientColors ??
                    const [
                      Color(0xFF2563EB),
                      Color(0xFF0284C7),
                      Color(0xFF10B981),
                    ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
