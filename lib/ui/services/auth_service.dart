import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _serverClientId =
      '840587110754-1mqv0poipt1obpqo0ma7ipap4i7d3iiu.apps.googleusercontent.com';

  final _google = GoogleSignIn.instance;
  final _auth = FirebaseAuth.instance;
  final _fire = FirebaseFirestore.instance;
  bool _init = false;

  Future<void> _ensure() async {
    if (_init) return;
    await _google.initialize(serverClientId: _serverClientId);
    _init = true;
  }

  Future<User?> signInWithGoogle() async {
    await _ensure();
    try {
      final gUser = await _google.authenticate();
      final gAuth = gUser.authentication;
      final idToken = gAuth.idToken;
      if (idToken == null) {
        debugPrint('Google ID token null');
        return null;
      }
      final cred = GoogleAuthProvider.credential(idToken: idToken);
      final result = await _auth.signInWithCredential(cred);
      return result.user;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await _fire.collection('users').doc(uid).get();
      if (doc.exists) return doc.data();
      return null;
    } catch (e) {
      debugPrint('getUserProfile error: $e');
      return null;
    }
  }

  Future<bool> saveUserProfile({
    required String nama,
    required String role,
    String sanggarName = '',
    String? kodeSanggar,
    String? sanggarId,
  }) async {
    final u = _auth.currentUser;
    if (u == null) return false;
    try {
      await _fire.collection('users').doc(u.uid).set({
        'uid': u.uid,
        'email': u.email ?? '',
        'nama': nama,
        'role': role,
        'sanggarName': sanggarName,
        'kodeSanggar': kodeSanggar,
        'sanggarId': sanggarId,
        'photoUrl': u.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('saveUserProfile error: $e');
      return false;
    }
  }

  Future<bool> setSanggarId(String sanggarId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      await _fire.collection('users').doc(uid).set({
        'sanggarId': sanggarId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('setSanggarId error: $e');
      return false;
    }
  }

  /// Fetch semua sanggar dari Firestore.
  Future<List<Map<String, dynamic>>> fetchSanggarList() async {
    try {
      final snap = await _fire.collection('sanggar').get();
      return snap.docs.map((d) {
        final data = d.data();
        data['docId'] = d.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('fetchSanggarList error: $e');
      return [];
    }
  }

  /// Cari sanggar berdasarkan kode (buat gabung).
  Future<Map<String, dynamic>?> findSanggarByKode(String kode) async {
    try {
      final snap = await _fire
          .collection('sanggar')
          .where('kode', isEqualTo: kode.toUpperCase().trim())
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final data = snap.docs.first.data();
      data['docId'] = snap.docs.first.id;
      return data;
    } catch (e) {
      debugPrint('findSanggarByKode error: $e');
      return null;
    }
  }

  /// Gabung sanggar: validasi kode + simpan ke profil user.
  /// Return: {success: bool, message: String, sanggar: Map?}
  Future<Map<String, dynamic>> joinSanggar(String kode) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return {'success': false, 'message': 'Belum login'};
    }
    if (kode.trim().isEmpty) {
      return {'success': false, 'message': 'Kode tidak boleh kosong'};
    }

    final sanggar = await findSanggarByKode(kode);
    if (sanggar == null) {
      return {
        'success': false,
        'message': 'Kode sanggar tidak ditemukan. Periksa kembali.'
      };
    }

    try {
      await _fire.collection('users').doc(uid).set({
        'role': 'siswa',
        'sanggarId': sanggar['docId'],
        'sanggarName': sanggar['name'] ?? '',
        'kodeSanggar': sanggar['kode'] ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return {
        'success': true,
        'message': 'Berhasil gabung ${sanggar['name']}',
        'sanggar': sanggar,
      };
    } catch (e) {
      debugPrint('joinSanggar error: $e');
      return {'success': false, 'message': 'Gagal gabung: $e'};
    }
  }

  /// Generate kode sanggar unik (SANG-XXXX).
  String _generateKode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = DateTime.now().microsecondsSinceEpoch;
    final buf = StringBuffer('SANG-');
    for (var i = 0; i < 4; i++) {
      buf.write(chars[(r >> (i * 5)) % chars.length]);
    }
    return buf.toString();
  }

  /// Cek apakah sanggar dengan kode tertentu udah ada.
  Future<bool> kodeExists(String kode) async {
    try {
      final snap = await _fire
          .collection('sanggar')
          .where('kode', isEqualTo: kode)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Bikin sanggar baru di Firestore + generate kode unik.
  /// Return: {success, message, sanggarId, kode}
  Future<Map<String, dynamic>> createSanggar({
    required String nama,
    required String region,
    String alamat = '',
    String telepon = '',
    String email = '',
    String jadwal = '',
    String deskripsi = '',
    int? tahunBerdiri,
    List<String> tarian = const [],
  }) async {
    final u = _auth.currentUser;
    if (u == null) {
      return {'success': false, 'message': 'Belum login'};
    }
    if (nama.trim().isEmpty) {
      return {'success': false, 'message': 'Nama sanggar wajib diisi'};
    }

    // Generate kode unik (loop max 10x)
    String kode = '';
    for (var i = 0; i < 10; i++) {
      final candidate = _generateKode();
      if (!await kodeExists(candidate)) {
        kode = candidate;
        break;
      }
    }
    if (kode.isEmpty) {
      return {'success': false, 'message': 'Gagal generate kode. Coba lagi.'};
    }

    try {
      final ref = _fire.collection('sanggar').doc(kode);
      await ref.set({
        'name': nama.trim(),
        'region': region.trim(),
        'alamat': alamat.trim(),
        'telepon': telepon.trim(),
        'email': email.trim(),
        'jadwal': jadwal.trim(),
        'deskripsi': deskripsi.trim(),
        'tahunBerdiri': tahunBerdiri,
        'tarian': tarian,
        'kode': kode,
        'pelatihUid': u.uid,
        'pelatihName': u.displayName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update user profile: kaitin sanggarId
      await _fire.collection('users').doc(u.uid).set({
        'sanggarId': ref.id,
        'sanggarName': nama.trim(),
        'kodeSanggar': kode,
        'role': 'pelatih',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return {
        'success': true,
        'message': 'Sanggar berhasil dibuat',
        'sanggarId': ref.id,
        'kode': kode,
      };
    } catch (e) {
      debugPrint('createSanggar error: $e');
      return {'success': false, 'message': 'Gagal buat sanggar: $e'};
    }
  }

  /// Update user role jadi 'pelatih' (dipanggil setelah create sanggar).
  Future<bool> setUserRolePelatih() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      await _fire.collection('users').doc(uid).set({
        'role': 'pelatih',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('setUserRolePelatih error: $e');
      return false;
    }
  }

  /// Sync data user (XP, streak, completed, dll) ke Firestore.
  /// Dipanggil otomatis tiap selesai latihan.
  Future<bool> syncUserStats({
    required int xp,
    required int streak,
    required int longest,
    required int totalMinutes,
    required int completedCount,
    String? lastDay,
    List<String>? badges,
    Map<String, int>? secondsByDay,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      final ref = _fire.collection('users').doc(uid);

      // Fetch remote dulu biar bisa merge (anti data-loss kalau ganti device)
      final remoteSnap = await ref.get();
      final remote = remoteSnap.data() ?? {};

      // Merge numeric: ambil yang lebih tinggi
      final remoteXp = (remote['xp'] ?? 0) as int;
      final remoteStreak = (remote['streak'] ?? 0) as int;
      final remoteLongest = (remote['longest'] ?? 0) as int;
      final remoteTotal = (remote['totalMinutes'] ?? 0) as int;
      final remoteCompleted = (remote['completedCount'] ?? 0) as int;

      final data = <String, dynamic>{
        'xp': xp > remoteXp ? xp : remoteXp,
        'streak': streak > remoteStreak ? streak : remoteStreak,
        'longest': longest > remoteLongest ? longest : remoteLongest,
        'totalMinutes':
            totalMinutes > remoteTotal ? totalMinutes : remoteTotal,
        'completedCount': completedCount > remoteCompleted
            ? completedCount
            : remoteCompleted,
        'lastDay': lastDay,
        'statsUpdatedAt': FieldValue.serverTimestamp(),
      };

      // Merge badges: union (ambil semua dari remote + lokal)
      if (badges != null) {
        final remoteBadges = List<String>.from(remote['badges'] ?? []);
        final mergedBadges = <String>{...remoteBadges, ...badges}.toList();
        data['badges'] = mergedBadges;
      }

      // Merge secondsByDay: max per hari, limit 30 hari terakhir
      if (secondsByDay != null) {
        final remoteSec =
            Map<String, int>.from(remote['secondsByDay'] ?? {});
        final mergedSec = <String, int>{};
        for (final k in {...remoteSec.keys, ...secondsByDay.keys}) {
          final a = remoteSec[k] ?? 0;
          final b = secondsByDay[k] ?? 0;
          mergedSec[k] = a > b ? a : b;
        }
        final keys = mergedSec.keys.toList()..sort();
        final recent =
            keys.length > 30 ? keys.sublist(keys.length - 30) : keys;
        data['secondsByDay'] = {
          for (final k in recent) k: mergedSec[k] ?? 0
        };
      }

      await ref.set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('syncUserStats error: $e');
      return false;
    }
  }

  /// Fetch semua murid di sanggar tertentu (real-time).
  Stream<List<Map<String, dynamic>>> streamMuridBySanggar(
      String sanggarId) {
    return _fire
        .collection('users')
        .where('sanggarId', isEqualTo: sanggarId)
        .where('role', isEqualTo: 'siswa')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['uid'] = d.id;
              return data;
            }).toList());
  }

  /// Kick murid dari sanggar (hapus sanggarId dari user).
  Future<bool> kickMurid(String uid) async {
    try {
      await _fire.collection('users').doc(uid).set({
        'sanggarId': null,
        'sanggarName': null,
        'kodeSanggar': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('kickMurid error: $e');
      return false;
    }
  }

  User? get current => _auth.currentUser;
  /// Stream dokumen user dari Firestore (real-time).
  /// Dipakai AppState.listenToMyFirestoreDoc() buat handle kick.
  Stream<Map<String, dynamic>?> streamUserDoc(String uid) {
    return _fire.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data()!;
      data['uid'] = snap.id;
      return data;
    });
  }
  bool get isSignedIn => _auth.currentUser != null;
}
