# Smart School - Flutter

Aplikasi Android edukasi sekolah sesuai modul project.

## Fitur
- Home / dashboard dan 13 kategori mata pelajaran
- Login admin
- CRUD artikel/materi: tambah, lihat, edit, hapus
- Database SQLite lokal: tabel users, categories, articles
- Pencarian artikel
- Tampilan responsif: grid menyesuaikan lebar layar
- Validasi login dan form artikel

## Akun demo
Username: `admin`
Password: `admin123`

Catatan: password demo disimpan sederhana untuk latihan sekolah. Jangan gunakan pola ini untuk aplikasi produksi.

## Menjalankan
1. Ekstrak ZIP dan buka folder `Smart_School_Flutter` di VS Code / Android Studio.
2. Jalankan `flutter pub get`.
3. Jalankan `flutter run`.
4. Untuk membuat APK: `flutter build apk --release`.
5. APK ada di `build/app/outputs/flutter-apk/app-release.apk`.

## Database
Database dibuat otomatis saat aplikasi pertama dibuka. SQLite menyimpan akun admin, 13 kategori mata pelajaran, dan artikel.

## Daftar pengujian
1. Home terbuka dan 13 kategori tampil.
2. Login dengan admin/admin123 berhasil.
3. Login dengan kolom kosong menampilkan validasi.
4. Login dengan password salah menampilkan pesan error.
5. Tambah artikel valid dan periksa apakah muncul.
6. Coba simpan judul kosong, judul kurang dari 3 karakter, dan isi kurang dari 10 karakter.
7. Edit artikel dan pastikan perubahan tersimpan.
8. Hapus artikel dan pastikan artikel hilang.
9. Cari artikel dengan kata kunci.
10. Uji pada beberapa ukuran layar Android.

## Catatan
SQLite adalah database lokal di perangkat. Jika guru secara khusus meminta MySQL/server online, aplikasi ini perlu ditambah backend/API.
