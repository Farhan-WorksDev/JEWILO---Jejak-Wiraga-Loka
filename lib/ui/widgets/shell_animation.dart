import 'package:flutter/widgets.dart';

/// InheritedWidget yang bawa animasi tab dari Shell ke tiap page.
class ShellAnimation extends InheritedWidget {
  final AnimationController controller;
  final Animation<double> slide;
  final Animation<double> fade;

  const ShellAnimation({
    super.key,
    required this.controller,
    required this.slide,
    required this.fade,
    required super.child,
  });

  static ShellAnimation of(BuildContext context) {
    final res =
        context.dependOnInheritedWidgetOfExactType<ShellAnimation>();
    assert(res != null, 'ShellAnimation tidak ditemukan di context');
    return res!;
  }

  static ShellAnimation? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellAnimation>();

  @override
  bool updateShouldNotify(ShellAnimation old) =>
      controller != old.controller ||
      slide != old.slide ||
      fade != old.fade;
}

/// Sudah tidak dipakai. Dibiarkan sebagai passthrough supaya file lain
/// (mis. common.dart) yang masih memanggilnya tidak error.
/// Header sekarang otomatis statis karena body tidak dianimasi lagi.
class ShellSlideCounter extends StatelessWidget {
  final Widget child;
  const ShellSlideCounter({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

/// Bungkus isi halaman / hero. Header JANGAN dibungkus.
class SlideUpFade extends StatelessWidget {
  final Widget child;
  const SlideUpFade({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final anim = ShellAnimation.maybeOf(context);
    if (anim == null) return child;

    return AnimatedBuilder(
      animation: anim.controller,
      builder: (context, c) => Opacity(
        opacity: anim.fade.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, anim.slide.value),
          child: c,
        ),
      ),
      child: child,
    );
  }
}