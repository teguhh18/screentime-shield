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

4. **Jadwal Mingguan per Aplikasi (Weekly Schedule):**
   - Batas waktu berbeda untuk tiap hari dalam seminggu, per aplikasi (misal: Senin Instagram 60 menit & TikTok 90 menit; Selasa Instagram 120 menit & TikTok 30 menit).
   - **Precedence (Override per-hari):**
     - Hari yang diisi jadwal → memakai nilai hari itu.
     - Hari yang dibiarkan kosong → memakai limit global aplikasi tersebut.
     - Nilai `0` pada suatu hari → aplikasi **tidak dibatasi** hari itu (berbeda dari kosong).
   - **Resolusi di Native:** `AppMonitorService` menghitung limit efektif **setiap siklus monitoring (1 detik)** berdasarkan hari berjalan, sehingga pergantian hari otomatis berlaku tepat saat lewat tengah malam tanpa perlu restart service atau membuka aplikasi.
   - **Tidak mengubah mode kunci:** `lockMode` (Hard Lock / Snooze Alarm) tetap satu nilai per aplikasi, diatur di halaman limit global.
   - **Konfigurasi mandiri:** jadwal bisa diatur walau limit global aplikasi belum/tidak diaktifkan (`isActive = isMonitored || jadwal tidak kosong`).
   - **Persistensi:** jadwal disimpan sebagai bagian dari payload konfigurasi yang sama (`weeklyLimits`), sehingga ikut tersimpan di `FlutterSecureStorage`/Hive dan di `SharedPreferences` native, serta tetap berlaku setelah reboot.

5. **Mode Intervensi:**
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

6. **Navigasi Utama (Bottom Navigation):**
   - Tiga tab di dalam `HomeShell`:
     - **Home** — dashboard screen time hari ini, pencarian aplikasi, dan pengaturan limit global + mode kunci per aplikasi.
     - **Schedule** — pengaturan jadwal mingguan per aplikasi (Senin..Minggu).
     - **Settings** — status & permintaan izin native, serta pengelolaan anti-cheat.
   - Ikon Settings di pojok kanan atas dashboard **dihapus**; akses ke halaman Settings hanya melalui tab ini.

7. **Refresh Status Izin Otomatis:**
   - Status izin native (Usage Access, Display Over Apps, Device Admin) diperbarui otomatis saat aplikasi kembali ke foreground, tanpa perlu me-refresh atau me-restart aplikasi.
   - Berlaku di halaman Onboarding maupun Settings, karena pengguna memberi izin melalui halaman Settings Android di luar aplikasi.

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
│   ├── storage/            # LocalStorageService (Hive) & box names
│   ├── theme/              # App Theme (Dark Mode)
│   ├── utils/              # Formatter, Validators, WeeklyLimit (label & ringkasan hari)
│   └── widgets/            # Reusable UI Components (PinPad, PermissionCard, Dialogs,
│                           #   WeekdayLimitRow/Dialog, ScheduleAppTile)
├── features/               # Modul Berbasis Fitur
│   ├── app_lock/           # Overlay UI, repository, & Native Service bridge
│   ├── auth/               # PIN Setup, Login, Lupa Password, Reset PIN
│   ├── dashboard/          # Home Dashboard, App List, Limit Global Config
│   ├── schedule/           # Jadwal mingguan per aplikasi (tab Schedule)
│   ├── settings/           # Anti-cheat settings, izin native & Device Admin toggle
│   └── shell/              # HomeShell: Bottom Navigation (Home/Schedule/Settings)
└── main.dart               # Entry point & Provider Scope

test/
└── weekly_limit_test.dart  # Unit test resolusi limit harian & (de)serialisasi

android/app/src/main/kotlin/com/inibudi/screentimeshield/
├── MainActivity.kt         # Native router, whitelist payload konfigurasi, Channel registration
├── services/               # AppMonitorService (Foreground Service) & BootReceiver
├── receivers/              # ScreenTimeDeviceAdminReceiver (Anti-cheat)
└── utils/                  # UsageStatsHelper, OverlayHelper, DeviceAdminHelper
```

### Alur Data Konfigurasi (satu sumber kebenaran)

```text
MonitoredApp.toMap()  ──┬─> FlutterSecureStorage + Hive (key: monitored_app_configs_json)
   (satu-satunya        │
    serializer)         └─> MethodChannel app_lock/updateMonitoredApps
                                └─> MainActivity (whitelist field) ─> AppMonitorService
                                        └─> SharedPreferences (monitor_prefs / monitored_apps)

Enforcement tiap 1 detik:
  AppMonitorService.resolveEffectiveLimitMs(config)
    = weeklyLimits[hari ini]  jika hari ini dijadwalkan  (0 = tanpa batas)
    = timeLimitMs global      jika hari ini tidak dijadwalkan
```

---

## 5. Non-Functional Requirements

- **UX Edukatif:** Alur Onboarding menjelaskan alasan setiap izin native (Usage Stats, System Overlay, Device Admin) sebelum meminta izin dari sistem Android.
- **UX Responsif:** Status izin native langsung berubah setelah pengguna memberi izin dari halaman Settings Android — tanpa perlu me-refresh atau me-restart aplikasi (`PermissionAwareScope` + `checkAllPermissions()` setelah setiap permintaan izin).
- **Efisiensi Daya:** Foreground Service dioptimalkan dengan interval pemonitoran 1 detik yang efisien dan penggunaan resource minimal; resolusi limit harian dilakukan di dalam siklus yang sama tanpa query atau I/O tambahan.
- **Keamanan Offline:** Tidak membutuhkan jaringan internet. Semua data PIN dan konfigurasi tersimpan secara enkripsi di dalam penyimpanan lokal perangkat.
- **Kompatibilitas Upgrade:** Konfigurasi yang sudah tersimpan di device pengguna (payload lama tanpa `weeklyLimits`) wajib tetap terbaca dan tidak menghilangkan limit yang sudah diatur. Setiap field baru harus punya default aman di kedua sisi (Dart `??`, Kotlin `optJSONObject`/`optInt`).
- **Konvensi Hari:** Kunci hari selalu `1..7` = Senin..Minggu (`DateTime.weekday` di Dart, `Calendar.DAY_OF_WEEK` di Kotlin — penomoran keduanya identik), sehingga tidak ada kode konversi hari di layer mana pun.

