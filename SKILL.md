# Coding Guidelines & Constraints (Wajib Dipatuhi)

## 1. Clean Code & DRY (Don't Repeat Yourself)
- **Ekstraksi Widget:** Jangan pernah membuat UI lebih dari 150 baris dalam satu file. Ekstrak komponen seperti `CustomButton`, `PermissionCard`, atau `PinPad` ke dalam folder `core/widgets/` agar bisa digunakan kembali (Reusable).
- **Hindari Duplikasi:** Jika ada fungsi format waktu atau pengecekan *null*, letakkan di `core/utils/`.

## 2. Pemisahan Kekhawatiran (Separation of Concerns)
- **UI is only UI:** File `.dart` di folder `presentation` atau `views` hanya boleh berisi deklarasi antarmuka. Dilarang keras melakukan pemanggilan API, *MethodChannel*, atau *query database* langsung dari file UI.
- Semua interaksi eksternal harus melalui layer `Repository`.

## 3. Standar MethodChannel (Dart <-> Kotlin)
- Gunakan arsitektur *Sealed Classes* (di Kotlin) dan Enum (di Dart) untuk menangani respons dari MethodChannel.
- Wajib menyertakan blok `try-catch` di setiap panggilan MethodChannel pada Dart, dan tangani `PlatformException` dengan memberikan pesan yang bisa dibaca pengguna.

## 4. Keamanan Penyimpanan
- Jangan simpan PIN/Password dalam *plaintext*. Gunakan *package* seperti `flutter_secure_storage` atau *hash* PIN tersebut sebelum menyimpannya di Hive/Isar.

## 5. Standar Kotlin (Android)
- Gunakan *Coroutines* untuk proses *background* yang asinkron di Android.
- Jangan letakkan semua logika di `MainActivity.kt`. Pisahkan logika servis (Foreground Service, Usage Stats) ke *class* terpisah di dalam package Kotlin dan cukup panggil instansinya di `MainActivity`.

## 6. Penanganan Error (Error Handling)
- Semua fungsi yang memproses data harus mengembalikan tipe data yang aman, misalnya menggunakan *Either pattern* (package `fpdart` atau `dartz`) seperti `Future<Either<Failure, SuccessData>>`. Jangan sekadar melempar (throw) Exception yang membuat aplikasi *crash*.