# 🕺 Dance Detector — Pendeteksi Tarian Indonesia

Program real-time untuk mendeteksi tarian Indonesia menggunakan **MediaPipe Holistic + Bidirectional LSTM + Attention**.

---

## Arsitektur

```
Video/Webcam
     │
     ▼
MediaPipe Holistic
  ├── Pose: 33 titik × 4 = 132 fitur
  ├── Tangan Kiri: 21 titik × 4 = 84 fitur
  └── Tangan Kanan: 21 titik × 4 = 84 fitur
     │
     ▼ Total: 300 fitur/frame × 60 frame = sequence
     │
     ▼
BiLSTM(128) → Dropout → BiLSTM(64) → Dropout → Attention
     │
     ▼
Dense(128) → BatchNorm → Dropout → Softmax
     │
     ▼
Kelas Tarian + Confidence
```

---

## Struktur Folder

```
tari/
├── config.py          ← konfigurasi global
├── extractor.py       ← ekstraksi keypoint dari video
├── dataset.py         ← load data & split train/val/test
├── model.py           ← arsitektur BiLSTM + Attention
├── train.py           ← training pipeline
├── evaluate.py        ← evaluasi & visualisasi
├── detector.py        ← real-time detection (webcam/video)
├── collect_data.py    ← rekam data training dari webcam
├── demo_no_model.py   ← demo pose tanpa model
├── requirements.txt
│
├── data/              ← taruh video training di sini
│   ├── tari_piring/
│   ├── tari_saman/
│   ├── tari_kecak/
│   └── tidak_dikenal/
│
├── keypoints/         ← hasil ekstraksi .npy (auto dibuat)
├── models/            ← bobot model .h5 (auto dibuat)
└── logs/              ← training history & plot (auto dibuat)
```

---

## Instalasi

```bash
pip install -r requirements.txt
```

---

## Cara Pakai

### Langkah 1 — Cek instalasi (tanpa model)
```bash
python demo_no_model.py
```
Cek apakah pose terdeteksi di webcam. Tidak butuh data/model dulu.

---

### Langkah 2A — Punya video tarian? Taruh di folder `data/`

```
data/
  tari_piring/  ← taruh file .mp4 / .avi di sini
  tari_saman/
  ...
```

Lalu ekstrak keypoint:
```bash
python extractor.py
```

---

### Langkah 2B — Tidak punya video? Rekam langsung dari webcam

```bash
python collect_data.py
```

Ikuti petunjuk di layar. Program akan rekam pose kamu dan simpan langsung ke `keypoints/`.

---

### Langkah 3 — Training

```bash
python train.py
```

Output:
- `models/dance_detector_best.h5` — model terbaik
- `models/label_map.json` — peta label
- `logs/training_history.png` — grafik accuracy & loss
- `logs/confusion_matrix.png` — confusion matrix

---

### Langkah 4 — Real-time detection

**Dari webcam:**
```bash
python detector.py
```

**Dari file video:**
```bash
python detector.py path/to/video.mp4
```

**Kontrol:**
- `Q` — Keluar
- `R` — Reset buffer

---

### Evaluasi model

```bash
# Evaluasi test set
python evaluate.py

# Evaluasi satu video
python evaluate.py path/to/video.mp4
```

---

## Konfigurasi (`config.py`)

| Parameter | Default | Keterangan |
|-----------|---------|------------|
| `DANCE_CLASSES` | `[tari_piring, tari_saman, tari_kecak, tidak_dikenal]` | Tambah kelas sesuai kebutuhan |
| `SEQUENCE_LENGTH` | `60` | Jumlah frame per sampel (~2 detik) |
| `EPOCHS` | `100` | Max epoch training (ada early stopping) |
| `CONFIDENCE_THRESHOLD` | `0.70` | Min confidence untuk tampilkan label |
| `SMOOTHING_WINDOW` | `10` | Rata-rata N prediksi terakhir |

---

## Tips Dataset

- **Minimum**: 20-30 video per kelas (±5 detik per video)
- **Ideal**: 100+ video per kelas dari angle & pencahayaan berbeda
- **Format**: MP4, AVI, MOV, MKV
- **Kualitas**: 720p sudah cukup, pencahayaan cukup terang

### Sumber video tari gratis:
- YouTube → download dengan `yt-dlp`
- `yt-dlp "https://youtube.com/..." -o "data/tari_piring/%(title)s.%(ext)s"`

---

## Menambah Kelas Tarian Baru

1. Edit `config.py` → tambah nama di `DANCE_CLASSES`
2. Buat folder `data/<nama_kelas>/` dan isi video
3. Jalankan ulang `extractor.py` → `train.py`
