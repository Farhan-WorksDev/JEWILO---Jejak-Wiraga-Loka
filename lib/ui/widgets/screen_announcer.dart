import 'dart:async';
import 'package:flutter/material.dart';
import '../services/tts_service.dart';

Timer? _globalAnnounceTimer;

/// Announce halaman saat masuk. Pakai global timer supaya kalau
/// ada beberapa announce berturut-turut, hanya yang terakhir yang jalan.
void announcePage(
  BuildContext context, {
  required String title,
  String? summary,
  Duration delay = const Duration(milliseconds: 450),
}) {
  final mq = MediaQuery.maybeOf(context);
  if (mq?.accessibleNavigation == true) return;

  _globalAnnounceTimer?.cancel();
  _globalAnnounceTimer = Timer(delay, () {
    if (!context.mounted) return;
    final text = (summary == null || summary.isEmpty)
        ? 'Halaman $title.'
        : 'Halaman $title. $summary';
    TtsService.instance.speakNow(text, force: true);
  });
}

/// Announce aksi user — non-blocking, return segera.
void announceAction(String text) {
  if (text.trim().isEmpty) return;
  TtsService.instance.speakNow(text, force: true);
}

class ScreenAnnouncer extends StatefulWidget {
  final String title;
  final String? summary;
  final Widget child;
  final Duration delay;

  const ScreenAnnouncer({
    super.key,
    required this.title,
    this.summary,
    required this.child,
    this.delay = const Duration(milliseconds: 450),
  });

  @override
  State<ScreenAnnouncer> createState() => _ScreenAnnouncerState();
}

class _ScreenAnnouncerState extends State<ScreenAnnouncer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      announcePage(
        context,
        title: widget.title,
        summary: widget.summary,
        delay: widget.delay,
      );
    });
  }

  @override
  void didUpdateWidget(covariant ScreenAnnouncer old) {
    super.didUpdateWidget(old);
    if (old.title != widget.title || old.summary != widget.summary) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        announcePage(
          context,
          title: widget.title,
          summary: widget.summary,
          delay: widget.delay,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}