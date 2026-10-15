import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'sanggar_detail_screen.dart';

/// Tab "Sanggar" — cari sanggar tari dari Firestore.
/// Butuh Mode Online. Kalau offline → kasih pesan.
class SanggarSearchScreen extends StatefulWidget {
  const SanggarSearchScreen({super.key});
  @override
  State<SanggarSearchScreen> createState() => _SanggarSearchScreenState();
}

class _SanggarSearchScreenState extends State<SanggarSearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  bool _loading = true;
  List<Map<String, dynamic>> _list = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final data = await AuthService.instance.fetchSanggarList();
    if (!mounted) return;
    setState(() {
      _list = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    if (s.isOffline) return _offlineMessage();
    return Column(children: [
      _searchBar(),
      Expanded(child: _body()),
    ]);
  }

  Widget _offlineMessage() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: C.orangeSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off,
                    size: 56, color: C.orange),
              ),
              const SizedBox(height: 20),
              const Text('Butuh Mode Online',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: C.ink)),
              const SizedBox(height: 8),
              const Text(
                'Fitur cari sanggar tari hanya tersedia di Mode Online. '
                'Ganti ke Mode Online di Pengaturan untuk mengaksesnya.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: C.muted, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      );

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: C.line),
          ),
          child: TextField(
            controller: _ctrl,
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Cari sanggar berdasarkan nama / wilayah...',
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
      );

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: C.purple));
    }
    if (_list.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.search_off, size: 60, color: C.line),
          const SizedBox(height: 10),
          const Text('Belum ada sanggar terdaftar',
              style: TextStyle(color: C.muted)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _fetch,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Muat ulang'),
          ),
        ]),
      );
    }

    final q = _query.toLowerCase().trim();
    final filtered = q.isEmpty
        ? _list
        : _list.where((sg) {
            final name = (sg['name'] ?? '').toString().toLowerCase();
            final region = (sg['region'] ?? '').toString().toLowerCase();
            final tarian = (sg['tarian'] ?? []).toString().toLowerCase();
            return name.contains(q) ||
                region.contains(q) ||
                tarian.contains(q);
          }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.search_off, size: 60, color: C.line),
          const SizedBox(height: 10),
          Text('Tidak ada sanggar untuk "$_query"',
              style: const TextStyle(color: C.muted)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      color: C.purple,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: filtered.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${filtered.length} sanggar ditemukan',
                  style: const TextStyle(color: C.muted, fontSize: 12)),
            );
          }
          return _sanggarCard(filtered[i - 1]);
        },
      ),
    );
  }

  Widget _sanggarCard(Map<String, dynamic> sg) {
    final name = sg['name'] ?? 'Sanggar';
    final region = sg['region'] ?? '-';
    final tarian = sg['tarian'] is List
        ? (sg['tarian'] as List).join(', ')
        : sg['tarian']?.toString() ?? '-';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SanggarDetailScreen(sanggar: sg),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: C.purpleSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.home_work, color: C.purple, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.location_on,
                      size: 12, color: C.muted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(region,
                        style: const TextStyle(
                            color: C.muted, fontSize: 11.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const SizedBox(height: 2),
                Text('Tarian: $tarian',
                    style:
                        const TextStyle(color: C.muted, fontSize: 11.5)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: C.muted),
        ]),
      ),
    );
  }
}