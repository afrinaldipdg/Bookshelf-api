const Hapi = require('@hapi/hapi');
const routes = require('./routes');

const init = async () => {
    const server = Hapi.server({
        port: 9000,
        host: 'localhost', // Secara eksplisit diatur ke localhost untuk pengembangan lokal
        routes: {
            cors: {
                origin: ['*'], // Izinkan semua origin untuk CORS (biasa digunakan di pengembangan)
            },
        },
    });

    server.route(routes);

    await server.start();
    console.log(`Server berjalan pada ${server.info.uri}`);
};

// Menangani Promise yang tidak tertangani untuk menghindari proses crash
process.on('unhandledRejection', (err) => {
    console.log(err);
    process.exit(1);
});

init();
