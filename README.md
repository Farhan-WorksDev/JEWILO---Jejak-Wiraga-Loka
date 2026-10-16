# JEWILO - Jejak Wiraga Loka

Aplikasi mobile untuk belajar **Tari Saman** dengan deteksi gerakan real-time menggunakan MediaPipe + TensorFlow Lite. Berjalan **offline** dan dirancang untuk semua usia.

## ✨ Fitur
- 🎯 Deteksi Gerakan Real-time (MediaPipe Holistic)
- 🤖 AI Binary Classifier (Conv1D, akurasi 88.8%, 155 KB)
- 👥 Login + Role (Siswa / Pelatih)
- 🏫 Manajemen Sanggar (Firebase)
- 📊 Gamifikasi (XP, level, badge, streak)
- 📴 Offline-First

## 🛠️ Tech Stack
- **Framework**: Flutter 3.47
- **AI/ML**: MediaPipe Holistic + TensorFlow Lite
- **Model**: Conv1D Neural Network
- **Backend**: Firebase Auth + Firestore

## 🧠 Model AI
- Arsitektur: Conv1D (2 block)
- Input: 60 frame × 300 landmark
- Output: 2 kelas (tari_saman / bukan_saman)
- Akurasi: 88.80%
- Ukuran: 155 KB

## 🚀 Cara Build
```bash
git clone https://github.com/Farhan-WorksDev/JEWILO---Jejak-Wiraga-Loka.git
cd JEWILO---Jejak-Wiraga-Loka/tari_app
flutter pub get
flutter run