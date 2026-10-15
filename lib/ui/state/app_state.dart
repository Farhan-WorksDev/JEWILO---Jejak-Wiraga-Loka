import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/saman_data.dart';

const _uuid = Uuid();

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ============================================================
// MODEL SANGGAR
// ============================================================
class Sanggar {
  final String id;
  final String name;
  final String pelatih;
  List<String> siswa;
  final String createdAt;

  Sanggar({
    required this.id,
    required this.name,
    required this.pelatih,
    required this.siswa,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pelatih': pelatih,
        'siswa': siswa,
        'createdAt': createdAt,
      };

  factory Sanggar.fromJson(Map<String, dynamic> m) => Sanggar(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        pelatih: m['pelatih'] ?? '',
        siswa: List<String>.from(m['siswa'] ?? []),
        createdAt: m['createdAt'] ?? '',
      );
}

// ============================================================
// MODEL USER (per profil)
// ============================================================
class UserData {
  final String id;
  String name;
  String role;
  String? sanggarId;
  Set<int> completed;
  int streak;
  int longest;
  String? lastDay;
  Map<String, int> secondsByDay;
  int xp;
  Set<String> badges;
  List<String> recentSearches;
  int fps;
  bool reminderOn;
  int reminderHour;
  int reminderMinute;
  String habitCue;
  bool metronome;
  bool voiceGuide;
  final String createdAt;

  UserData({
    required this.id,
    required this.name,
    required this.role,
    this.sanggarId,
    Set<int>? completed,
    this.streak = 0,
    this.longest = 0,
    this.lastDay,
    Map<String, int>? secondsByDay,
    this.xp = 0,
    Set<String>? badges,
    List<String>? recentSearches,
    this.fps = 30,
    this.reminderOn = true,
    this.reminderHour = 19,
    this.reminderMinute = 30,
    this.habitCue = 'minum teh sore',
    this.metronome = true,
    this.voiceGuide = true,
    required this.createdAt,
  })  : completed = completed ?? {},
        secondsByDay = secondsByDay ?? {},
        badges = badges ?? {},
        recentSearches = recentSearches ?? [];

  // ---- Turunan per-user ----
  int get totalSeconds => secondsByDay.values.fold(0, (a, b) => a + b);
  int get totalMinutes => totalSeconds ~/ 60;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'sanggarId': sanggarId,
        'completed': completed.toList(),
        'streak': streak,
        'longest': longest,
        'lastDay': lastDay,
        'secondsByDay': secondsByDay,
        'xp': xp,
        'badges': badges.toList(),
        'recentSearches': recentSearches,
        'fps': fps,
        'reminderOn': reminderOn,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'habitCue': habitCue,
        'metronome': metronome,
        'voiceGuide': voiceGuide,
        'createdAt': createdAt,
      };

  factory UserData.fromJson(Map<String, dynamic> m) => UserData(
        id: m['id'] ?? _uuid.v4(),
        name: m['name'] ?? 'Penari',
        role: m['role'] ?? 'siswa',
        sanggarId: m['sanggarId'],
        completed: Set<int>.from(m['completed'] ?? []),
        streak: m['streak'] ?? 0,
        longest: m['longest'] ?? 0,
        lastDay: m['lastDay'],
        secondsByDay: Map<String, int>.from(m['secondsByDay'] ?? {}),
        xp: m['xp'] ?? 0,
        badges: Set<String>.from(m['badges'] ?? []),
        recentSearches: List<String>.from(m['recentSearches'] ?? []),
        fps: m['fps'] ?? 30,
        reminderOn: m['reminderOn'] ?? true,
        reminderHour: m['reminderHour'] ?? 19,
        reminderMinute: m['reminderMinute'] ?? 30,
        habitCue: m['habitCue'] ?? 'minum teh sore',
        metronome: m['metronome'] ?? true,
        voiceGuide: m['voiceGuide'] ?? true,
        createdAt: m['createdAt'] ?? DateTime.now().toIso8601String(),
      );
}

// ============================================================
// APPSTATE — DOM-JS style, tapi per user pakai UUID
// ============================================================
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  SharedPreferences? _p;

  // === STATE GLOBAL ===
  /// `Map<userId (UUID), UserData>`
  Map<String, UserData> users = {};

  /// ID user yang aktif, null = belum login
  String? activeUserId;

  /// Daftar sanggar (global)
  List<Sanggar> sanggarList = [];

  // === AKSES ===
  UserData? get current => activeUserId != null ? users[activeUserId] : null;
  bool get hasLoggedIn => activeUserId != null;

  /// Semua profil (buat list di login screen)
  List<UserData> get allUsers => users.values.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  /// Semua profil siswa yang tergabung di sanggar yang sama dengan pelatih aktif.
  List<UserData> get muridProfiles {
    final sgId = currentSanggarId;
    if (sgId == null) return [];
    return users.values
        .where((u) => u.role == 'siswa' && u.sanggarId == sgId)
        .toList();
  }

  // ---- Proxy getter ke current ----
  String get name => current?.name ?? 'Penari';
  String get userRole => current?.role ?? 'siswa';
  String? get currentSanggarId => current?.sanggarId;
  bool get isPelatih => userRole == 'pelatih';
  Set<int> get completed => current?.completed ?? {};
  int get streak => current?.streak ?? 0;
  int get longest => current?.longest ?? 0;
  int get xp => current?.xp ?? 0;
  Set<String> get badges => current?.badges ?? {};
  List<String> get recentSearches => current?.recentSearches ?? [];
  int get fps => current?.fps ?? 30;
  bool get reminderOn => current?.reminderOn ?? true;
  int get reminderHour => current?.reminderHour ?? 19;
  int get reminderMinute => current?.reminderMinute ?? 30;
  String get habitCue => current?.habitCue ?? 'minum teh sore';
  bool get metronome => current?.metronome ?? true;
  bool get voiceGuide => current?.voiceGuide ?? true;
  Map<String, int> get secondsByDay => current?.secondsByDay ?? {};

  Sanggar? get currentSanggar {
    if (currentSanggarId == null) return null;
    try {
      return sanggarList.firstWhere((s) => s.id == currentSanggarId);
    } catch (_) {
      return null;
    }
  }

  bool get inSanggar => currentSanggar != null;

  // ---- Turunan ----
  double get progress => completed.length / samanVariations.length;
  bool get allDone => completed.length == samanVariations.length;
  int get level => xp ~/ 100 + 1;
  int get totalSeconds => secondsByDay.values.fold(0, (a, b) => a + b);
  bool get practicedToday => (secondsByDay[dayKey(DateTime.now())] ?? 0) > 0;

  int get currentStreak {
    final ld = current?.lastDay;
    if (ld == null) return 0;
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final l = DateTime.parse(ld);
    final diff = today.difference(DateTime(l.year, l.month, l.day)).inDays;
    return diff <= 1 ? streak : 0;
  }

  bool isUnlocked(int i) => i == 0 || completed.contains(i - 1);
  String get reminderLabel =>
      '${reminderHour.toString().padLeft(2, '0')}:${reminderMinute.toString().padLeft(2, '0')}';

  // === ID GENERATORS (UUID v4) ===
  String _generateSanggarId() {
    // SANG-XXYY (readable, tapi unik dari UUID)
    final u = _uuid.v4().replaceAll('-', '');
    return 'SANG-${u.substring(0, 4).toUpperCase()}';
  }

  // ============================================================
  // LOGIN
  // ============================================================
  /// Buat profil BARU — selalu bikin UUID baru
  Future<String> createProfile({
    required String userName,
    required String role,
    String sanggarName = '',
    String? kodeSanggar,
  }) async {
    final trimmed = userName.trim().isEmpty ? 'Penari' : userName.trim();
    final newId = _uuid.v4();

    String? sanggarId;
    if (role == 'pelatih') {
      if (sanggarName.trim().isEmpty) throw 'Nama sanggar wajib diisi';
      sanggarId = _ensureSanggar(sanggarName.trim(), trimmed);
    } else if (kodeSanggar != null && kodeSanggar.isNotEmpty) {
      final kode = kodeSanggar.trim().toUpperCase();
      if (!sanggarList.any((s) => s.id == kode)) {
        throw 'Kode sanggar "$kode" tidak ditemukan';
      }
      sanggarId = kode;
    }

    final user = UserData(
      id: newId,
      name: trimmed,
      role: role,
      sanggarId: sanggarId,
      createdAt: DateTime.now().toIso8601String(),
    );
    users[newId] = user;
    activeUserId = newId;
    await _save();
    notifyListeners();
    return newId;
  }

  /// Login ke profil yang SUDAH ada (dipilih dari list)
  Future<void> loginAs(String userId) async {
    if (!users.containsKey(userId)) return;
    activeUserId = userId;
    await _save();
    notifyListeners();
  }

  /// Cari user by name (buat auto-suggest)
  List<UserData> findUsersByName(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return users.values
        .where((u) => u.name.toLowerCase().contains(q))
        .toList();
  }

  String _ensureSanggar(String sanggarName, String pelatihName) {
    try {
      final existing = sanggarList.firstWhere(
        (s) =>
            s.name.toLowerCase() == sanggarName.toLowerCase() &&
            s.pelatih.toLowerCase() == pelatihName.toLowerCase(),
      );
      return existing.id;
    } catch (_) {
      final newSg = Sanggar(
        id: _generateSanggarId(),
        name: sanggarName,
        pelatih: pelatihName,
        siswa: [],
        createdAt: DateTime.now().toIso8601String(),
      );
      sanggarList.add(newSg);
      return newSg.id;
    }
  }

  Future<void> logout() async {
    await _save();
    activeUserId = null;
    notifyListeners();
  }

  // ============================================================
  // SANGGAR MANAGEMENT
  // ============================================================
  void addSiswa(String nama) {
    final v = nama.trim();
    if (v.isEmpty) return;
    final sg = currentSanggar;
    if (sg == null) return;
    if (sg.siswa.contains(v)) return;
    sg.siswa.add(v);
    _save();
    notifyListeners();
  }

  void removeSiswa(String nama) {
    final sg = currentSanggar;
    if (sg == null) return;
    sg.siswa.remove(nama);
    _save();
    notifyListeners();
  }

  Sanggar? findSanggarById(String id) {
    try {
      return sanggarList.firstWhere(
          (s) => s.id.toUpperCase() == id.trim().toUpperCase());
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // PROGRESS
  // ============================================================
  Future<void> recordSession({required int seconds, int? variationIndex}) async {
    final u = current;
    if (u == null) return;

    final today = dayKey(DateTime.now());
    u.secondsByDay[today] = (u.secondsByDay[today] ?? 0) + seconds;

    if (u.lastDay != today) {
      final t = DateTime.now();
      final y = dayKey(DateTime(t.year, t.month, t.day - 1));
      u.streak = (u.lastDay == y) ? u.streak + 1 : 1;
      u.lastDay = today;
      if (u.streak > u.longest) u.longest = u.streak;
    }

    u.badges.add('first_step');
    if (u.streak >= 3) u.badges.add('streak3');
    if (u.streak >= 7) u.badges.add('streak7');

    if (variationIndex == null) {
      u.xp += 10;
    } else {
      final first = u.completed.add(variationIndex);
      if (first) u.xp += Level.values[variationIndex].xp;
      u.badges.add(['var_pemula', 'var_menengah', 'var_akhir'][variationIndex]);
      if (u.completed.length == samanVariations.length) {
        if (u.badges.add('saman_complete')) u.xp += 150;
      }
    }
    await _save();
    notifyListeners();
  }

  // ============================================================
  // SEARCH
  // ============================================================
  void addSearch(String q) {
    final u = current;
    if (u == null) return;
    final v = q.trim();
    if (v.isEmpty) return;
    u.recentSearches.removeWhere((e) => e.toLowerCase() == v.toLowerCase());
    u.recentSearches.insert(0, v);
    if (u.recentSearches.length > 8) {
      u.recentSearches = u.recentSearches.sublist(0, 8);
    }
    _save();
    notifyListeners();
  }

  void removeSearch(String q) {
    current?.recentSearches.remove(q);
    _save();
    notifyListeners();
  }

  void clearSearches() {
    current?.recentSearches.clear();
    _save();
    notifyListeners();
  }

  // ============================================================
  // UPDATE HELPERS
  // ============================================================
  void update(void Function() change) {
    change();
    _save();
    notifyListeners();
  }

  set fps(int v) => current?.fps = v;
  set reminderOn(bool v) => current?.reminderOn = v;
  set reminderHour(int v) => current?.reminderHour = v;
  set reminderMinute(int v) => current?.reminderMinute = v;
  set habitCue(String v) => current?.habitCue = v;
  set metronome(bool v) => current?.metronome = v;
  set voiceGuide(bool v) => current?.voiceGuide = v;
  set name(String v) => current?.name = v;

  Future<void> resetProgress() async {
    final u = current;
    if (u == null) return;
    u.completed.clear();
    u.streak = 0;
    u.longest = 0;
    u.lastDay = null;
    u.secondsByDay = {};
    u.xp = 0;
    u.badges.clear();
    u.recentSearches.clear();
    await _save();
    notifyListeners();
  }

  /// Hapus profil user tertentu
  Future<void> deleteUser(String userId) async {
    users.remove(userId);
    if (activeUserId == userId) activeUserId = null;
    await _save();
    notifyListeners();
  }

  Future<void> resetAll() async {
    users.clear();
    sanggarList.clear();
    activeUserId = null;
    await _save();
    notifyListeners();
  }

  // ============================================================
  // STORAGE
  // ============================================================
  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final raw = _p!.getString('app_state_v3');
    if (raw == null) {
      // Coba migration dari v2 (nama-based)
      await _migrateFromV2();
      return;
    }
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final usersRaw = m['users'] as Map<String, dynamic>? ?? {};
      users = usersRaw.map((k, v) =>
          MapEntry(k, UserData.fromJson(Map<String, dynamic>.from(v))));
      activeUserId = m['activeUserId'];
      final sgRaw = m['sanggarList'] as List? ?? [];
      sanggarList = sgRaw
          .map((e) => Sanggar.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      users = {};
      activeUserId = null;
      sanggarList = [];
    }
  }

  Future<void> _migrateFromV2() async {
    final raw = _p!.getString('app_state_v2');
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final usersRaw = m['users'] as Map<String, dynamic>? ?? {};
      // Convert nama-keyed → UUID-keyed
      users = {};
      for (final entry in usersRaw.entries) {
        final data = Map<String, dynamic>.from(entry.value);
        final newId = _uuid.v4();
        data['id'] = newId;
        data['createdAt'] = DateTime.now().toIso8601String();
        users[newId] = UserData.fromJson(data);
      }
      activeUserId = null; // paksa login ulang
      final sgRaw = m['sanggarList'] as List? ?? [];
      sanggarList = sgRaw
          .map((e) => Sanggar.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      await _save();
    } catch (_) {}
  }

  Future<void> _save() async {
    await _p?.setString(
      'app_state_v3',
      jsonEncode({
        'users': users.map((k, v) => MapEntry(k, v.toJson())),
        'activeUserId': activeUserId,
        'sanggarList': sanggarList.map((s) => s.toJson()).toList(),
      }),
    );
  }
}