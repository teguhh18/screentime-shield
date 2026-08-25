# Product Requirements Document (PRD): Kids ScreenTime Shield

## 1. Visi & Deskripsi Produk

Aplikasi mobile (Android-first) yang dirancang untuk orang tua guna membatasi dan memantau waktu layar (Screen Time) anak pada aplikasi tertentu. Aplikasi berjalan sepenuhnya offline dengan fitur _anti-cheat_ tingkat sistem untuk mencegah penghapusan aplikasi oleh anak.

---

## 2. Fitur Utama (Core Features)

1. **Keamanan PIN & Lupa Password:**
   - **Setup & Login PIN Parent:** Autentikasi PIN 4 digit untuk mengakses aplikasi.
   - **Fitur Lupa Password:** Integrasi dengan sistem keamanan perangkat HP (`KeyguardManager` / Device Lock). Pengguna dapat mereset PIN dengan memasukkan PIN/Password/Pola bawaan HP. Jika HP tidak menggunakan pengunci layar, pengguna langsung diarahkan ke halaman pembuatan PIN baru.
   - **Dual-Storage Persistence:** Menggunakan `FlutterSecureStorage` (enkripsi) dengan fallback `Hive` (JSON) agar pengaturan aman dan tidak hilang saat aplikasi di-refresh atau HP di-reboot.

2. **Daftar & Pemantauan Aplikasi (App Selection & Monitoring):**
   - Menampilkan daftar aplikasi yang terinstal di HP pengguna beserta ikon dan durasi penggunaan hari ini.
   - **Daily Reset System:** Pengukuran batas waktu otomatis mengikuti siklus harian sistem Android OS (reset setiap jam 00:00 tengah malam).
   - **Akurat & Konsisten:** Menggunakan `queryAndAggregateUsageStats` pada layer Kotlin Native untuk memastikan perhitungan durasi penggunaan di UI Flutter dan Native Monitor 100% identik tanpa penggandaan bucket.

3. **Pengaturan Batas Waktu (Screen Time Limit):**
   - Pengaturan batas waktu pemakaian harian per aplikasi (misal: 30 menit, 1 jam, 2 jam).
   - Pengubahan batas limit secara dinamis — jika limit dinaikkan di atas waktu penggunaan yang berjalan, sistem seketika membuka kuncian aplikasi.

4. **Mode Intervensi:**
   - **Hard Lock Mode:**
     - Layar overlay penuh (*Full-Screen Lock Overlay*) langsung menutupi aplikasi target saat limit harian tercapai.
     - Menahan overlay selama 5 detik, lalu secara otomatis mengembalikan perangkat ke Home Screen (`Intent.CATEGORY_HOME`) dan membersihkan proses latar belakang (`killBackgroundProcesses`).
   - **Snooze Alarm Mode:**
     - Layar overlay khusus Snooze Alarm muncul dengan 3 tombol pilihan waktu tunda: **+5 Menit**, **+15 Menit**, dan **+30 Menit**.
     - Memutar **suara alarm sistem** (`RingtoneManager`) secara berulang (looping) dan **getaran HP** (`Vibrator` pulse pattern) saat overlay tampil.
     - Saat salah satu opsi tunda dipilih, overlay langsung hilang serta suara alarm dan getaran seketika berhenti. Setelah masa tunda habis, overlay Snooze, suara alarm, dan getaran akan tampil kembali.

5. **Anti-Cheat & Keamanan Sistem (Device Admin):**
   - Meminta hak `Device Administrator` untuk mencegah uninstallation aplikasi oleh anak.
   - Pemantauan latar belakang melalui Foreground Service (`AppMonitorService`) berdaya tahan tinggi.
   - Opsi pencabutan hak Admin / Uninstallation yang aman dari dalam aplikasi (membutuhkan PIN Parent).

---

## 3. Tech Stack

- **Frontend/UI:** Flutter (Dart)
- **State Management:** Riverpod
- **Native OS Integration:** Kotlin (Android Service, Overlay, Keyguard, UsageStats)
- **Local Persistence:** `flutter_secure_storage` + `hive_flutter`
- **MethodChannels:**
  - `com.inibudi.screentimeshield/usage_stats`
  - `com.inibudi.screentimeshield/app_lock`
  - `com.inibudi.screentimeshield/device_admin`
  - `com.inibudi.screentimeshield/device_security`

---

## 4. Arsitektur & Struktur Folder

Aplikasi menggunakan **Feature-Driven Architecture** dengan prinsip **Clean Code**:

```text
lib/
├── core/                   # Logika sistem & resource umum
│   ├── constants/          # Colors, Strings, Dimensions
│   ├── error/              # Custom Exceptions & Failure classes
│   ├── native_bridge/      # MethodChannels (Dart <-> Kotlin)
│   ├── theme/              # App Theme (Dark Mode)
│   ├── utils/              # Formatter & Validators
│   └── widgets/            # Reusable UI Components (PinPad, Dialogs)
├── features/               # Modul Berbasis Fitur
│   ├── app_lock/           # Overlay UI, repository, & Native Service bridge
│   ├── auth/               # PIN Setup, Login, Lupa Password, Reset PIN
│   ├── dashboard/          # Home Dashboard, App List, Limit Config
│   └── settings/           # Anti-cheat settings & Device Admin toggle
└── main.dart               # Entry point & Provider Scope

android/app/src/main/kotlin/com/inibudi/screentimeshield/
├── MainActivity.kt         # Native router & Keyguard/Channel registration
├── services/               # AppMonitorService (Foreground Service) & BootReceiver
├── receivers/              # ScreenTimeDeviceAdminReceiver (Anti-cheat)
└── utils/                  # UsageStatsHelper, OverlayHelper, DeviceAdminHelper
```

---

## 5. Non-Functional Requirements

- **UX Edukatif:** Alur Onboarding menjelaskan alasan setiap izin native (Usage Stats, System Overlay, Device Admin) sebelum meminta izin dari sistem Android.
- **Efisiensi Daya:** Foreground Service dioptimalkan dengan interval pemonitoran 1 detik yang efisien dan penggunaan resource minimal.
- **Keamanan Offline:** Tidak membutuhkan jaringan internet. Semua data PIN dan konfigurasi tersimpan secara enkripsi di dalam penyimpanan lokal perangkat.
