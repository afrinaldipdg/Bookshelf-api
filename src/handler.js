/**
 * Modul handler berisi fungsi-fungsi untuk mengelola data buku.
 * Mulai dari menambahkan buku, membaca daftar, mencari berdasarkan ID,
 * mengedit data, hingga menghapus data buku.
 */

const { nanoid } = require('nanoid');
const daftarBuku = require('./books');

/**
 * Menambahkan buku baru ke daftar
 */
const simpanBukuBaru = (request, h) => {
    const {
        name: judul,
        year: tahunTerbit,
        author: penulis,
        summary: ringkasan,
        publisher: penerbit,
        pageCount: jumlahHalaman,
        readPage: halamanDibaca,
        reading: sedangDibaca,
    } = request.payload;

    // Validasi: judul harus diisi
    if (!judul) {
        return h.response({
            status: 'fail',
            message: 'Gagal menyimpan buku. Judul tidak boleh kosong',
        }).code(400);
    }

    // Validasi: halaman dibaca tidak boleh melebihi total halaman
    if (halamanDibaca > jumlahHalaman) {
        return h.response({
            status: 'fail',
            message: 'Gagal menyimpan buku. Halaman dibaca tidak boleh lebih besar dari total halaman',
        }).code(400);
    }

    // Buat objek buku baru
    const id = nanoid(16);
    const selesaiDibaca = jumlahHalaman === halamanDibaca;
    const waktuDibuat = new Date().toISOString();

    const bukuBaru = {
        id,
        name: judul,
        year: tahunTerbit,
        author: penulis,
        summary: ringkasan,
        publisher: penerbit,
        pageCount: jumlahHalaman,
        readPage: halamanDibaca,
        finished: selesaiDibaca,
        reading: sedangDibaca,
        insertedAt: waktuDibuat,
        updatedAt: waktuDibuat,
    };

    daftarBuku.push(bukuBaru);

    const berhasil = daftarBuku.some((buku) => buku.id === id);

    if (berhasil) {
        return h.response({
            status: 'success',
            message: 'Buku berhasil disimpan',
            data: { bookId: id },
        }).code(201);
    }

    return h.response({
        status: 'error',
        message: 'Terjadi kesalahan. Buku gagal disimpan',
    }).code(500);
};

/**
 * Mengambil semua buku, dengan opsi filter nama, sedang dibaca, dan selesai dibaca
 */
const ambilSemuaBuku = (request, h) => {
    const { name, reading, finished } = request.query;

    let hasilFilter = [...daftarBuku];

    if (name) {
        hasilFilter = hasilFilter.filter((buku) =>
            buku.name.toLowerCase().includes(name.toLowerCase())
        );
    }

    if (reading !== undefined) {
        const statusBaca = reading === '1';
        hasilFilter = hasilFilter.filter((buku) => buku.reading === statusBaca);
    }

    if (finished !== undefined) {
        const statusSelesai = finished === '1';
        hasilFilter = hasilFilter.filter((buku) => buku.finished === statusSelesai);
    }

    return h.response({
        status: 'success',
        data: {
            books: hasilFilter.map((buku) => ({
                id: buku.id,
                name: buku.name,
                publisher: buku.publisher,
            })),
        },
    }).code(200);
};

/**
 * Mengambil detail satu buku berdasarkan ID
 */
const ambilBukuBerdasarkanId = (request, h) => {
    const { bookId } = request.params;
    const ditemukan = daftarBuku.find((buku) => buku.id === bookId);

    if (ditemukan) {
        return h.response({
            status: 'success',
            data: { book: ditemukan },
        }).code(200);
    }

    return h.response({
        status: 'fail',
        message: 'Buku tidak ditemukan',
    }).code(404);
};

/**
 * Memperbarui data buku berdasarkan ID
 */
const perbaruiBukuBerdasarkanId = (request, h) => {
    const { bookId } = request.params;
    const {
        name: judul,
        year: tahun,
        author: penulis,
        summary: ringkasan,
        publisher: penerbit,
        pageCount: totalHalaman,
        readPage: halamanTerbaca,
        reading: dibaca,
    } = request.payload;

    if (!judul) {
        return h.response({
            status: 'fail',
            message: 'Gagal memperbarui buku. Judul tidak boleh kosong',
        }).code(400);
    }

    if (halamanTerbaca > totalHalaman) {
        return h.response({
            status: 'fail',
            message: 'Gagal memperbarui buku. Halaman terbaca tidak boleh melebihi total halaman',
        }).code(400);
    }

    const indeks = daftarBuku.findIndex((buku) => buku.id === bookId);

    if (indeks !== -1) {
        const waktuUpdate = new Date().toISOString();
        const sudahSelesai = totalHalaman === halamanTerbaca;

        daftarBuku[indeks] = {
            ...daftarBuku[indeks],
            name: judul,
            year: tahun,
            author: penulis,
            summary: ringkasan,
            publisher: penerbit,
            pageCount: totalHalaman,
            readPage: halamanTerbaca,
            finished: sudahSelesai,
            reading: dibaca,
            updatedAt: waktuUpdate,
        };

        return h.response({
            status: 'success',
            message: 'Buku berhasil diperbarui',
        }).code(200);
    }

    return h.response({
        status: 'fail',
        message: 'Gagal memperbarui buku. ID tidak ditemukan',
    }).code(404);
};

/**
 * Menghapus buku dari daftar berdasarkan ID
 */
const hapusBukuBerdasarkanId = (request, h) => {
    const { bookId } = request.params;
    const indeks = daftarBuku.findIndex((buku) => buku.id === bookId);

    if (indeks !== -1) {
        daftarBuku.splice(indeks, 1);
        return h.response({
            status: 'success',
            message: 'Buku berhasil dihapus',
        }).code(200);
    }

    return h.response({
        status: 'fail',
        message: 'Buku gagal dihapus. ID tidak ditemukan',
    }).code(404);
};

// Ekspor semua fungsi handler dengan nama baru yang lebih khas
module.exports = {
    simpanBukuBaru,
    ambilSemuaBuku,
    ambilBukuBerdasarkanId,
    perbaruiBukuBerdasarkanId,
    hapusBukuBerdasarkanId,
};
