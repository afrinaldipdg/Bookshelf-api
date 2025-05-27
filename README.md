# 📚 Bookshelf API

![Node.js](https://img.shields.io/badge/Node.js-v18.13.0+-green?style=flat-square&logo=node.js)
![Hapi.js](https://img.shields.io/badge/Hapi.js-%5E21.3.2-blue?style=flat-square&logo=hapijs)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

> RESTful API untuk mengelola koleksi buku secara lokal. Dibangun menggunakan Node.js dan Hapi.js sebagai bagian dari submission Dicoding: *Belajar Membuat Aplikasi Back-End untuk Pemula*.

---

## 🚀 Fitur Utama

- ✅ Menambahkan buku baru
- 📖 Melihat daftar semua buku
- 🔍 Melihat detail buku berdasarkan ID
- ✏️ Memperbarui data buku
- 🗑️ Menghapus buku berdasarkan ID
- 🎯 Filter buku berdasarkan:
  - Nama (`/books?name=`)
  - Status dibaca (`/books?reading=0/1`)
  - Status selesai dibaca (`/books?finished=0/1`)

---

## 🛠️ Teknologi yang Digunakan

- [Node.js](https://nodejs.org/) v18.13.0+
- [Hapi.js](https://hapi.dev/) ^21.3.2
- [Nanoid](https://github.com/ai/nanoid) untuk ID unik
- [ESLint](https://eslint.org/) dengan konfigurasi Dicoding
- [Nodemon](https://nodemon.io/) (opsional, untuk pengembangan)

---

## 📁 Struktur Proyek

```
Bookshelf-api/
├── src/
│   ├── books.js           # Penyimpanan data buku (in-memory)
│   ├── handler.js         # Handler untuk setiap endpoint
│   ├── routes.js          # Daftar rute API
│   └── server.js          # Entry point server Hapi
├── .eslintrc.json         # Konfigurasi ESLint
├── package.json           # Informasi proyek dan dependensi
├── README.md              # Dokumentasi proyek
└── test_bookshelf_api.sh  # Skrip pengujian API (opsional)
```

---

## ⚙️ Cara Menjalankan Proyek

1. **Kloning repositori:**

   ```bash
   git clone https://github.com/afrinaldipdg/Bookshelf-api.git
   cd Bookshelf-api
   ```

2. **Instal dependensi:**

   ```bash
   npm install
   ```

3. **Jalankan server:**

   - Mode pengembangan (dengan Nodemon):

     ```bash
     npm run dev
     ```

   - Mode produksi:

     ```bash
     npm start
     ```

4. **Akses API:**

   Server akan berjalan di: `http://localhost:9000`

---

## 📬 Dokumentasi Endpoint

### 📌 Tambah Buku

- **Method:** `POST`
- **Endpoint:** `/books`
- **Body JSON:**

  ```json
  {
    "name": "Contoh Buku",
    "year": 2021,
    "author": "Penulis A",
    "summary": "Ringkasan buku",
    "publisher": "Penerbit A",
    "pageCount": 100,
    "readPage": 25,
    "reading": true
  }
  ```

### 📌 Lihat Semua Buku

- **Method:** `GET`
- **Endpoint:** `/books`
- **Query Opsional:**
  - `name`
  - `reading` (0 atau 1)
  - `finished` (0 atau 1)

### 📌 Lihat Detail Buku

- **Method:** `GET`
- **Endpoint:** `/books/{bookId}`

### 📌 Perbarui Buku

- **Method:** `PUT`
- **Endpoint:** `/books/{bookId}`
- **Body JSON:** *(sama seperti tambah buku)*

### 📌 Hapus Buku

- **Method:** `DELETE`
- **Endpoint:** `/books/{bookId}`

---

## 🧪 Pengujian API

Skrip pengujian tersedia di file `test_bookshelf_api.sh`. Pastikan Anda telah memberikan izin eksekusi:

```bash
chmod +x test_bookshelf_api.sh
./test_bookshelf_api.sh
```

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE).

---

## 🙌 Kontribusi

Kontribusi sangat terbuka! Silakan fork repositori ini dan ajukan pull request untuk perbaikan atau penambahan fitur.

---

## 📫 Kontak

Dibuat dengan ❤️ oleh [afrinaldipdg](https://github.com/afrinaldipdg)