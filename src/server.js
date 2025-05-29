/**
 * File utama untuk menjalankan server Hapi
 * Menyediakan endpoint HTTP untuk aplikasi manajemen buku
 */

const Hapi = require('@hapi/hapi');
const ruteBuku = require('./routes');

/**
 * Fungsi inisialisasi server
 */
const mulaiServer = async () => {
  const server = Hapi.server({
    port: 9000,
    host: 'localhost',
    routes: {
      cors: {
        origin: ['*'], // Izinkan permintaan dari semua domain (CORS)
      },
    },
  });

  // Registrasi semua rute dari file routes.js
  server.route(ruteBuku);

  // Mulai server
  await server.start();
  // eslint-disable-next-line no-console
  console.log(`🚀 Server aktif di: ${server.info.uri}`);
};

/**
 * Tangani error yang tidak ditangani secara eksplisit
 * Agar server tidak crash tanpa log
 */
process.on('unhandledRejection', (err) => {
  // eslint-disable-next-line no-console
  console.error('❌ Terjadi kesalahan:', err);
  process.exit(1);
});

// Jalankan server
mulaiServer();
