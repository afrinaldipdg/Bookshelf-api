#!/bin/bash

#  Script Otomatisasi Tes API Bookshelf dengan Logging
#  Dokumentasi Lengkap Bahasa Indonesia
#
#  Script ini menjalankan serangkaian tes API untuk aplikasi Bookshelf dan mencatat
#  hasilnya ke dalam file log. Anda dapat memilih tes individual atau menjalankan
#  semua tes sekaligus.
#
#  Cara Penggunaan:
#  1.  Simpan script ini sebagai file .sh (misalnya, `test_bookshelf_api.sh`).
#  2.  Ubah permission agar bisa dieksekusi: `chmod +x test_bookshelf_api.sh`
#  3.  Jalankan script: `./test_bookshelf_api.sh`
#  4.  Ikuti petunjuk di menu untuk memilih tes yang ingin dijalankan.
#
#  Prasyarat:
#  -   Aplikasi Bookshelf API harus sudah berjalan dan dapat diakses.
#  -   Pastikan nilai-nilai variabel di dalam script sesuai dengan environment Anda.
#      (Terutama `BASE_URL`). Data buku akan dibuat otomatis oleh script.
#  -   (Opsional) Install `jq` untuk memformat output JSON: `sudo apt install jq` (Debian/Ubuntu)
#
#  Output:
#  -   Script akan menampilkan hasil setiap tes (status code, header, body) ke terminal
#      dan juga mencatatnya ke file log.
#  -   Nama file log akan berdasarkan tanggal dan waktu saat script dijalankan.
#  -   Jika terjadi kesalahan, script akan menampilkan pesan error yang informatif.

# Konfigurasi Environment (Ganti dengan nilai sesuai environment Anda)
#!/bin/bash

BASE_URL="https://amplified-telling-pie.glitch.me/"
LOG_FILE="test_bookshelf_api.log"

declare -A test_descriptions=(
  [1]="Tambah buku baru"
  [2]="Ambil semua buku"
  [3]="Ambil buku berdasarkan ID"
  [4]="Update data buku"
  [5]="Hapus buku"
  [6]="Tambah buku dengan data tidak lengkap"
  [7]="Tambah buku dengan finished tidak sesuai"
  [8]="Ambil buku dengan ID yang tidak ada"
  [9]="Update buku dengan ID yang tidak ada"
  [10]="Hapus buku dengan ID yang tidak ada"
  [11]="Tambah buku dengan name kosong"
  [12]="Update buku dengan name kosong"
  [13]="Update finished tidak sesuai"
  [14]="Tambah buku dengan readPage > pageCount"
  [15]="Update buku dengan readPage > pageCount"
  [16]="Ambil buku berdasarkan query parameter name"
)

log_result() {
  local title="$1"
  local content="$2"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $title" >> "$LOG_FILE"
  echo "$content" >> "$LOG_FILE"
  echo "" >> "$LOG_FILE"
}

run_test() {
  local choice=$1
  local response=""
  local book_id=""
  local sample_id="not-exist-id-123"
  local title="${test_descriptions[$choice]}"

  case $choice in
    1)
      response=$(curl -s -X POST "$BASE_URL/books" \
        -H "Content-Type: application/json" \
        -d '{"name":"Buku Dicoding","year":2024,"author":"Dicoding","summary":"Belajar API","publisher":"Dicoding Indonesia","pageCount":100,"readPage":10,"reading":true}')
      book_id=$(echo "$response" | jq -r '.data.bookId')
      echo "$book_id" > book_id.tmp
      ;;
    2)
      response=$(curl -s "$BASE_URL/books")
      ;;
    3)
      book_id=$(<book_id.tmp)
      response=$(curl -s "$BASE_URL/books/$book_id")
      ;;
    4)
      book_id=$(<book_id.tmp)
      response=$(curl -s -X PUT "$BASE_URL/books/$book_id" \
        -H "Content-Type: application/json" \
        -d '{"name":"Buku Dicoding Update","year":2025,"author":"Dicoding Update","summary":"Updated","publisher":"Dicoding","pageCount":150,"readPage":100,"reading":false}')
      ;;
    5)
      book_id=$(<book_id.tmp)
      response=$(curl -s -X DELETE "$BASE_URL/books/$book_id")
      ;;
    6)
      response=$(curl -s -X POST "$BASE_URL/books" \
        -H "Content-Type: application/json" \
        -d '{"name":"Buku Incomplete"}')
      ;;
    7)
      response=$(curl -s -X POST "$BASE_URL/books" \
        -H "Content-Type: application/json" \
        -d '{"name":"Invalid Finish","pageCount":100,"readPage":150}')
      ;;
    8)
      response=$(curl -s "$BASE_URL/books/$sample_id")
      ;;
    9)
      response=$(curl -s -X PUT "$BASE_URL/books/$sample_id" \
        -H "Content-Type: application/json" \
        -d '{"name":"Non-existent"}')
      ;;
    10)
      response=$(curl -s -X DELETE "$BASE_URL/books/$sample_id")
      ;;
    11)
      response=$(curl -s -X POST "$BASE_URL/books" \
        -H "Content-Type: application/json" \
        -d '{"name":"","pageCount":100,"readPage":20}')
      ;;
    12)
      book_id=$(<book_id.tmp)
      response=$(curl -s -X PUT "$BASE_URL/books/$book_id" \
        -H "Content-Type: application/json" \
        -d '{"name":"","pageCount":100,"readPage":20}')
      ;;
    13)
      book_id=$(<book_id.tmp)
      response=$(curl -s -X PUT "$BASE_URL/books/$book_id" \
        -H "Content-Type: application/json" \
        -d '{"name":"Buku","pageCount":100,"readPage":150}')
      ;;
    14)
      response=$(curl -s -X POST "$BASE_URL/books" \
        -H "Content-Type: application/json" \
        -d '{"name":"Invalid Pages","pageCount":100,"readPage":120}')
      ;;
    15)
      book_id=$(<book_id.tmp)
      response=$(curl -s -X PUT "$BASE_URL/books/$book_id" \
        -H "Content-Type: application/json" \
        -d '{"name":"Invalid Update","pageCount":100,"readPage":120}')
      ;;
    16)
      response=$(curl -s "$BASE_URL/books?name=Buku")
      ;;
    *)
      echo "Pilihan tidak valid."
      return
      ;;
  esac

  log_result "$title" "$response"
  echo -e "\n? Tes \"$title\" selesai. Lihat hasil di $LOG_FILE\n"
  read -n 1 -s -r -p "Tekan sembarang tombol untuk kembali ke menu..."
  echo ""
}

# MENU UTAMA
while true; do
  clear
  echo "=== MENU PENGUJIAN API BUKU ==="
  for i in "${!test_descriptions[@]}"; do
    echo "$i) ${test_descriptions[$i]}"
  done | sort -n
  echo "0) Keluar"
  echo "==============================="
  read -p "Pilih nomor tes yang ingin dijalankan: " choice

  if [[ "$choice" == "0" ]]; then
    echo "Selesai. Log tersimpan di $LOG_FILE"
    exit 0
  fi

  if [[ -n "${test_descriptions[$choice]}" ]]; then
    run_test "$choice"
  else
    echo "? Pilihan tidak valid."
    read -p "Tekan Enter untuk kembali ke menu..."
  fi
done