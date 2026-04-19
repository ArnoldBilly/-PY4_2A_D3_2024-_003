Aplikasi mobile berbasis Flutter yang mengintegrasikan sistem pelaporan patroli dengan fitur **Pengolahan Citra Digital (DIP)** tingkat lanjut. Proyek ini dikembangkan untuk memenuhi standar praktikum PCD (Pengolahan Citra Digital) dengan mengimplementasikan teori dari merubah ke grayscale menjadi ke .

## Fitur Utama

### 1. Akuisisi Citra & Interface
* **Live Camera Stream**: Integrasi hardware kamera menggunakan `camera` package.
* **Smart Capture**: Pengambilan gambar dengan manajemen lifecycle yang aman.
* **Pro-Grade UX**: Toggle Flashlight, Toggle Overlay, dan loading state yang informatif.

### Digital Image Processing (Sesuai Kurikulum PCD)
Fitur pengolahan citra yang diimplementasikan meliputi:

| Kategori | Fitur | Deskripsi (Referensi PPT) |
| :--- | :--- | :--- |
| **Operasi Titik** | Brightness, Grayscale, Biner | Manipulasi nilai pixel individual dan Thresholding. |
| **Aritmatika** | Penjumlahan & Pengurangan | Operasi $g(x,y) = f(x,y) \pm c$ dengan teknik *clamping*. |
| **Logika** | AND, OR, XOR, MAX, MIN | Operasi bitwise dan perbandingan antara dua citra. |
| **Histogram** | Equalization & Specification | Perbaikan kontras citra dan *Histogram Matching*. |
| **Filter Spasial** | Mean, Median, Sharpen | Penghalusan citra (*smoothing*) dan penajaman tepi. |

## Prasyarat (Prerequisites)
Sebelum menjalankan proyek ini, pastikan Anda telah menginstal:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Versi terbaru disarankan).
* [Dart SDK](https://dart.dev/get-started/sdk).
* Android Studio / VS Code dengan plugin Flutter & Dart.
* Perangkat Android/iOS fisik (untuk menguji fitur kamera).

## 📥 Instalasi

1. **Clone Repository**
   ```bash
   git clone [https://github.com/ArnoldBilly/-PY4_2A_D3_2024-_003](https://github.com/ArnoldBilly/-PY4_2A_D3_2024-_003)
2. **Install semua dependencies yang dibutuhkan**
    ```bash
    flutter pub get
3. **Jalankan aplikasi**
    ```bash
    flutter run