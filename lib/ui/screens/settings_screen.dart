import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => ListView(padding: EdgeInsets.zero, children: [
        const GradientHeader(
          title: 'Pengaturan',
          subtitle: 'Semua data tersimpan di HP kamu',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(children: [
            // === PROFIL ===
            _section('Profil', [
              Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                      color: C.purpleSoft, shape: BoxShape.circle),
                  child: Icon(
                      s.isPelatih
                          ? Icons.groups_outlined
                          : Icons.school_outlined,
                      color: C.purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(
                            s.isPelatih
                                ? 'Pelatih • ${s.currentSanggar?.name ?? "-"}'
                                : (s.inSanggar
                                    ? 'Siswa • ${s.currentSanggar?.name ?? "-"}'
                                    : 'Siswa Mandiri'),
                            style: const TextStyle(
                                color: C.muted, fontSize: 12.5)),
                      ]),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: s.name,
                decoration: InputDecoration(
                    labelText: 'Nama panggilan',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: C.bg),
                onChanged: (v) => s.update(
                    () => s.name = v.trim().isEmpty ? 'Penari' : v.trim()),
              ),
            ]),
            const SizedBox(height: 12),

            // === PEMICU HARIAN ===
            _section('Pemicu Harian', [
              _switchRow(
                title: 'Pengingat latihan',
                sub: 'Setiap pukul ${s.reminderLabel}',
                value: s.reminderOn,
                onChanged: (v) => s.update(() => s.reminderOn = v),
              ),
              _tapRow(
                title: 'Jam latihan',
                trailing: s.reminderLabel,
                onTap: () async {
                  final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                          hour: s.reminderHour, minute: s.reminderMinute));
                  if (t != null) {
                    s.update(() {
                      s.reminderHour = t.hour;
                      s.reminderMinute = t.minute;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: s.habitCue,
                decoration: InputDecoration(
                    labelText: 'Setelah aku ...',
                    helperText: 'Kebiasaan pemicu latihan',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: C.bg),
                onChanged: (v) => s.update(() => s.habitCue = v),
              ),
            ]),
            const SizedBox(height: 12),

            // === KAMERA ===
            _section('Kamera & Deteksi', [
              const Text('Frame rate (FPS)',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('FPS tinggi = deteksi lebih halus, tapi boros baterai',
                  style: TextStyle(color: C.muted, fontSize: 12)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: C.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: C.line)),
                child: Row(
                  children: [
                    for (final fps in [15, 24, 30, 60])
                      Expanded(
                        child: GestureDetector(
                          onTap: () => s.update(() => s.fps = fps),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: s.fps == fps
                                  ? C.purple
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text('$fps',
                                  style: TextStyle(
                                      color: s.fps == fps
                                          ? Colors.white
                                          : C.ink,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // === AUDIO ===
            _section('Audio', [
              _switchRow(
                title: 'Metronom ketukan',
                sub: 'Bunyi tempo sesuai detik per gerakan',
                value: s.metronome,
                onChanged: (v) => s.update(() => s.metronome = v),
              ),
              _switchRow(
                title: 'Panduan suara pelatih',
                sub: 'Instruksi suara offline',
                value: s.voiceGuide,
                onChanged: (v) => s.update(() => s.voiceGuide = v),
              ),
            ]),
            const SizedBox(height: 24),

            // === RESET ===
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                    foregroundColor: C.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                            color: C.red.withValues(alpha: .3)))),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Reset Semua Progres',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('Reset semua progres?',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 17)),
                      content: const Text(
                          'Streak, XP, lencana, dan variasi yang selesai akan dihapus.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal')),
                        FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: C.red),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Reset')),
                      ],
                    ),
                  );
                  if (ok == true) await s.resetProgress();
                },
              ),
            ),
            const SizedBox(height: 12),

            // === LOGOUT ===
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                    foregroundColor: C.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                            color: C.purple.withValues(alpha: .3)))),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Keluar dari Akun',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('Keluar dari akun?',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 17)),
                      content: const Text(
                          'Data latihan kamu tetap tersimpan. Kamu bisa masuk lagi dengan nama yang sama.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal')),
                        FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: C.purple),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Keluar')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await s.logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text('Versi 1.0.0 • Mode offline',
                style: TextStyle(color: C.muted, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: C.line),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 12),
              ...children,
            ]),
      );

  Widget _switchRow({
    required String title,
    required String sub,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13.5)),
                  Text(sub,
                      style: const TextStyle(color: C.muted, fontSize: 12)),
                ]),
          ),
          Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: C.purple),
        ]),
      );

  Widget _tapRow({
    required String title,
    required String trailing,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13.5)),
            ),
            Text(trailing,
                style: const TextStyle(
                    color: C.purple, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: C.muted),
          ]),
        ),
      );
}
