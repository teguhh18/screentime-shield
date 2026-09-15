# AI Agent Roles & Workflow

Untuk membangun aplikasi ini, AI harus mengadopsi 3 peran spesifik yang bekerja secara sekuensial. Jangan lompat ke peran lain sebelum tugas di peran saat ini selesai.

## Peran 1: 🏛️ Lead Architect & Setup Engineer
**Tugas:**
- Membaca `PRD.md` dan menginisialisasi proyek Flutter.
- Membangun struktur folder persis seperti yang didefinisikan di PRD.
- Menyiapkan *dependency injection*, *State Management* (Riverpod/BLoC), dan *Local Storage* (Hive/Isar).
- Membuat *base class* untuk `MethodChannels` di folder `core/native_bridge/`.

## Peran 2: 📱 Native Android Engineer (Kotlin Expert)
**Tugas:**
- Membuka folder `android/` dan menulis kode Kotlin yang bersih dan modular.
- Mengimplementasikan `UsageStatsManager` untuk membaca screen time.
- Mengimplementasikan `Foreground Service` dan `SYSTEM_ALERT_WINDOW` untuk memunculkan UI Overlay di atas aplikasi lain (Lock Mode).
- Mengimplementasikan `DevicePolicyManager` (Device Administrator) untuk mencegah *uninstall* aplikasi (Anti-Cheat).
- Memastikan MethodChannels terhubung sempurna dengan layer Flutter (bisa mengirim dan menerima instruksi).

## Peran 3: 🎨 Flutter UI/UX & Logic Engineer
**Tugas:**
- Membangun UI berbasis komponen (Reusable Widgets) untuk Dashboard, Jadwal Mingguan, Setup PIN, dan Lock Screen.
- Menghubungkan State Management dengan UI.
- Membuat alur *Onboarding* yang ramah (menjelaskan kepada pengguna sebelum meminta izin Native).
- Memastikan tidak ada *business logic* (logika perhitungan/keputusan) di dalam *UI file*. Semua logika harus berada di *Controller* atau *ViewModel*.

## Alur Kerja (Workflow)
1. User akan memanggil "Mulai Fase 1", AI akan bertindak sebagai **Peran 1**.
2. Setelah Peran 1 selesai dan direview User, User memanggil "Mulai Fase 2". AI menjadi **Peran 2**.
3. Setelah Native selesai, User memanggil "Mulai Fase 3" untuk penyelesaian UI.
4. Setelah Fase 3, perubahan berikutnya bersifat **inkremental**: tentukan peran mana yang tersentuh (biasanya Peran 2 + 3 sekaligus kalau fitur baru harus di-enforce native), lalu kerjakan berurutan dalam satu perubahan.

---

## Aturan Wajib (hasil keputusan yang sudah disepakati)

Aturan ini lahir dari implementasi nyata. Jangan dilanggar tanpa alasan kuat.

### 1. Satu Serializer untuk Konfigurasi Aplikasi
`MonitoredApp.toMap()` / `MonitoredApp.fromMap()` di `lib/features/dashboard/domain/monitored_app_model.dart` adalah **satu-satunya** serializer konfigurasi. Payload yang sama dipakai untuk:
- penyimpanan Flutter (`FlutterSecureStorage` + Hive, key `monitored_app_configs_json`), dan
- payload `MethodChannel` `app_lock` / `updateMonitoredApps`.

Artinya menambah field baru **tidak perlu** ubah layer bridge. Cukup tambah di model, lalu **wajib** tambahkan juga di whitelist Kotlin `MainActivity.handleUpdateMonitoredApps()` — kalau tidak, field itu dibuang diam-diam sebelum sampai `AppMonitorService`.

### 2. `fromMap` harus selalu toleran data lama
Setiap field baru wajib punya default aman (`?? const {}`, `?? 0`, dst) supaya JSON yang sudah tersimpan di device pengguna tidak membuat konfigurasi hilang setelah update. Berlaku juga di sisi Kotlin: pakai `optJSONObject` / `optString` / `optInt`, bukan `getJSONObject` / `getString`.

### 3. `isActive`, bukan `isMonitored`, untuk menentukan aplikasi dipantau
`MonitoredApp.isActive` = `isMonitored || weeklyLimits.isNotEmpty`. Filter `isMonitored` **hanya** berarti "punya limit global". Setiap tempat yang memfilter daftar sebelum disimpan atau dikirim ke native harus pakai `isActive`, kalau tidak konfigurasi jadwal (yang berdiri sendiri tanpa limit global) akan terbuang.

### 4. Resolusi limit per hari terjadi di native, bukan di Dart
`AppMonitorService.resolveEffectiveLimitMs()` dipanggil **setiap tick** (1 detik), bukan sekali saat konfigurasi dikirim. Ini disengaja: service hidup 24 jam dan hanya menerima payload baru saat user membuka dashboard, jadi resolusi di Dart akan basi setelah tengah malam. Jangan pindahkan logika ini ke Dart.

### 5. Konvensi kunci hari
Kunci hari selalu integer `1..7` = **Senin..Minggu** (`DateTime.weekday` di Dart). Sisi Kotlin membaca kunci yang sama sebagai `Calendar.DAY_OF_WEEK`, jadi:
- **Tidak ada kode konversi hari di mana pun.** Jangan tambahkan remap.
- Nilai per hari: kunci **absen** = ikut limit global; nilai **`0`** = tanpa batas hari itu. Jangan perlakukan `0` sebagai "tidak diatur".

### 6. Sinkronisasi status izin native
Setiap layar yang menampilkan status izin wajib dibungkus `PermissionAwareScope` (`lib/core/widgets/permission_aware_scope.dart`), dan setiap `request*` di `PermissionsNotifier` harus diakhiri `checkAllPermissions()`. Tanpa itu UI menampilkan status basi karena user memberi izin di luar aplikasi (halaman Settings Android). Jangan pakai polling timer untuk ini.

### 7. Invarian yang harus dijaga saat mengubah fitur limit
- `configureAppLimit()` **tidak boleh** menyentuh `weeklyLimits`.
- `configureWeeklyLimits()` **tidak boleh** menyentuh `timeLimitMinutes` / `lockMode`.
- `lockMode` tetap satu nilai per aplikasi (bukan per hari).
- Naikkan limit di atas pemakaian berjalan **wajib** langsung membuka kuncian; ini berlaku otomatis karena native membandingkan ulang setiap tick.

---

## Verifikasi Wajib Sebelum Menandai Selesai
1. `flutter analyze` → harus `No issues found`.
2. `flutter build apk --debug` → satu-satunya cara memastikan kode Kotlin ikut terkompilasi.
3. `flutter test` → `test/weekly_limit_test.dart` menjaga logika resolusi limit harian.
   *Catatan lingkungan:* `flutter test` gagal di mesin ini karena path SDK Flutter mengandung spasi (`C:\Users\TEGUH BUDIONO\flutter`), yang memecahkan build hook `objective_c` (`'C:\Users\TEGUH' is not recognized`). `flutter analyze` dan `flutter build apk` tidak terpengaruh. Pindahkan SDK ke path tanpa spasi (mis. `C:\flutter`) untuk menjalankan test.
