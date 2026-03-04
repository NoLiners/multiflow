#!/bin/bash

# --- 1. UPDATE & INSTALL DEPENDENCIES ---
echo "Mencoba memperbarui sistem dan menginstal FFmpeg..."
sudo apt-get update
sudo apt-get install -y ffmpeg curl git unzip

# --- 2. INSTALL NODE.JS (Jika belum ada) ---
if ! command -v node &> /dev/null
then
    echo "Node.js belum terinstall. Menginstall Node.js v18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# --- 3. SETUP DIREKTORI STREAMFLOW ---
echo "Menyiapkan direktori project..."
# Folder untuk penyimpanan fragmen video HLS (.m3u8 & .ts)
mkdir -p public/live
chmod -R 777 public/live

# --- 4. INSTALL NPM PACKAGES ---
echo "Menginstal library Node.js (termasuk Node-Media-Server)..."
npm install
npm install node-media-server crypto

# --- 5. SETUP PM2 (PROCESS MANAGER) ---
echo "Menyiapkan PM2 agar aplikasi berjalan 24 jam..."
sudo npm install pm2 -g
pm2 stop all || true # Hentikan proses lama jika ada
pm2 start app.js --name streamflow-hls
pm2 save
pm2 startup

# --- 6. KONFIGURASI FIREWALL ---
echo "Membuka port yang dibutuhkan (1935:RTMP, 7575:Web, 8000:HLS)..."
sudo ufw allow 1935/tcp
sudo ufw allow 7575/tcp
sudo ufw allow 8000/tcp
sudo ufw allow 80/tcp

echo "----------------------------------------------------"
echo "INSTALASI SELESAI!"
echo "Akses Dashboard: http://IP-VPS-KAMU:7575"
echo "Push RTMP ke: rtmp://IP-VPS-KAMU/live"
echo "----------------------------------------------------"