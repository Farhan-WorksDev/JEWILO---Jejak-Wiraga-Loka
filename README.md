# JEWILO - Jejak Wiraga Loka

Aplikasi mobile untuk belajar **Tari Saman** dengan deteksi gerakan real-time berbasis AI. Berjalan **hybrid: offline untuk latihan, online untuk kolaborasi sanggar**.

## Fitur Utama

### Deteksi Gerakan Real-time
- MediaPipe Holistic (pose + tangan kiri + tangan kanan)
- TensorFlow Lite model Conv1D - akurasi 88.8%, ukuran 155 KB
- Feedback akurasi per gerakan + timer + overlay real-time
- Mode validasi gerakan (bukan sekadar timer)

### Multi-Role & Sanggar
- Login sebagai Siswa atau Pelatih
- Google Sign-In + autentikasi Firebase
- Pelatih dapat mengelola sanggar (tambah/hapus murid, pantau progres)
- Data sanggar tersimpan di Cloud Firestore

### Gamifikasi & Kebiasaan
- XP, level, badge, streak harian
- Mengadopsi 4 Hukum Atomic Habits: Cue (reminder), Craving (XP), Response (mode 2 menit), Reward (centang + badge)

### Offline-First
- Latihan tetap jalan tanpa internet (model AI di-bundle di app)
- Progres lokal pakai SharedPreferences
- Text-to-speech offline untuk panduan suara
- Auto-reset saat app masuk background

### Kustomisasi
- FPS selector: 15 / 24 / 30 / 60
- Volume + voice guide toggle
- Reminder harian (zonedSchedule notification)

## Tech Stack

| Layer | Teknologi |
|---|---|
| Framework | Flutter 3.47 (stable) |
| AI/ML Runtime | MediaPipe Holistic + TensorFlow Lite |
| Model | Conv1D Neural Network (2 block + Dense head) |
| Auth | Firebase Auth + Google Sign-In |
| Database | Cloud Firestore (sanggar & progres online) |
| Local Storage | SharedPreferences |
| Notifikasi | flutter_local_notifications (zonedSchedule) |
| TTS | flutter_tts (offline) |
| Build/CI | GitHub Actions - APK artifact |

## Model AI

Arsitektur    : Conv1D (2 block) + BatchNorm + GlobalAvgPool + Dense
Input         : 60 frame x 300 fitur
                - Pose         : 33 titik x 4 (x,y,z,visibility) = 132
                - Tangan kiri  : 21 titik x 4 = 84
                - Tangan kanan : 21 titik x 4 = 84
Output        : 2 kelas - tari_saman / bukan_saman
Akurasi Val   : 88.80%
Ukuran        : ~155 KB (.tflite)
Runtime       : On-device, offline

Kenapa Conv1D? LSTM/RNN gagal di-convert ke TFLite di Keras 3 (bug TensorListReserve). Conv1D:
- TFLite-native
- 5-10x lebih cepat di HP (parallel)
- Model 5x lebih kecil
- Akurasi justru lebih tinggi

Dataset latihan:
- 198.323 sequence Tari Saman
- 165.288 sequence non-Saman (Kecak + Piring)

Retrain: python train_binary.py - auto-copy ke assets/models/.

## Halaman Aplikasi (10 Layar)

1. Splash - animasi logo + fade
2. Login - nama + role (Siswa/Pelatih), Pelatih input sanggar
3. Home - hero card, quick actions, streak
4. Latihan - 3 variasi Saman + badge XP
5. Detail Tarian - tempo, selector variasi, list gerakan
6. Practice - kamera + akurasi overlay + timer
7. Progress - 3 tab: Streak / Waktu / Status
8. Search - filter chip + recent + hasil
9. Notifikasi - grouping Hari Ini / Kemarin
10. Settings - FPS, reminder, audio, logout

## Cara Install

### 1. Download APK (via CI)
- Buka tab Actions di repo ini
- Pilih run terakhir yang sukses
- Download artifact tari-debug-apk

### 2. Build Sendiri
git clone https://github.com/Farhan-WorksDev/JEWILO---Jejak-Wiraga-Loka.git
cd JEWILO---Jejak-Wiraga-Loka/tari_app
flutter pub get
flutter run

### 3. Build APK dari lokal
flutter build apk --debug --target-platform android-arm64
Output: build/app/outputs/flutter-apk/app-debug.apk

## Struktur Project

JEWILO/
- tari_app/                    # Flutter app
  - lib/
    - ai/                       # ai_service.dart (TFLite inference)
    - ui/                       # 10 halaman UI
    - models/                   # data model
    - services/                 # Firebase, auth, TTS, notifikasi
  - assets/models/
    - dance_detector.tflite
    - label_map.json
  - android/
- keypoints/                   # Dataset (.npz)
- models/                      # Model output + Keras backup
- train_binary.py              # Script training
- .github/workflows/build.yml  # CI build APK

## Rebuild Model AI

python train_binary.py

Input dari keypoints/*.npz, output ke models/ + auto-copy ke tari_app/assets/models/.

## Tim

- Farhan
- Razi Ahmad Azzuhri
- Muhammad Syarafi Putra Andrian
- Khalifah Muhammad Zaki Fathurrahman

## Lisensi

MIT License - bebas dipakai untuk belajar dan penelitian.
