import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';

/// Splash screen yang muncul 1.8 detik sebelum masuk ke Shell.
class SplashScreen extends StatefulWidget {
  final Widget next;
  const SplashScreen({super.key, required this.next});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _scale = Tween(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    _ctrl.forward();

    Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, _, _) => widget.next,
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [C.purpleDark, C.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .15),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: .3),
                          width: 2),
                    ),
                    child: const Icon(Icons.self_improvement,
                        size: 72, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text('Belajar Bareng',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Eksplorasi Seni Tari Nusantara',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: .75),
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
