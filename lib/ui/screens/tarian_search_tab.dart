import 'package:flutter/material.dart';
import '../data/saman_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'saman_detail_screen.dart';

class TarianTab extends StatefulWidget {
  const TarianTab({super.key});
  @override
  State<TarianTab> createState() => _TarianTabState();
}

class _TarianTabState extends State<TarianTab> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String _query = '';
  int _filter = 0;

  static const _filters = ['Semua', 'Pemula', 'Menengah', 'Mahir'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String q) {
    final v = q.trim();
    if (v.isEmpty) return;
    setState(() => _query = v);
    _ctrl.text = v;
    AppState.instance.addSearch(v);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (_, _) => Column(children: [
        _searchBar(),
        _filterChips(),
        if (_query.isEmpty)
          Expanded(child: _discover())
        else
          Expanded(child: _results()),
      ]),
    );
  }

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: C.line)),
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                textInputAction: TextInputAction.search,
                onSubmitted: _submit,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Cari tarian, gerakan, modul...',
                  icon: const Icon(Icons.search, color: C.muted),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _ctrl.clear();
                            setState(() => _query = '');
                          }),
                ),
              ),
            ),
          ),
        ]),
      );

  Widget _filterChips() => SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filters.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => setState(() => _filter = i),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _filter == i ? C.purple : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: _filter == i ? C.purple : C.line),
              ),
              child: Center(
                child: Text(_filters[i],
                    style: TextStyle(
                        color: _filter == i ? Colors.white : C.ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      );

  // ============ DISCOVER (empty query) ============
  Widget _discover() {
    final s = AppState.instance;
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // Recent searches
          if (s.recentSearches.isNotEmpty) ...[
            Row(children: [
              const Expanded(
                  child: Text('Pencarian Terakhir',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15))),
              TextButton(
                onPressed: () => s.clearSearches(),
                child: const Text('Hapus Semua',
                    style: TextStyle(
                        color: C.orange, fontWeight: FontWeight.w700)),
              ),
            ]),
            for (final q in s.recentSearches)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading:
                    const Icon(Icons.history, color: C.muted, size: 20),
                title: Text(q,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 16, color: C.muted),
                  onPressed: () => s.removeSearch(q),
                ),
                onTap: () => _submit(q),
              ),
            const SizedBox(height: 16),
          ],

          // ============ MODUL BELAJAR ============
          Row(children: [
            const Icon(Icons.menu_book, color: C.purple, size: 18),
            const SizedBox(width: 6),
            const Expanded(
                child: Text('Modul Belajar',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15))),
            Pill('${_modul.length} modul',
                fg: C.purple, bg: C.purpleSoft),
          ]),
          const SizedBox(height: 10),
          for (final m in _modul) ...[
            _modulCard(m),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),

          // ============ VARIASI CEPAT ============
          const Row(children: [
            Icon(Icons.school, color: C.purple, size: 18),
            SizedBox(width: 6),
            Text('Variasi Tari Saman',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ]),
          const SizedBox(height: 10),
          for (var i = 0; i < samanVariations.length; i++) ...[
            _variasiCard(i, samanVariations[i]),
            const SizedBox(height: 8),
          ],
        ]);
  }

  Widget _modulCard(_Modul m) => GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => SamanDetailScreen(initial: m.varIdx))),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.line),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: m.color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(m.icon, color: m.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(m.subtitle,
                        style: const TextStyle(
                            color: C.muted, fontSize: 12)),
                  ]),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: C.muted),
          ]),
        ),
      );

  Widget _variasiCard(int i, Variation v) => GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => SamanDetailScreen(initial: i))),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.line),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: C.purpleSoft,
                  borderRadius: BorderRadius.circular(10)),
              child:
                  const Icon(Icons.music_note, color: C.purple, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Variasi ${v.level.label}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13.5)),
                    Text('${v.moves.length} gerakan • ${v.totalSec.round()} dtk',
                        style: const TextStyle(
                            color: C.muted, fontSize: 11.5)),
                  ]),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 12, color: C.muted),
          ]),
        ),
      );

  // ============ RESULTS ============
  Widget _results() {
    final q = _query.toLowerCase();
    final levelFilter = _filter == 0 ? null : Level.values[_filter - 1];

    // Cari variasi
    final variasiHits = <({int index, Variation v})>[];
    for (var i = 0; i < samanVariations.length; i++) {
      final v = samanVariations[i];
      if (levelFilter != null && v.level != levelFilter) continue;
      if ('tari saman'.contains(q) ||
          'saman'.contains(q) ||
          v.level.label.toLowerCase().contains(q) ||
          v.focus.toLowerCase().contains(q) ||
          v.moves.any((m) =>
              m.name.toLowerCase().contains(q) ||
              m.stage.toLowerCase().contains(q))) {
        variasiHits.add((index: i, v: v));
      }
    }

    // Cari modul
    final modulHits = _modul
        .where((m) =>
            m.title.toLowerCase().contains(q) ||
            m.subtitle.toLowerCase().contains(q))
        .toList();

    if (variasiHits.isEmpty && modulHits.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.search_off, size: 60, color: C.line),
          const SizedBox(height: 10),
          Text('Tidak ada hasil untuk "$_query"',
              style: const TextStyle(color: C.muted)),
        ]),
      );
    }

    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('${variasiHits.length + modulHits.length} hasil',
              style: const TextStyle(color: C.muted, fontSize: 12.5)),
          const SizedBox(height: 12),

          if (modulHits.isNotEmpty) ...[
            const Text('Modul',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: C.muted)),
            const SizedBox(height: 8),
            for (final m in modulHits) ...[
              _modulCard(m),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
          ],

          if (variasiHits.isNotEmpty) ...[
            const Text('Variasi Tari Saman',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: C.muted)),
            const SizedBox(height: 8),
            for (final h in variasiHits) ...[
              _variasiCard(h.index, h.v),
              const SizedBox(height: 8),
            ],
          ],
        ]);
  }

  // ============ DATA MODUL ============
  List<_Modul> get _modul => const [
        _Modul(
          title: 'Dasar Gerakan Saman',
          subtitle: 'Pengenalan tepukan & postur dasar',
          icon: Icons.school,
          color: C.purple,
          varIdx: 0,
        ),
        _Modul(
          title: 'Tempo & Ritme',
          subtitle: 'Melatih kecepatan tepukan dada',
          icon: Icons.speed,
          color: C.orange,
          varIdx: 1,
        ),
        _Modul(
          title: 'Formasi & Dinamika',
          subtitle: 'Sinkronisasi gerakan kelompok',
          icon: Icons.groups,
          color: C.green,
          varIdx: 2,
        ),
      ];
}

class _Modul {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int varIdx;
  const _Modul({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.varIdx,
  });
}
