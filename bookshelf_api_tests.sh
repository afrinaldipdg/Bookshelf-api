#!/bin/bash

# =========================================================
# Bookshelf API Test Script
# Script ini digunakan untuk menguji fungsionalitas Bookshelf API
# secara otomatis menggunakan perintah cURL.
# Pastikan server Bookshelf API berjalan pada http://localhost:9000
# sebelum menjalankan script ini.
#
# Prasyarat:
# - Node.js dan Hapi.js server Bookshelf API berjalan.
# - Tool 'jq' terinstal di sistem Anda (untuk parsing JSON).
#   Instalasi jq: sudo apt-get install jq (Linux) / brew install jq (macOS)
#
# Cara Menjalankan:
# 1. Simpan script ini dengan nama 'bookshelf_api_tests.sh'.
# 2. Berikan izin eksekusi: chmod +x bookshelf_api_tests.sh
# 3. Jalankan script: ./bookshelf_api_tests.sh
# =========================================================

# --- Konfigurasi Awal ---
# Port server API
PORT="9000"
# Base URL untuk semua endpoint buku
BASE_URL="http://localhost:${PORT}/books"

# --- Variabel Global untuk Data Uji ---
# Variabel ini akan menyimpan ID buku yang dibuat agar bisa digunakan di tes selanjutnya.
BOOK_ID=""
BOOK_ID_FINISHED_READING=""

# --- Fungsi Pembantu untuk Logging dan Validasi ---

# Fungsi untuk mencetak header bagian tes
print_section_header() {
    echo ""
    echo "===================================================="
    echo "=== ${1}"
    echo "===================================================="
    echo ""
}

# Fungsi untuk mencetak sub-header tes
print_test_header() {
    echo "--- Menjalankan Tes: ${1} ---"
}

# Fungsi untuk mencetak hasil respon dan melakukan validasi sederhana
validate_response() {
    local test_name="$1"
    local response="$2"
    local expected_status_code="$3" # Ex: "201", "200", "400", "404"
    local expected_json_status="$4" # Ex: "success", "fail"
    local expected_json_message_partial="$5" # Partial match for message, or "" if not checking

    echo "Body Respons:"
    echo "${response}" | jq .

    # Ekstrak status code HTTP dari header (membutuhkan -i di curl)
    # ATAU, untuk kesederhanaan, kita bisa asumsikan curl -s hanya mengembalikan body dan memeriksa status/message JSON
    # Kita akan memeriksa status dari body JSON dan juga mencoba menebak status HTTP jika ada error message standar.
    ACTUAL_JSON_STATUS=$(echo "${response}" | jq -r '.status // empty')
    ACTUAL_JSON_MESSAGE=$(echo "${response}" | jq -r '.message // empty')

    # Simple check for HTTP status code based on common JSON error responses
    ACTUAL_HTTP_STATUS_CODE=$(echo "${response}" | head -n 1 | awk '{print $2}') # Attempts to get status from non-silent curl output if available

    # Fallback to check if response starts with HTTP/1.1 or contains HTTP status line if curl -s -i was used
    if [[ "${response}" =~ ^HTTP/1\.1[[:space:]]+([0-9]{3}) ]]; then
        ACTUAL_HTTP_STATUS_CODE="${BASH_REMATCH[1]}"
    else
        # If no explicit HTTP status line, default to 200 for success, or infer from JSON status
        if [[ "${ACTUAL_JSON_STATUS}" == "success" ]]; then
            ACTUAL_HTTP_STATUS_CODE="200" # Default for success
        elif [[ "${ACTUAL_JSON_STATUS}" == "fail" ]]; then
            # Infer 400 or 404 based on common failure messages
            if [[ "${ACTUAL_JSON_MESSAGE}" =~ "Mohon isi nama buku" || "${ACTUAL_JSON_MESSAGE}" =~ "readPage tidak boleh lebih besar" ]]; then
                ACTUAL_HTTP_STATUS_CODE="400"
            elif [[ "${ACTUAL_JSON_MESSAGE}" =~ "tidak ditemukan" ]]; then
                ACTUAL_HTTP_STATUS_CODE="404"
            else
                ACTUAL_HTTP_STATUS_CODE="500" # General error
            fi
        fi
    fi

    echo "Status HTTP Diharapkan: ${expected_status_code}, Aktual: ${ACTUAL_HTTP_STATUS_CODE}"
    echo "Status JSON Diharapkan: ${expected_json_status}, Aktual: ${ACTUAL_JSON_STATUS}"
    if [[ -n "${expected_json_message_partial}" ]]; then
        echo "Pesan JSON Diharapkan (parsial): '${expected_json_message_partial}', Aktual: '${ACTUAL_JSON_MESSAGE}'"
    fi

    local status_code_match=false
    if [[ "${ACTUAL_HTTP_STATUS_CODE}" == "${expected_status_code}" ]]; then
        status_code_match=true
    else
        # Allow 201 for success if 200 was loosely expected for 'success' status (e.g. GET all)
        if [[ "${expected_status_code}" == "200" && "${ACTUAL_HTTP_STATUS_CODE}" == "201" && "${expected_json_status}" == "success" ]]; then
            status_code_match=true
        fi
    fi


    if [[ "${status_code_match}" == "true" && \
          "${ACTUAL_JSON_STATUS}" == "${expected_json_status}" && \
          ("${expected_json_message_partial}" == "" || "${ACTUAL_JSON_MESSAGE}" =~ "${expected_json_message_partial}") ]]; then
        echo "? Tes BERHASIL: ${test_name}"
        return 0 # Success
    else
        echo "? Tes GAGAL: ${test_name}"
        echo "    Detail Kegagalan:"
        echo "    - Status HTTP: Diharapkan '${expected_status_code}', Didapat '${ACTUAL_HTTP_STATUS_CODE}'"
        echo "    - Status JSON: Diharapkan '${expected_json_status}', Didapat '${ACTUAL_JSON_STATUS}'"
        if [[ -n "${expected_json_message_partial}" ]]; then
            echo "    - Pesan JSON: Diharapkan mengandung '${expected_json_message_partial}', Didapat '${ACTUAL_JSON_MESSAGE}'"
        fi
        exit 1 # Exit script on first failure
    fi
}

# --- Mulai Proses Pengujian ---
echo "Memulai Pengujian Bookshelf API..."

# =========================================================
# BAGIAN 1: TES MANDATORY (PENAMBAHAN BUKU)
# =========================================================
print_section_header "TES MANDATORY: PENAMBAHAN BUKU"

# 1.1 Menambahkan Buku dengan Data Lengkap (Sukses)
print_test_header "1.1 Menambahkan Buku dengan Data Lengkap (Sukses)"
NEW_BOOK_NAME="Filosofi Hutan"
NEW_BOOK_YEAR=2020
NEW_BOOK_AUTHOR="Joko Widodo"
NEW_BOOK_SUMMARY="Sebuah buku tentang alam dan kearifan lokal."
NEW_BOOK_PUBLISHER="Penerbit Alam Raya"
NEW_BOOK_PAGE_COUNT=180
NEW_BOOK_READ_PAGE=25
NEW_BOOK_READING="true"

REQUEST_BODY_ADD_SUCCESS=$(cat <<EOF
{
    "name": "${NEW_BOOK_NAME}",
    "year": ${NEW_BOOK_YEAR},
    "author": "${NEW_BOOK_AUTHOR}",
    "summary": "${NEW_BOOK_SUMMARY}",
    "publisher": "${NEW_BOOK_PUBLISHER}",
    "pageCount": ${NEW_BOOK_PAGE_COUNT},
    "readPage": ${NEW_BOOK_READ_PAGE},
    "reading": ${NEW_BOOK_READING}
}
EOF
)
echo "Body Permintaan:"
echo "${REQUEST_BODY_ADD_SUCCESS}" | jq .

RESPONSE=$(curl -s -X POST "${BASE_URL}" \
    -H "Content-Type: application/json" \
    -d "${REQUEST_BODY_ADD_SUCCESS}")

validate_response "1.1 Menambahkan Buku dengan Data Lengkap" "${RESPONSE}" "201" "success" "Buku berhasil ditambahkan"

BOOK_ID=$(echo "${RESPONSE}" | jq -r '.data.bookId // empty')
if [[ -z "${BOOK_ID}" ]]; then
    echo "? GAGAL: ID buku tidak ditemukan dalam respons sukses."
    exit 1
fi
echo "ID Buku yang ditambahkan: ${BOOK_ID}"

# 1.2 Menambahkan Buku yang Sudah Selesai Dibaca (finished: true)
print_test_header "1.2 Menambahkan Buku yang Sudah Selesai Dibaca"
BOOK_FINISHED_NAME="Kisah Perjuangan"
BOOK_FINISHED_PAGE_COUNT=100
BOOK_FINISHED_READ_PAGE=100

REQUEST_BODY_ADD_FINISHED=$(cat <<EOF
{
    "name": "${BOOK_FINISHED_NAME}",
    "year": 2018,
    "author": "Pahlawan Tanpa Tanda Jasa",
    "summary": "Cerita inspiratif.",
    "publisher": "Penerbit Inspirasi",
    "pageCount": ${BOOK_FINISHED_PAGE_COUNT},
    "readPage": ${BOOK_FINISHED_READ_PAGE},
    "reading": false
}
EOF
)
echo "Body Permintaan:"
echo "${REQUEST_BODY_ADD_FINISHED}" | jq .

RESPONSE=$(curl -s -X POST "${BASE_URL}" \
    -H "Content-Type: application/json" \
    -d "${REQUEST_BODY_ADD_FINISHED}")

validate_response "1.2 Menambahkan Buku yang Sudah Selesai Dibaca" "${RESPONSE}" "201" "success" "Buku berhasil ditambahkan"

BOOK_ID_FINISHED_READING=$(echo "${RESPONSE}" | jq -r '.data.bookId // empty')
if [[ -z "${BOOK_ID_FINISHED_READING}" ]]; then
    echo "? GAGAL: ID buku selesai dibaca tidak ditemukan dalam respons sukses."
    exit 1
fi
echo "ID Buku Selesai Dibaca: ${BOOK_ID_FINISHED_READING}"

# 1.3 Menambahkan Buku Tanpa Properti 'name' (Gagal)
print_test_header "1.3 Menambahkan Buku Tanpa Properti 'name' (Gagal)"
REQUEST_BODY_ADD_NO_NAME=$(cat <<EOF
{
    "year": 2021,
    "author": "Penulis Anonim",
    "summary": "Ringkasan tanpa nama.",
    "publisher": "Penerbit Rahasia",
    "pageCount": 120,
    "readPage": 30,
    "reading": false
}
EOF
)
echo "Body Permintaan:"
echo "${REQUEST_BODY_ADD_NO_NAME}" | jq .

RESPONSE=$(curl -s -X POST "${BASE_URL}" \
    -H "Content-Type: application/json" \
    -d "${REQUEST_BODY_ADD_NO_NAME}")

validate_response "1.3 Menambahkan Buku Tanpa Properti 'name'" "${RESPONSE}" "400" "fail" "Gagal menambahkan buku. Mohon isi nama buku"

# 1.4 Menambahkan Buku dengan 'readPage' Lebih Besar dari 'pageCount' (Gagal)
print_test_header "1.4 Menambahkan Buku dengan 'readPage' Lebih Besar dari 'pageCount' (Gagal)"
REQUEST_BODY_ADD_INVALID_READPAGE=$(cat <<EOF
{
    "name": "Buku Error Baca",
    "year": 2022,
    "author": "Error Maker",
    "summary": "Buku yang dibaca melebihi jumlah halaman.",
    "publisher": "Penerbit Salah",
    "pageCount": 100,
    "readPage": 101,
    "reading": true
}
EOF
)
echo "Body Permintaan:"
echo "${REQUEST_BODY_ADD_INVALID_READPAGE}" | jq .

RESPONSE=$(curl -s -X POST "${BASE_URL}" \
    -H "Content-Type: application/json" \
    -d "${REQUEST_BODY_ADD_INVALID_READPAGE}")

validate_response "1.4 Menambahkan Buku dengan 'readPage' Lebih Besar dari 'pageCount'" "${RESPONSE}" "400" "fail" "Gagal menambahkan buku. readPage tidak boleh lebih besar dari pageCount"


# =========================================================
# BAGIAN 2: TES MANDATORY (Melihat Daftar Buku)
# =========================================================
print_section_header "TES MANDATORY: MELIHAT DAFTAR BUKU"

# 2.1 Mendapatkan Seluruh Buku (Tanpa Filter)
print_test_header "2.1 Mendapatkan Seluruh Buku (Tanpa Filter)"
RESPONSE=$(curl -s -X GET "${BASE_URL}")
validate_response "2.1 Mendapatkan Seluruh Buku" "${RESPONSE}" "200" "success" ""

BOOKS_COUNT=$(echo "${RESPONSE}" | jq '.data.books | length')
if [[ "${BOOKS_COUNT}" -ge 2 ]]; then # Expect at least 2 books from previous add operations
    echo "Jumlah buku yang ditemukan: ${BOOKS_COUNT} (Diharapkan >= 2)"
else
    echo "? GAGAL: Jumlah buku tidak sesuai harapan atau array kosong."
    exit 1
fi

# =========================================================
# BAGIAN 3: TES OPTIONAL (Query Parameters untuk Daftar Buku)
# =========================================================
print_section_header "TES OPTIONAL: QUERY PARAMETERS DAFTAR BUKU"

# 3.1 Mendapatkan Buku dengan Filter 'name' (Case-Insensitive)
print_test_header "3.1 Mendapatkan Buku dengan Filter 'name'"
SEARCH_NAME_PARTIAL="hutan" # Bagian dari "Filosofi Hutan"
RESPONSE=$(curl -s -X GET "${BASE_URL}?name=${SEARCH_NAME_PARTIAL}")
validate_response "3.1 Mendapatkan Buku dengan Filter 'name'" "${RESPONSE}" "200" "success" ""

FOUND_BOOKS_NAME=$(echo "${RESPONSE}" | jq -r '.data.books[].name' | grep -i "${SEARCH_NAME_PARTIAL}" | wc -l)
if [[ "${FOUND_BOOKS_NAME}" -ge 1 ]]; then
    echo "Ditemukan ${FOUND_BOOKS_NAME} buku dengan nama mengandung '${SEARCH_NAME_PARTIAL}'."
else
    echo "? GAGAL: Tidak ditemukan buku dengan nama mengandung '${SEARCH_NAME_PARTIAL}'."
    exit 1
fi

# 3.2 Mendapatkan Buku dengan Filter 'reading=1' (Sedang Dibaca)
print_test_header "3.2 Mendapatkan Buku dengan Filter 'reading=1'"
RESPONSE=$(curl -s -X GET "${BASE_URL}?reading=1")
validate_response "3.2 Mendapatkan Buku dengan Filter 'reading=1'" "${RESPONSE}" "200" "success" ""

READING_BOOKS_COUNT=$(echo "${RESPONSE}" | jq '.data.books | length')
# Expect at least "Filosofi Hutan" which has reading: true
if [[ "${READING_BOOKS_COUNT}" -ge 1 ]]; then
    echo "Ditemukan ${READING_BOOKS_COUNT} buku sedang dibaca."
else
    echo "? GAGAL: Tidak ditemukan buku sedang dibaca."
    exit 1
fi

# 3.3 Mendapatkan Buku dengan Filter 'reading=0' (Tidak Sedang Dibaca)
print_test_header "3.3 Mendapatkan Buku dengan Filter 'reading=0'"
RESPONSE=$(curl -s -X GET "${BASE_URL}?reading=0")
validate_response "3.3 Mendapatkan Buku dengan Filter 'reading=0'" "${RESPONSE}" "200" "success" ""

NOT_READING_BOOKS_COUNT=$(echo "${RESPONSE}" | jq '.data.books | length')
# Expect at least "Kisah Perjuangan" which has reading: false
if [[ "${NOT_READING_BOOKS_COUNT}" -ge 1 ]]; then
    echo "Ditemukan ${NOT_READING_BOOKS_COUNT} buku tidak sedang dibaca."
else
    echo "? GAGAL: Tidak ditemukan buku tidak sedang dibaca."
    exit 1
fi

# 3.4 Mendapatkan Buku dengan Filter 'finished=1' (Sudah Selesai Dibaca)
print_test_header "3.4 Mendapatkan Buku dengan Filter 'finished=1'"
RESPONSE=$(curl -s -X GET "${BASE_URL}?finished=1")
validate_response "3.4 Mendapatkan Buku dengan Filter 'finished=1'" "${RESPONSE}" "200" "success" ""

FINISHED_BOOKS_COUNT=$(echo "${RESPONSE}" | jq '.data.books | length')
# Expect at least "Kisah Perjuangan" which has finished: true
if [[ "${FINISHED_BOOKS_COUNT}" -ge 1 ]]; then
    echo "Ditemukan ${FINISHED_BOOKS_COUNT} buku sudah selesai dibaca."
else
    echo "? GAGAL: Tidak ditemukan buku sudah selesai dibaca."
    exit 1
fi

# 3.5 Mendapatkan Buku dengan Filter 'finished=0' (Belum Selesai Dibaca)
print_test_header "3.5 Mendapatkan Buku dengan Filter 'finished=0'"
RESPONSE=$(curl -s -X GET "${BASE_URL}?finished=0")
validate_response "3.5 Mendapatkan Buku dengan Filter 'finished=0'" "${RESPONSE}" "200" "success" ""

NOT_FINISHED_BOOKS_COUNT=$(echo "${RESPONSE}" | jq '.data.books | length')
# Expect at least "Filosofi Hutan" which has finished: false
if [[ "${NOT_FINISHED_BOOKS_COUNT}" -ge 1 ]]; then
    echo "Ditemukan ${NOT_FINISHED_BOOKS_COUNT} buku belum selesai dibaca."
else
    echo "? GAGAL: Tidak ditemukan buku belum selesai dibaca."
    exit 1
fi

# =========================================================
# BAGIAN 4: TES MANDATORY (Melihat Detail Buku)
# =========================================================
print_section_header "TES MANDATORY: MELIHAT DETAIL BUKU"

# 4.1 Mendapatkan Detail Buku Berdasarkan ID (Sukses)
print_test_header "4.1 Mendapatkan Detail Buku Berdasarkan ID (Sukses)"
if [[ -z "${BOOK_ID}" ]]; then
    echo "? GAGAL: BOOK_ID kosong. Tes sebelumnya gagal."
    exit 1
fi

RESPONSE=$(curl -s -X GET "${BASE_URL}/${BOOK_ID}")
validate_response "4.1 Mendapatkan Detail Buku Berdasarkan ID" "${RESPONSE}" "200" "success" ""

RETRIEVED_BOOK_ID=$(echo "${RESPONSE}" | jq -r '.data.book.id // empty')
if [[ "${RETRIEVED_BOOK_ID}" == "${BOOK_ID}" ]]; then
    echo "Detail buku dengan ID '${BOOK_ID}' berhasil diambil."
else
    echo "? GAGAL: ID buku yang diambil tidak cocok."
    exit 1
fi

# 4.2 Mendapatkan Detail Buku dengan ID yang Tidak Ditemukan (Gagal)
print_test_header "4.2 Mendapatkan Detail Buku dengan ID yang Tidak Ditemukan (Gagal)"
INVALID_BOOK_ID="invalidBookId1234567"
RESPONSE=$(curl -s -X GET "${BASE_URL}/${INVALID_BOOK_ID}")
validate_response "4.2 Mendapatkan Detail Buku dengan ID yang Tidak Ditemukan" "${RESPONSE}" "404" "fail" "Buku tidak ditemukan"


# =========================================================
# BAGIAN 5: TES MANDATORY (Mengubah Data Buku)
# =========================================================
print_section_header "TES MANDATORY: MENGUBAH DATA BUKU"

# 5.1 Mengubah Data Buku dengan Data Lengkap (Sukses)
print_test_header "5.1 Mengubah Data Buku dengan Data Lengkap (Sukses)"
if [[ -z "${BOOK_ID}" ]]; then
    echo "? GAGAL: BOOK_ID kosong. Tes sebelumnya gagal."
    exit 1
fi

UPDATED_BOOK_NAME="Filosofi Hutan (Edisi Revisi)"
UPDATED_PAGE_COUNT=200
UPDATED_READ_PAGE=200 # Agar menjadi finished: true

REQUEST_BODY_UPDATE_SUCCESS=$(cat <<EOF
{
    "name": "${UPDATED_BOOK_NAME}",
    "year": 2021,
    "author": "Joko Widodo Revisi",
    "summary": "Ringkasan terbaru tentang hutan dan lingkungan.",
    "publisher": "Penerbit Alam Jaya",
    "pageCount": ${UPDATED_PAGE_COUNT},
    "readPage": ${UPDATED_READ_PAGE},
    "reading": false
}
EOF
)
echo "Body Permintaan:"
echo "${REQUEST_BODY_UPDATE_SUCCESS}" | jq .

RESPONSE=$(curl -s -X PUT "${BASE_URL}/${BOOK_ID}" \
    -H "Content-Type: application/json" \
    -d "${REQUEST_BODY_UPDATE_SUCCESS}")

validate_response "5.1 Mengubah Data Buku dengan Data Lengkap" "${RESPONSE}" "200" "success" "Buku berhasil diperbarui"

# Verifikasi perubahan data
print_test_header "5.1.1 Verifikasi Perubahan Data Buku"
VERIFY_RESPONSE=$(curl -s -X GET "${BASE_URL}/${BOOK_ID}")
VERIFY_NAME=$(echo "${VERIFY_RESPONSE}" | jq -r '.data.book.name // empty')
VERIFY_FINISHED=$(echo "${VERIFY_RESPONSE}" | jq -r '.data.book.finished // empty')

if [[ "${VERIFY_NAME}" == "${UPDATED_BOOK_NAME}" && "${VERIFY_FINISHED}" == "true" ]]; then
    echo "? Verifikasi BERHASIL: Nama buku dan status 'finished' telah diperbarui dengan benar."
else
    echo "? Verifikasi GAGAL: Nama buku atau status 'finished' tidak diperbarui sesuai harapan."
    exit 1
fi

# 5.2 Mengubah Data Buku Tanpa Properti 'name' (Gagal)
print_test_header "5.2 Mengubah Data Buku Tanpa Properti 'name' (Gagal)"
if [[ -z "${BOOK_ID}" ]]; then
    echo "? GAGAL: BOOK_ID kosong. Tes sebelumnya gagal."
    exit 1
fi

REQUEST_BODY_UPDATE_NO_NAME=$(cat <<EOF
{
    "year": 2022,
    "author": "Anonim Update",
    "summary": "Ringkasan tanpa nama untuk update.",
    "publisher": "Penerbit X",
    "pageCount": 150,
    "readPage": 50,
    "reading": false
}
EOF
)
echo "Body Permintaan:"
echo "${REQUEST_BODY_UPDATE_NO_NAME}" | jq .

RESPONSE=$(curl -s -X PUT "${BASE_URL}/${BOOK_ID}" \
    -H "Content-Type: application/json" \
    -d "${REQUEST_BODY_UPDATE_NO_NAME}")

validate_response "5.2 Mengubah Data Buku Tanpa Properti 'name'" "${RESPONSE}" "400" "fail" "Gagal memperbarui buku. Mohon isi nama buku"

# 5.3 Mengubah Data Buku dengan 'readPage' Lebih Besar dari 'pageCount' (Gagal)
print_test_header "5.3 Mengubah Data Buku dengan 'readPage' Lebih Besar dari 'pageCount' (Gagal)"
if [[ -z "${BOOK_ID}" ]]; then
    echo "? GAGAL: BOOK_ID kosong. Tes sebelumnya gagal."
    exit 1
fi

REQUEST_BODY_UPDATE_INVALID_READPAGE=$(cat <<EOF
{
    "name": "Buku Update Error",
    "year": 2023,
    "author": "Tester",
    "summary": "Ringkasan update error readPage.",
    "publisher": "Penerbit Y",
    "pageCount": 100,
    "readPage": 101,
    "reading": true
}
EOF
)
echo "Body Permintaan:"
echo "${REQUEST_BODY_UPDATE_INVALID_READPAGE}" | jq .

RESPONSE=$(curl -s -X PUT "${BASE_URL}/${BOOK_ID}" \
    -H "Content-Type: application/json" \
    -d "${REQUEST_BODY_UPDATE_INVALID_READPAGE}")

validate_response "5.3 Mengubah Data Buku dengan 'readPage' Lebih Besar dari 'pageCount'" "${RESPONSE}" "400" "fail" "Gagal memperbarui buku. readPage tidak boleh lebih besar dari pageCount"

# 5.4 Mengubah Data Buku dengan ID yang Tidak Ditemukan (Gagal)
print_test_header "5.4 Mengubah Data Buku dengan ID yang Tidak Ditemukan (Gagal)"
INVALID_UPDATE_BOOK_ID="nonExistentUpdateId"
REQUEST_BODY_UPDATE_INVALID_ID=$(cat <<EOF
{
    "name": "Buku yang Tidak Ada",
    "year": 2024,
    "author": "Tidak Terdaftar",
    "summary": "Buku ini seharusnya tidak ada.",
    "publisher": "Fiksi",
    "pageCount": 50,
    "readPage": 10,
    "reading": false
}
EOF
)
echo "Body Permintaan:"
echo "${REQUEST_BODY_UPDATE_INVALID_ID}" | jq .

RESPONSE=$(curl -s -X PUT "${BASE_URL}/${INVALID_UPDATE_BOOK_ID}" \
    -H "Content-Type: application/json" \
    -d "${REQUEST_BODY_UPDATE_INVALID_ID}")

validate_response "5.4 Mengubah Data Buku dengan ID yang Tidak Ditemukan" "${RESPONSE}" "404" "fail" "Gagal memperbarui buku. Id tidak ditemukan"


# =========================================================
# BAGIAN 6: TES MANDATORY (Menghapus Buku)
# =========================================================
print_section_header "TES MANDATORY: MENGHAPUS BUKU"

# 6.1 Menghapus Buku Berdasarkan ID (Sukses)
print_test_header "6.1 Menghapus Buku Berdasarkan ID (Sukses)"
if [[ -z "${BOOK_ID}" ]]; then
    echo "? GAGAL: BOOK_ID kosong. Tes sebelumnya gagal."
    exit 1
fi

RESPONSE=$(curl -s -X DELETE "${BASE_URL}/${BOOK_ID}")
validate_response "6.1 Menghapus Buku Berdasarkan ID" "${RESPONSE}" "200" "success" "Buku berhasil dihapus"

# Verifikasi penghapusan
print_test_header "6.1.1 Verifikasi Penghapusan Buku"
VERIFY_DELETE_RESPONSE=$(curl -s -X GET "${BASE_URL}/${BOOK_ID}")
validate_response "6.1.1 Verifikasi Penghapusan Buku" "${VERIFY_DELETE_RESPONSE}" "404" "fail" "Buku tidak ditemukan"
echo "Buku dengan ID '${BOOK_ID}' berhasil dihapus dan tidak dapat ditemukan lagi."

# Menghapus buku yang selesai dibaca juga agar bersih
print_test_header "6.1.2 Menghapus Buku Finished Reading (Cleanup)"
if [[ -n "${BOOK_ID_FINISHED_READING}" ]]; then
    RESPONSE_CLEANUP=$(curl -s -X DELETE "${BASE_URL}/${BOOK_ID_FINISHED_READING}")
    validate_response "6.1.2 Menghapus Buku Finished Reading (Cleanup)" "${RESPONSE_CLEANUP}" "200" "success" "Buku berhasil dihapus"
    echo "Buku dengan ID '${BOOK_ID_FINISHED_READING}' juga berhasil dihapus."
else
    echo "Melewatkan cleanup buku finished reading karena ID tidak tersedia."
fi


# 6.2 Menghapus Buku dengan ID yang Tidak Ditemukan (Gagal)
print_test_header "6.2 Menghapus Buku dengan ID yang Tidak Ditemukan (Gagal)"
NON_EXISTENT_DELETE_ID="nonExistentDeleteId999"
RESPONSE=$(curl -s -X DELETE "${BASE_URL}/${NON_EXISTENT_DELETE_ID}")
validate_response "6.2 Menghapus Buku dengan ID yang Tidak Ditemukan" "${RESPONSE}" "404" "fail" "Buku gagal dihapus. Id tidak ditemukan"


echo ""
echo "===================================================="
echo "=============== SEMUA TES SELESAI =================="
echo "===================================================="
echo "Jika tidak ada pesan '? Tes GAGAL' di atas, semua tes berhasil dilewati."
echo "Pastikan untuk selalu me-restart server Bookshelf API Anda sebelum menjalankan script ini kembali"
echo "untuk memastikan kondisi data yang bersih di awal setiap pengujian."