#!/bin/bash

# ==============================================================================
# Bookshelf API Test Script (Versi Final Perbaikan)
# ==============================================================================
#
# Script ini digunakan untuk menjalankan serangkaian tes otomatis pada Bookshelf API.
# Tes mencakup semua kriteria mandatory dan optional sesuai Postman Collection.
#
# Prasyarat:
# - Aplikasi Bookshelf API harus sudah berjalan dan dapat diakses.
#   (Contoh: di Glitch, pastikan URL BASE_URL sudah benar dan aplikasi running)
# - Tool `jq` harus terinstal di sistem Anda (untuk parsing JSON).
#   Instalasi jq: `sudo apt install jq` (Debian/Ubuntu) atau `brew install jq` (macOS)
#
# Cara Penggunaan:
# 1. Salin seluruh kode ini dan simpan dengan nama `bookshelf_api_tests.sh`.
# 2. Berikan izin eksekusi: `chmod +x bookshelf_api_tests.sh`
# 3. Jalankan script: `./bookshelf_api_tests.sh`
#
# Output:
# - Setiap tes akan menampilkan status (BERHASIL/GAGAL) dan detail respons.
# - Jika ada tes yang gagal, script akan berhenti dan menampilkan pesan error.
# - Log lengkap akan disimpan di file `test_bookshelf_api_YYYYMMDD_HHMMSS.log`.
#
# Catatan Penting:
# - Script ini akan membuat, mengubah, dan menghapus data buku di API Anda.
#   Pastikan Anda memahami dampaknya pada data yang ada.
# - Disarankan untuk me-restart server API Anda sebelum setiap kali menjalankan script
#   ini untuk memastikan kondisi data yang bersih di awal pengujian.
#
# ==============================================================================

# --- Konfigurasi Environment ---
# Ganti dengan URL dasar Glitch Anda, TANPA /books di akhir.
# Contoh: https://amplified-telling-pie.glitch.me
BASE_URL="https://amplified-telling-pie.glitch.me"

# Nama file log akan menyertakan timestamp
LOG_TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="test_bookshelf_api_${LOG_TIMESTAMP}.log"

# --- Variabel Global untuk Data Uji Dinamis ---
# ID buku yang akan disimpan dan digunakan antar tes
BOOK_ID=""
BOOK_ID_FINISHED_READING=""

# Data buku dasar untuk penambahan/pembaruan
NEW_BOOK_BASE_NAME="Buku Tes"
UPDATED_BOOK_BASE_NAME="Buku Tes Update"

# --- Fungsi Pembantu untuk Logging dan Validasi ---

# Fungsi untuk mencetak header bagian tes ke konsol dan log
print_section_header() {
    local header_text="$1"
    echo "" | tee -a "$LOG_FILE"
    echo "====================================================" | tee -a "$LOG_FILE"
    echo "=== ${header_text}" | tee -a "$LOG_FILE"
    echo "====================================================" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

# Fungsi untuk mencetak header tes individual ke konsol dan log
print_test_header() {
    local test_name="$1"
    echo "--- Menjalankan Tes: ${test_name} ---" | tee -a "$LOG_FILE"
}

# Fungsi untuk mencatat hasil respons dan melakukan validasi
# Argumen:
# 1: Nama tes (string)
# 2: Respons cURL lengkap (string)
# 3: Status HTTP yang diharapkan (string, misal "200", "201", "400", "404")
# 4: Status JSON yang diharapkan (string, misal "success", "fail")
# 5: Pesan JSON parsial yang diharapkan (string, atau kosong jika tidak diperiksa)
# 6: (Opsional) Variabel untuk menyimpan ID buku dari respons (misal "BOOK_ID")
validate_response() {
    local test_name="$1"
    local response_full="$2"
    local expected_http_status="$3"
    local expected_json_status="$4"
    local expected_json_message_partial="$5"
    local output_book_id_var="$6" # Variabel untuk menyimpan bookId jika sukses

    # Ekstrak body JSON dari respons (setelah header)
    local response_body=$(echo "${response_full}" | sed '1,/^\r*$/d')

    # Ekstrak status HTTP dari header (curl -i)
    local actual_http_status=$(echo "${response_full}" | head -n 1 | awk '{print $2}')

    # Ekstrak status dan pesan dari body JSON
    local actual_json_status=$(echo "${response_body}" | jq -r '.status // empty')
    local actual_json_message=$(echo "${response_body}" | jq -r '.message // empty')
    local extracted_book_id=$(echo "${response_body}" | jq -r '.data.bookId // empty')

    echo "Body Permintaan (jika ada):" | tee -a "$LOG_FILE"
    # Asumsi REQUEST_BODY_VAR_NAME adalah variabel global yang menyimpan body permintaan terakhir
    if [[ -n "${LAST_REQUEST_BODY}" ]]; then
        echo "${LAST_REQUEST_BODY}" | jq . | tee -a "$LOG_FILE"
    else
        echo "(Tidak ada body permintaan yang dicatat)" | tee -a "$LOG_FILE"
    fi

    echo "Body Respons:" | tee -a "$LOG_FILE"
    echo "${response_body}" | jq . | tee -a "$LOG_FILE"

    echo "Status HTTP Diharapkan: ${expected_http_status}, Aktual: ${actual_http_status}" | tee -a "$LOG_FILE"
    echo "Status JSON Diharapkan: ${expected_json_status}, Aktual: ${actual_json_status}" | tee -a "$LOG_FILE"
    if [[ -n "${expected_json_message_partial}" ]]; then
        echo "Pesan JSON Diharapkan (parsial): '${expected_json_message_partial}', Aktual: '${actual_json_message}'" | tee -a "$LOG_FILE"
    fi

    local test_passed=true

    # Validasi Status HTTP
    if [[ "${actual_http_status}" != "${expected_http_status}" ]]; then
        test_passed=false
    fi

    # Validasi Status JSON
    if [[ "${actual_json_status}" != "${expected_json_status}" ]]; then
        test_passed=false
    fi

    # Validasi Pesan JSON (jika diharapkan)
    if [[ -n "${expected_json_message_partial}" && ! "${actual_json_message}" =~ "${expected_json_message_partial}" ]]; then
        test_passed=false
    fi

    if [[ "${test_passed}" == "true" ]]; then
        echo "✅ Tes BERHASIL: ${test_name}" | tee -a "$LOG_FILE"
        # Jika ada variabel untuk menyimpan bookId dan tes sukses, simpan ID-nya
        if [[ -n "${output_book_id_var}" && -n "${extracted_book_id}" ]]; then
            eval "${output_book_id_var}=\"${extracted_book_id}\""
            echo "   ID Buku yang diekstrak: ${extracted_book_id}" | tee -a "$LOG_FILE"
        fi
        return 0 # Sukses
    else
        echo "❌ Tes GAGAL: ${test_name}" | tee -a "$LOG_FILE"
        echo "    Detail Kegagalan:" | tee -a "$LOG_FILE"
        echo "    - Status HTTP: Diharapkan '${expected_http_status}', Didapat '${actual_http_status}'" | tee -a "$LOG_FILE"
        echo "    - Status JSON: Diharapkan '${expected_json_status}', Didapat '${actual_json_status}'" | tee -a "$LOG_FILE"
        if [[ -n "${expected_json_message_partial}" ]]; then
            echo "    - Pesan JSON: Diharapkan mengandung '${expected_json_message_partial}', Didapat '${actual_json_message}'" | tee -a "$LOG_FILE"
        fi
        echo "Script dihentikan karena kegagalan tes." | tee -a "$LOG_FILE"
        exit 1 # Keluar dari script jika ada kegagalan
    fi
}

# Fungsi untuk menjalankan request cURL dan memanggil validasi
# Argumen:
# 1: Nama tes
# 2: Metode HTTP
# 3: Path URL (misal "/books" atau "/books/someid")
# 4: Body JSON (kosong jika tidak ada)
# 5: Status HTTP yang diharapkan
# 6: Status JSON yang diharapkan
# 7: Pesan JSON parsial yang diharapkan
# 8: (Opsional) Variabel untuk menyimpan ID buku
run_api_test() {
    local test_name="$1"
    local method="$2"
    local path="$3"
    local request_body="$4"
    local expected_http_status="$5"
    local expected_json_status="$6"
    local expected_json_message_partial="$7"
    local output_book_id_var="$8"

    print_test_header "${test_name}"

    LAST_REQUEST_BODY="${request_body}" # Simpan body request terakhir untuk logging

    local curl_command="curl -i -s -X ${method} \"${BASE_URL}${path}\""
    if [[ -n "${request_body}" ]]; then
        curl_command+=" -H \"Content-Type: application/json\" -d '${request_body}'"
    fi

    local response=$(eval "${curl_command}") # Jalankan perintah curl

    validate_response "${test_name}" "${response}" "${expected_http_status}" "${expected_json_status}" "${expected_json_message_partial}" "${output_book_id_var}"
    LAST_REQUEST_BODY="" # Bersihkan setelah digunakan
}

# --- Fungsi Cleanup ---
# Menghapus semua buku yang dibuat selama pengujian
cleanup_books() {
    print_section_header "CLEANUP: MENGHAPUS BUKU-BUKU YANG DIBUAT"
    echo "Mendapatkan semua buku untuk dihapus..." | tee -a "$LOG_FILE"

    # Gunakan path /books untuk GET all
    local get_all_response=$(curl -i -s -X GET "${BASE_URL}/books")
    local book_ids_to_delete=$(echo "${get_all_response}" | sed '1,/^\r*$/d' | jq -r '.data.books[].id // empty')

    if [[ -z "${book_ids_to_delete}" ]]; then
        echo "Tidak ada buku untuk dihapus." | tee -a "$LOG_FILE"
        return
    fi

    echo "ID buku yang akan dihapus: ${book_ids_to_delete}" | tee -a "$LOG_FILE"
    for book_id in ${book_ids_to_delete}; do
        # Menggunakan `printf` untuk menghindari masalah `Broken pipe` dengan `echo`
        # ketika output dialihkan ke `tee` dan proses mungkin sudah selesai.
        printf "Menghapus buku dengan ID: %s\n" "${book_id}" | tee -a "$LOG_FILE"
        # Gunakan path /books/{bookId} untuk DELETE
        local delete_response=$(curl -i -s -X DELETE "${BASE_URL}/books/${book_id}")
        local actual_http_status=$(echo "${delete_response}" | head -n 1 | awk '{print $2}')
        local actual_json_status=$(echo "${delete_response}" | sed '1,/^\r*$/d' | jq -r '.status // empty')

        if [[ "${actual_http_status}" == "200" && "${actual_json_status}" == "success" ]]; then
            printf "✅ Berhasil menghapus buku %s.\n" "${book_id}" | tee -a "$LOG_FILE"
        else
            printf "❌ Gagal menghapus buku %s.\n" "${book_id}" | tee -a "$LOG_FILE"
            echo "Respons: ${delete_response}" | tee -a "$LOG_FILE"
        fi
    done
    echo "Cleanup selesai." | tee -a "$LOG_FILE"
}


# ==============================================================================
# MULAI PENGUJIAN
# ==============================================================================
echo "Memulai Pengujian Bookshelf API. Log akan disimpan di: ${LOG_FILE}" | tee "$LOG_FILE"

# --- Pastikan server bersih sebelum memulai tes ---
cleanup_books

# ==============================================================================
# BAGIAN 1: TES MANDATORY - PENAMBAHAN BUKU (4 Tes)
# ==============================================================================
print_section_header "BAGIAN 1: TES MANDATORY - PENAMBAHAN BUKU"

# M1: Add Book With Complete Data
run_api_test \
    "M1: Menambahkan Buku dengan Data Lengkap" \
    "POST" "/books"\
    "{\"name\":\"${NEW_BOOK_BASE_NAME} 1 $(date +%s%N)\",\"year\":2023,\"author\":\"Penulis A\",\"summary\":\"Ringkasan buku A\",\"publisher\":\"Penerbit X\",\"pageCount\":150,\"readPage\":25,\"reading\":true}" \
    "201" "success" "Buku berhasil ditambahkan" \
    "BOOK_ID"

# M2: Add Book With Finished Reading (readPage === pageCount)
run_api_test \
    "M2: Menambahkan Buku yang Sudah Selesai Dibaca" \
    "POST" "/books"\
    "{\"name\":\"${NEW_BOOK_BASE_NAME} 2 $(date +%s%N)\",\"year\":2022,\"author\":\"Penulis B\",\"summary\":\"Ringkasan buku B\",\"publisher\":\"Penerbit Y\",\"pageCount\":100,\"readPage\":100,\"reading\":false}" \
    "201" "success" "Buku berhasil ditambahkan" \
    "BOOK_ID_FINISHED_READING"

# M3: Add Book Without Name (missing 'name' property)
run_api_test \
    "M3: Menambahkan Buku Tanpa Properti 'name'" \
    "POST" "/books"\
    "{\"year\":2021,\"author\":\"Penulis C\",\"summary\":\"Ringkasan buku C\",\"publisher\":\"Penerbit Z\",\"pageCount\":200,\"readPage\":50,\"reading\":true}" \
    "400" "fail" "Gagal menambahkan buku. Mohon isi nama buku"

# M4: Add Book with readPage > pageCount
run_api_test \
    "M4: Menambahkan Buku dengan readPage > pageCount" \
    "POST" "/books"\
    "{\"name\":\"${NEW_BOOK_BASE_NAME} Invalid Page\",\"year\":2020,\"author\":\"Penulis D\",\"summary\":\"Ringkasan buku D\",\"publisher\":\"Penerbit W\",\"pageCount\":100,\"readPage\":101,\"reading\":false}" \
    "400" "fail" "Gagal menambahkan buku. readPage tidak boleh lebih besar dari pageCount"

# ==============================================================================
# BAGIAN 2: TES MANDATORY - MELIHAT DAFTAR BUKU (1 Tes)
# ==============================================================================
print_section_header "BAGIAN 2: TES MANDATORY - MELIHAT DAFTAR BUKU"

# M5: Get All Books
run_api_test \
    "M5: Mendapatkan Seluruh Buku" \
    "GET" "/books"\
    "" \
    "200" "success" ""

# ==============================================================================
# BAGIAN 3: TES MANDATORY - MELIHAT DETAIL BUKU (2 Tes)
# ==============================================================================
print_section_header "BAGIAN 3: TES MANDATORY - MELIHAT DETAIL BUKU"

# M6: Get Book Detail With Correct ID
run_api_test \
    "M6: Mendapatkan Detail Buku dengan ID yang Benar" \
    "GET" "/books/${BOOK_ID}" \
    "" \
    "200" "success" ""

# M7: Get Book Detail With Invalid ID
run_api_test \
    "M7: Mendapatkan Detail Buku dengan ID yang Tidak Ditemukan" \
    "GET" "/books/invalidBookIdXYZ123" \
    "" \
    "404" "fail" "Buku tidak ditemukan"

# ==============================================================================
# BAGIAN 4: TES MANDATORY - MENGUBAH DATA BUKU (4 Tes)
# ==============================================================================
print_section_header "BAGIAN 4: TES MANDATORY - MENGUBAH DATA BUKU"

# M8: Update Book With Complete Data
run_api_test \
    "M8: Memperbarui Buku dengan Data Lengkap" \
    "PUT" "/books/${BOOK_ID}" \
    "{\"name\":\"${UPDATED_BOOK_BASE_NAME} 1 $(date +%s%N)\",\"year\":2024,\"author\":\"Penulis A Update\",\"summary\":\"Ringkasan update A\",\"publisher\":\"Penerbit X Update\",\"pageCount\":160,\"readPage\":160,\"reading\":false}" \
    "200" "success" "Buku berhasil diperbarui"

# M9: Update Book Without Name (missing 'name' property)
run_api_test \
    "M9: Memperbarui Buku Tanpa Properti 'name'" \
    "PUT" "/books/${BOOK_ID}" \
    "{\"year\":2025,\"author\":\"Penulis B Update\",\"summary\":\"Ringkasan update B\",\"publisher\":\"Penerbit Y Update\",\"pageCount\":170,\"readPage\":30,\"reading\":true}" \
    "400" "fail" "Gagal memperbarui buku. Mohon isi nama buku"

# M10: Update Book with readPage > pageCount
run_api_test \
    "M10: Memperbarui Buku dengan readPage > pageCount" \
    "PUT" "/books/${BOOK_ID}" \
    "{\"name\":\"${UPDATED_BOOK_BASE_NAME} Invalid Page\",\"year\":2026,\"author\":\"Penulis C Update\",\"summary\":\"Ringkasan update C\",\"publisher\":\"Penerbit Z Update\",\"pageCount\":100,\"readPage\":101,\"reading\":false}" \
    "400" "fail" "Gagal memperbarui buku. readPage tidak boleh lebih besar dari pageCount"

# M11: Update Book with Invalid ID
run_api_test \
    "M11: Memperbarui Buku dengan ID yang Tidak Ditemukan" \
    "PUT" "/books/invalidUpdateBookId123" \
    "{\"name\":\"${UPDATED_BOOK_BASE_NAME} Non Existent\",\"year\":2027,\"author\":\"Penulis D Update\",\"summary\":\"Ringkasan update D\",\"publisher\":\"Penerbit W Update\",\"pageCount\":180,\"readPage\":40,\"reading\":true}" \
    "404" "fail" "Gagal memperbarui buku. Id tidak ditemukan"

# ==============================================================================
# BAGIAN 5: TES OPTIONAL - QUERY PARAMETERS (5 Tes)
# ==============================================================================
print_section_header "BAGIAN 5: TES OPTIONAL - QUERY PARAMETERS"

# O1: Get All Books by Name (partial, case-insensitive)
# Kita akan mencari nama buku yang baru saja diupdate (M8)
run_api_test \
    "O1: Mendapatkan Buku Berdasarkan Query Parameter 'name'" \
    "GET" "/books?name=${UPDATED_BOOK_BASE_NAME}" \
    "" \
    "200" "success" ""

# O2: Get All Books by Reading Status (reading=1)
# Akan mencari buku yang reading: true
run_api_test \
    "O2: Mendapatkan Buku Berdasarkan Query Parameter 'reading=1'" \
    "GET" "/books?reading=1" \
    "" \
    "200" "success" ""

# O3: Get All Books by Reading Status (reading=0)
# Akan mencari buku yang reading: false (termasuk yang finished: true)
run_api_test \
    "O3: Mendapatkan Buku Berdasarkan Query Parameter 'reading=0'" \
    "GET" "/books?reading=0" \
    "" \
    "200" "success" ""

# O4: Get All Books by Finished Status (finished=1)
# Akan mencari buku yang finished: true
run_api_test \
    "O4: Mendapatkan Buku Berdasarkan Query Parameter 'finished=1'" \
    "GET" "/books?finished=1" \
    "" \
    "200" "success" ""

# O5: Get All Books by Finished Status (finished=0)
# Akan mencari buku yang finished: false
run_api_test \
    "O5: Mendapatkan Buku Berdasarkan Query Parameter 'finished=0'" \
    "GET" "/books?finished=0" \
    "" \
    "200" "success" ""

# ==============================================================================
# BAGIAN 6: TES MANDATORY - MENGHAPUS BUKU (2 Tes)
# ==============================================================================
print_section_header "BAGIAN 6: TES MANDATORY - MENGHAPUS BUKU"

# M12: Delete Book With Correct ID
run_api_test \
    "M12: Menghapus Buku dengan ID yang Benar" \
    "DELETE" "/books/${BOOK_ID}" \
    "" \
    "200" "success" "Buku berhasil dihapus"

# M13: Delete Book With Invalid ID
run_api_test \
    "M13: Menghapus Buku dengan ID yang Tidak Ditemukan" \
    "DELETE" "/books/invalidDeleteBookId123" \
    "" \
    "404" "fail" "Buku gagal dihapus. Id tidak ditemukan"

# ==============================================================================
# SELESAI PENGUJIAN
# ==============================================================================
echo "" | tee -a "$LOG_FILE"
echo "====================================================" | tee -a "$LOG_FILE"
echo "=============== SEMUA TES SELESAI ==================" | tee -a "$LOG_FILE"
echo "====================================================" | tee -a "$LOG_FILE"
echo "Jika tidak ada pesan '❌ Tes GAGAL' di atas, semua tes berhasil dilewati." | tee -a "$LOG_FILE"
echo "Log lengkap pengujian tersedia di: ${LOG_FILE}" | tee -a "$LOG_FILE"

# --- Final Cleanup ---
# Pastikan semua buku yang mungkin tersisa dihapus
cleanup_books

echo "Pengujian selesai."
