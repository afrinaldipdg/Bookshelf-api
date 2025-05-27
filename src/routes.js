/**
 * File ini mendefinisikan semua endpoint (rute) untuk REST API manajemen buku.
 * Setiap rute akan mengarahkan permintaan HTTP ke handler yang sesuai.
 */

const {
  simpanBukuBaru,
  ambilSemuaBuku,
  ambilBukuBerdasarkanId,
  perbaruiBukuBerdasarkanId,
  hapusBukuBerdasarkanId,
} = require('./handler');

/**
 * Array daftar endpoint yang digunakan oleh server Hapi.
 * Masing-masing berisi method, path, dan fungsi handler-nya.
 */
const daftarRute = [
  {
    method: 'POST',
    path: '/books',
    handler: simpanBukuBaru, // Endpoint untuk menambah buku baru
  },
  {
    method: 'GET',
    path: '/books',
    handler: ambilSemuaBuku, // Endpoint untuk mengambil semua data buku
  },
  {
    method: 'GET',
    path: '/books/{bookId}',
    handler: ambilBukuBerdasarkanId, // Endpoint untuk mengambil satu buku berdasarkan ID
  },
  {
    method: 'PUT',
    path: '/books/{bookId}',
    handler: perbaruiBukuBerdasarkanId, // Endpoint untuk memperbarui data buku
  },
  {
    method: 'DELETE',
    path: '/books/{bookId}',
    handler: hapusBukuBerdasarkanId, // Endpoint untuk menghapus buku
  },
];

// Mengekspor array daftar rute agar bisa didaftarkan di server.js
module.exports = daftarRute;