// Impor framework Hapi.js
const Hapi = require('@hapi/hapi');
// Impor rute yang sudah didefinisikan
const routes = require('./routes');

// Fungsi async untuk inisialisasi server
const init = async () => {
    const server = Hapi.server({
        port: 9000,
        host: 'localhost', // Jalankan hanya secara lokal
        routes: {
            cors: {
                origin: ['*'], // Izinkan semua origin (CORS) untuk testing
            },
        },
    });

    // Registrasi rute
    server.route(routes);

    // Mulai server
    await server.start();
    console.log(`Server berjalan pada ${server.info.uri}`);
};

// Tangani error Promise yang tidak ditangani agar server tidak crash
process.on('unhandledRejection', (err) => {
    console.log(err);
    process.exit(1);
});

// Panggil fungsi inisialisasi
init();
