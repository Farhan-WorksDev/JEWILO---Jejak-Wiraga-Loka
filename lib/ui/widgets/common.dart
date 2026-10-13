import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme.dart';

class GradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? bottom;
  const GradientHeader(
      {super.key, required this.title, required this.subtitle, this.bottom});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 14, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [C.purpleDark, C.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const CircleAvatar(
              radius: 20,
              backgroundColor: C.orange,
              child: Icon(Icons.self_improvement, color: Colors.white)),
          const SizedBox(width: 10),
          const Expanded(
              child: Text('Belajar Bareng',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800))),
          const StreakChip(),
        ]),
        const SizedBox(height: 18),
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: .75))),
        if (bottom != null) ...[const SizedBox(height: 14), bottom!],
      ]),
    );
  }
}

class StreakChip extends StatelessWidget {
  const StreakChip({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: AppState.instance,
        builder: (_, _) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.local_fire_department, color: C.orange, size: 18),
            const SizedBox(width: 4),
            Text('${AppState.instance.currentStreak} Hari',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

class CardBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color? border;
  final EdgeInsets padding;
  const CardBox(
      {super.key,
      required this.child,
      this.color = Colors.white,
      this.border,
      this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border ?? C.line),
          ),
          child: child,
        ),
      );
}

class Pill extends StatelessWidget {
  final String text;
  final Color fg;
  final Color bg;
  final IconData? icon;
  const Pill(this.text,
      {super.key, this.fg = C.purple, this.bg = C.purpleSoft, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4)
          ],
          Flexible(
              child: Text(text,
                  style: TextStyle(
                      color: fg, fontSize: 11.5, fontWeight: FontWeight.w700))),
        ]),
      );
}

class Bar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  const Bar(this.value, {super.key, this.color = C.orange, this.height = 10});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: height,
          backgroundColor: C.purpleSoft,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
        child: Row(children: [
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800))),
          ?trailing,
        ]),
      );
}

String fmtSec(double s) => '${s.toStringAsFixed(1)} dtk';
String fmtDur(num sec) {
  final m = sec ~/ 60;
  final s = (sec % 60).round();
  if (m == 0) return '$s dtk';
  return s == 0 ? '$m mnt' : '$m mnt $s dtk';
}
