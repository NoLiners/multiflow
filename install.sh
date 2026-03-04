#!/bin/bash

set -e

echo "================================================"
echo "   MultiFlow Installer (Node 22 + HLS FIX)      "
echo "================================================"

echo "🔄 Updating sistem..."
sudo apt update && sudo apt upgrade -y

# 1. Install Node.js v22 (LTS Terbaru) agar support library @tus
echo "📦 Installing Node.js v22..."
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs ffmpeg git build-essential

# 2. Setup Folder HLS (Penting untuk Dashboard)
echo "📁 Setting up storage..."
mkdir -p public/live
sudo chmod -R 777 public/live

# 3. Setup Project (Jika dijalankan di luar folder project)
if [ ! -f "package.json" ]; then
    echo "📥 Cloning MultiFlow..."
    git clone https://github.com/NoLiners/multiflow.git .
fi

# 4. Install Dependencies
echo "⚙️ Installing dependencies..."
# Menggunakan --force atau --legacy-peer-deps jika ada konflik versi engine lama
npm install --force
npm install node-media-server crypto ejs-mate --save

# 5. FIX: 'version is not defined' pada Node Media Server
echo "🛠️ Patching node-media-server..."
if [ -f "node_modules/node-media-server/src/node_trans_server.js" ]; then
    sed -i "s/version: version/version: '2.1.0'/g" node_modules/node-media-server/src/node_trans_server.js
fi

# 6. Config Asli StreamFlow
echo "🔑 Generating secret & setting timezone..."
npm run generate-secret || true
sudo timedatectl set-timezone Asia/Jakarta

# 7. Firewall (Membuka Web, RTMP, HLS)
echo "🔧 Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 7575/tcp
sudo ufw allow 1935/tcp
sudo ufw allow 8000/tcp
sudo ufw --force enable

# 8. Start PM2
echo "🚀 Starting with PM2..."
sudo npm install -g pm2
pm2 delete multiflow || true
pm2 start app.js --name multiflow
pm2 save

echo
echo "================================================"
echo "✅ INSTALASI SELESAI DENGAN NODE 22!"
echo "================================================"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "IP_SERVER")
echo "🌐 Dashboard: http://$SERVER_IP:7575"
echo "================================================"
