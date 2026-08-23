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
- Membangun UI berbasis komponen (Reusable Widgets) untuk Dashboard, Setup PIN, dan Lock Screen.
- Menghubungkan State Management dengan UI.
- Membuat alur *Onboarding* yang ramah (menjelaskan kepada pengguna sebelum meminta izin Native).
- Memastikan tidak ada *business logic* (logika perhitungan/keputusan) di dalam *UI file*. Semua logika harus berada di *Controller* atau *ViewModel*.

## Alur Kerja (Workflow)
1. User akan memanggil "Mulai Fase 1", AI akan bertindak sebagai **Peran 1**.
2. Setelah Peran 1 selesai dan direview User, User memanggil "Mulai Fase 2". AI menjadi **Peran 2**.
3. Setelah Native selesai, User memanggil "Mulai Fase 3" untuk penyelesaian UI.