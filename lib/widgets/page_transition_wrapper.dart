import 'package:flutter/material.dart';

class PageTransitionWrapper extends StatefulWidget {
  const PageTransitionWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  State<PageTransitionWrapper> createState() => _PageTransitionWrapperState();
}

class _PageTransitionWrapperState extends State<PageTransitionWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();

    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(curvedAnimation);
    _scaleAnimation = Tween<double>(begin: 0.98, end: 1).animate(curvedAnimation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}
