import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/saman_data.dart';

const _uuid = Uuid();

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
  // ---- Aksesibilitas ----
  bool dyslexiaFont;
  bool lowVision;
  bool reduceMotion;
  bool colorBlind;
  String colorBlindType;
  bool focusMode;
  /// Skala teks manual: 0.85 – 1.5 (default 1.0).
  double textScale;
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
    this.dyslexiaFont = false,
    this.lowVision = false,
    this.reduceMotion = false,
    this.colorBlind = false,
    this.colorBlindType = 'deutan',
    this.focusMode = false,
    this.textScale = 1.0,
    required this.createdAt,
  })  : completed = completed ?? {},
        secondsByDay = secondsByDay ?? {},
        badges = badges ?? {},
        recentSearches = recentSearches ?? [];

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
        'dyslexiaFont': dyslexiaFont,
        'lowVision': lowVision,
        'reduceMotion': reduceMotion,
        'colorBlind': colorBlind,
        'colorBlindType': colorBlindType,
        'focusMode': focusMode,
        'textScale': textScale,
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
        dyslexiaFont: m['dyslexiaFont'] ?? false,
        lowVision: m['lowVision'] ?? false,
        reduceMotion: m['reduceMotion'] ?? false,
        colorBlind: m['colorBlind'] ?? false,
        colorBlindType: m['colorBlindType'] ?? 'deutan',
        focusMode: m['focusMode'] ?? false,
        // Migration: user lama yang punya lowVision:true → otomatis textScale 1.25
        textScale: (m['textScale'] as num?)?.toDouble() ??
            ((m['lowVision'] == true) ? 1.25 : 1.0),
        createdAt: m['createdAt'] ?? DateTime.now().toIso8601String(),
      );
}

class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  SharedPreferences? _p;

  /// Mode yang dipilih user: 'online' atau 'offline'.
  String _userMode = 'online';
  String get userMode => _userMode;
  bool get isOffline => _userMode == 'offline';

  Map<String, UserData> users = {};
  String? activeUserId;
  List<Sanggar> sanggarList = [];

  UserData? get current => activeUserId != null ? users[activeUserId] : null;
  bool get hasLoggedIn => activeUserId != null;

  List<UserData> get allUsers => users.values.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<UserData> get muridProfiles {
    final sgId = currentSanggarId;
    if (sgId == null) return [];
    return users.values
        .where((u) => u.role == 'siswa' && u.sanggarId == sgId)
        .toList();
  }

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
  bool get dyslexiaFont => current?.dyslexiaFont ?? false;
  bool get lowVision => current?.lowVision ?? false;
  bool get reduceMotion => current?.reduceMotion ?? false;
  bool get colorBlind => current?.colorBlind ?? false;
  String get colorBlindType => current?.colorBlindType ?? 'deutan';
  bool get focusMode => current?.focusMode ?? false;
  double get textScale => current?.textScale ?? 1.0;
  Map<String, int> get secondsByDay => current?.secondsByDay ?? {};

  /// Set user aktif jadi pelatih + kaitin ke sanggar baru.
  Future<void> setAsPelatih({
    required String sanggarId,
    required String sanggarName,
    required String kode,
  }) async {
    final u = current;
    if (u == null) return;

    // Update role + sanggarId di UserData
    u.role = 'pelatih';
    u.sanggarId = sanggarId;

    // Tambah sanggar ke list lokal (biar currentSanggar works)
    if (!sanggarList.any((s) => s.id == sanggarId)) {
      sanggarList.add(Sanggar(
        id: sanggarId,
        name: sanggarName,
        pelatih: u.name,
        siswa: [],
        createdAt: DateTime.now().toIso8601String(),
      ));
    }

    await _save();
    notifyListeners();
  }

  Sanggar? get currentSanggar {
    if (currentSanggarId == null) return null;
    try {
      return sanggarList.firstWhere((s) => s.id == currentSanggarId);
    } catch (_) {
      return null;
    }
  }

  bool get inSanggar => currentSanggar != null;

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

  String _generateSanggarId() {
    final u = _uuid.v4().replaceAll('-', '');
    return 'SANG-${u.substring(0, 4).toUpperCase()}';
  }

  /// Update sanggarId user aktif + save ke SharedPreferences.
  Future<void> setSanggarId(String? sanggarId) async {
    final u = current;
    if (u == null) return;
    u.sanggarId = sanggarId;
    await _save();
    notifyListeners();
  }

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

  Future<void> loginAs(String userId) async {
    if (!users.containsKey(userId)) return;
    activeUserId = userId;
    await _save();
    notifyListeners();
  }

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
  set dyslexiaFont(bool v) => current?.dyslexiaFont = v;
  set lowVision(bool v) => current?.lowVision = v;
  set reduceMotion(bool v) => current?.reduceMotion = v;
  set colorBlind(bool v) => current?.colorBlind = v;
  set colorBlindType(String v) => current?.colorBlindType = v;
  set focusMode(bool v) => current?.focusMode = v;
  set textScale(double v) =>
      current?.textScale = v.clamp(0.85, 1.5).toDouble();

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

  Future<void> setUserMode(String mode) async {
    _userMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userMode', mode);
    notifyListeners();
  }

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    _userMode = _p!.getString('userMode') ?? 'online';
    final raw = _p!.getString('app_state_v3');
    if (raw == null) {
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
      users = {};
      for (final entry in usersRaw.entries) {
        final data = Map<String, dynamic>.from(entry.value);
        final newId = _uuid.v4();
        data['id'] = newId;
        data['createdAt'] = DateTime.now().toIso8601String();
        users[newId] = UserData.fromJson(data);
      }
      activeUserId = null;
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