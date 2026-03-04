#!/bin/bash

set -e

echo "================================================"
echo "   StreamFlow Installer (Original + HLS Fix)    "
echo "================================================"
echo

read -p "Mulai instalasi? (y/n): " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && echo "Instalasi dibatalkan." && exit 1

echo "🔄 Updating sistem..."
sudo apt update && sudo apt upgrade -y

# --- BAGIAN 1: INSTALL ENGINE (NODE & FFMPEG) ---
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -ge 18 ]; then
        echo "✅ Node.js sudah terinstall ($(node -v)), skip..."
    else
        echo "⚠️ Node.js versi $(node -v) terlalu lama, upgrade ke v18..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
else
    echo "📦 Installing Node.js v18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# TAMBAHAN: Install FFmpeg untuk HLS
if command -v ffmpeg &> /dev/null; then
    echo "✅ FFmpeg sudah terinstall, skip..."
else
    echo "🎬 Installing FFmpeg (Wajib untuk HLS)..."
    sudo apt install ffmpeg -y
fi

if command -v git &> /dev/null; then
    echo "✅ Git sudah terinstall, skip..."
else
    echo "🎬 Installing Git..."
    sudo apt install git -y
fi

# --- BAGIAN 2: SETUP REPOSITORY ---
echo "📥 Clone repository..."
# Cek jika folder sudah ada agar tidak error saat clone
if [ -d "streamflow" ]; then
    echo "Folder streamflow sudah ada, masuk ke direktori..."
    cd streamflow
else
    git clone https://github.com/bangtutorial/streamflow
    cd streamflow
fi

# --- BAGIAN 3: SETUP HLS STORAGE (TAMBAHAN PENTING) ---
echo "📁 Menyiapkan folder storage HLS..."
mkdir -p public/live
sudo chmod -R 777 public/live

# --- BAGIAN 4: DEPENDENCIES ---
echo "⚙️ Installing dependencies..."
npm install
# Tambahkan library pendukung streaming secara otomatis
npm install node-media-server crypto ejs-mate --save
npm run generate-secret

echo "🕐 Setup timezone ke Asia/Jakarta..."
sudo timedatectl set-timezone Asia/Jakarta

# --- BAGIAN 5: FIREWALL (TAMBAHAN PORT STREAMING) ---
echo "🔧 Setup firewall..."
sudo ufw allow ssh
sudo ufw allow 7575/tcp # Port Web
sudo ufw allow 1935/tcp # Port RTMP (OBS)
sudo ufw allow 8000/tcp # Port HLS (Player)
sudo ufw --force enable

# --- BAGIAN 6: RUNNING ---
if command -v pm2 &> /dev/null; then
    echo "✅ PM2 sudah terinstall, skip..."
else
    echo "🚀 Installing PM2..."
    sudo npm install -g pm2
fi

echo "▶️ Starting StreamFlow..."
# Pastikan proses lama dimatikan sebelum mulai baru
pm2 delete streamflow || true
pm2 start app.js --name streamflow
pm2 save

echo
echo "================================================"
echo "✅ INSTALASI SELESAI!"
echo "================================================"

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "IP_SERVER")
echo
echo "🌐 URL Akses Dashboard : http://$SERVER_IP:7575"
echo "📺 Ingest RTMP (OBS)  : rtmp://$SERVER_IP/live"
echo "🎬 Playback HLS Port  : 8000"
echo "================================================"
