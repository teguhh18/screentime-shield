# Product Requirements Document (PRD): Kids ScreenTime Shield

## 1. Visi & Deskripsi Produk

Aplikasi mobile (Android-first) yang dirancang untuk orang tua guna membatasi dan memantau waktu layar (Screen Time) anak pada aplikasi tertentu. Aplikasi berjalan sepenuhnya offline dengan fitur _anti-cheat_ tingkat sistem untuk mencegah penghapusan aplikasi oleh anak.

## 2. Fitur Utama (Core Features)

1. **Onboarding & Keamanan:** Set-up PIN/Password awal untuk melindungi aplikasi.
2. **App Selection:** Daftar aplikasi terinstal yang bisa dipilih untuk dipantau.
3. **Screen Time Limit:** Pengaturan batas waktu (misal: 1 jam/hari) per aplikasi.
4. **Intervensi (Mode):**
   - **Snooze Alarm:** Peringatan yang bisa ditunda (5/15 menit).
   - **Hard Lock:** Layar overlay penuh yang memblokir akses ke aplikasi target hingga waktu reset.
5. **Anti-Cheat (Device Admin):**
   - Meminta hak `Device Administrator` untuk mencegah _uninstall_.
   - Otomatis mengunci aplikasi `Settings` (Pengaturan HP) dan `Google Play Store` menggunakan overlay jika PIN belum dimasukkan.
   - Opsi _Uninstall_ / Cabut hak Admin yang aman dari dalam aplikasi (membutuhkan PIN).

## 3. Tech Stack

- **Frontend/UI:** Flutter (Dart).
- **Native OS:** Android OS (Kotlin) - Wajib untuk integrasi sistem.
- **Local Storage:** Hive atau Isar (NoSQL, fast offline storage).
- **State Management:** Riverpod atau BLoC (pilih salah satu dan konsisten).

## 4. Arsitektur & Struktur Folder

Prodroduct ini WAJIB menggunakan pendekatan **Feature-Driven Architecture** yang dipadukan dengan **Clean Code**. Tidak boleh ada _Spaghetti Code_.

```text
lib/
├── core/                   # Logika sistem & resource yang dipakai berulang
│   ├── constants/          # Colors, Strings, Dimensions
│   ├── error/              # Custom Exceptions & Failure classes
│   ├── native_bridge/      # MethodChannels (komunikasi Dart <-> Kotlin)
│   ├── theme/              # App themes
│   └── utils/              # Helpers (Date formatters, validators)
├── features/               # Modul berbasis fitur
│   ├── auth/               # Setup PIN, Login Screen
│   ├── app_lock/           # Overlay UI, lock logic, background service
│   ├── dashboard/          # Home screen, app usage list
│   └── settings/           # Uninstall logic, Device Admin toggle
└── main.dart               # Entry point, dependency injection setup

android/app/src/main/kotlin/com/example/screentime/
├── MainActivity.kt         # Entry point native, MethodChannel handler
├── services/               # Foreground Service (pemantau aplikasi aktif)
├── receivers/              # DeviceAdminReceiver (Anti-cheat)
└── utils/                  # UsageStatsManager helpers
```

## 5. Non-Functional Requirements

- **UX Pertama**: Proses permintaan hak akses (Usage Stats, Draw Overlay, Device Admin) harus mulus, didahului dengan layar edukasi yang ramah pengguna.

- **Efisiensi Baterai**: Background service di Android harus dioptimalkan agar tidak menguras baterai (gunakan JobScheduler atau optimasi Foreground Service standar).
