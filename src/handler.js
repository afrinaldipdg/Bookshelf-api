// Mengimpor nanoid untuk membuat ID unik setiap buku
const { nanoid } = require('nanoid');

// Mengimpor array kosong untuk menyimpan buku dari file books.js
const books = require('./books');

/**
 * Menambahkan buku baru ke dalam daftar
 * @param {object} request - Permintaan dari client
 * @param {object} h - Toolkit respons dari Hapi.js
 * @returns {object} response - Objek respons berisi status dan pesan
 */
const addBookHandler = (request, h) => {
    const { name, year, author, summary, publisher, pageCount, readPage, reading } = request.payload;

    // Validasi: nama buku wajib diisi
    if (!name) {
        const response = h.response({
            status: 'fail',
            message: 'Gagal menambahkan buku. Mohon isi nama buku',
        });
        response.code(400);
        return response;
    }

    // Validasi: readPage tidak boleh lebih besar dari pageCount
    if (readPage > pageCount) {
        const response = h.response({
            status: 'fail',
            message: 'Gagal menambahkan buku. readPage tidak boleh lebih besar dari pageCount',
        });
        response.code(400);
        return response;
    }

    // Generate ID unik untuk buku
    const id = nanoid(16);
    const finished = pageCount === readPage;
    const insertedAt = new Date().toISOString();
    const updatedAt = insertedAt;

    // Membentuk objek buku baru
    const newBook = {
        id, name, year, author, summary,
        publisher, pageCount, readPage,
        finished, reading, insertedAt, updatedAt,
    };

    // Menambahkan ke array books
    books.push(newBook);

    // Verifikasi buku berhasil ditambahkan
    const isSuccess = books.filter((book) => book.id === id).length > 0;

    if (isSuccess) {
        const response = h.response({
            status: 'success',
            message: 'Buku berhasil ditambahkan',
            data: {
                bookId: id,
            },
        });
        response.code(201);
        return response;
    }

    // Gagal menambahkan buku karena alasan tak diketahui
    const response = h.response({
        status: 'error',
        message: 'Buku gagal ditambahkan',
    });
    response.code(500);
    return response;
};

/**
 * Mengambil semua buku dengan kemungkinan filter query string
 */
const getAllBooksHandler = (request, h) => {
    const { name, reading, finished } = request.query;

    let filteredBooks = books;

    // Filter berdasarkan nama (case insensitive)
    if (name) {
        filteredBooks = filteredBooks.filter((book) =>
            book.name.toLowerCase().includes(name.toLowerCase())
        );
    }

    // Filter berdasarkan status membaca
    if (reading !== undefined) {
        const isReading = reading === '1';
        filteredBooks = filteredBooks.filter((book) => book.reading === isReading);
    }

    // Filter berdasarkan status selesai dibaca
    if (finished !== undefined) {
        const isFinished = finished === '1';
        filteredBooks = filteredBooks.filter((book) => book.finished === isFinished);
    }

    const response = h.response({
        status: 'success',
        data: {
            books: filteredBooks.map((book) => ({
                id: book.id,
                name: book.name,
                publisher: book.publisher,
            })),
        },
    });
    response.code(200);
    return response;
};

/**
 * Mengambil detail satu buku berdasarkan ID
 */
const getBookByIdHandler = (request, h) => {
    const { bookId } = request.params;

    const book = books.find((b) => b.id === bookId);

    if (book) {
        const response = h.response({
            status: 'success',
            data: { book },
        });
        response.code(200);
        return response;
    }

    const response = h.response({
        status: 'fail',
        message: 'Buku tidak ditemukan',
    });
    response.code(404);
    return response;
};

/**
 * Memperbarui data buku berdasarkan ID
 */
const editBookByIdHandler = (request, h) => {
    const { bookId } = request.params;
    const { name, year, author, summary, publisher, pageCount, readPage, reading } = request.payload;

    // Validasi: nama wajib diisi
    if (!name) {
        const response = h.response({
            status: 'fail',
            message: 'Gagal memperbarui buku. Mohon isi nama buku',
        });
        response.code(400);
        return response;
    }

    // Validasi: readPage tidak boleh lebih besar dari pageCount
    if (readPage > pageCount) {
        const response = h.response({
            status: 'fail',
            message: 'Gagal memperbarui buku. readPage tidak boleh lebih besar dari pageCount',
        });
        response.code(400);
        return response;
    }

    const index = books.findIndex((book) => book.id === bookId);

    if (index !== -1) {
        const updatedAt = new Date().toISOString();
        const finished = pageCount === readPage;

        // Perbarui nilai buku
        books[index] = {
            ...books[index],
            name,
            year,
            author,
            summary,
            publisher,
            pageCount,
            readPage,
            finished,
            reading,
            updatedAt,
        };

        const response = h.response({
            status: 'success',
            message: 'Buku berhasil diperbarui',
        });
        response.code(200);
        return response;
    }

    // Jika ID tidak ditemukan
    const response = h.response({
        status: 'fail',
        message: 'Gagal memperbarui buku. Id tidak ditemukan',
    });
    response.code(404);
    return response;
};

/**
 * Menghapus buku berdasarkan ID
 */
const deleteBookByIdHandler = (request, h) => {
    const { bookId } = request.params;

    const index = books.findIndex((book) => book.id === bookId);

    if (index !== -1) {
        books.splice(index, 1);
        const response = h.response({
            status: 'success',
            message: 'Buku berhasil dihapus',
        });
        response.code(200);
        return response;
    }

    const response = h.response({
        status: 'fail',
        message: 'Buku gagal dihapus. Id tidak ditemukan',
    });
    response.code(404);
    return response;
};

// Mengekspor semua handler untuk digunakan di routes.js
module.exports = {
    addBookHandler,
    getAllBooksHandler,
    getBookByIdHandler,
    editBookByIdHandler,
    deleteBookByIdHandler,
};
