#!/bin/bash

set -e

echo "================================================"
echo "   MultiFlow Installer (FIX Clone & Engine)     "
echo "================================================"

echo "🔄 Updating sistem..."
sudo apt update && sudo apt upgrade -y

# 1. Install Node.js v22 (LTS) & FFmpeg
echo "📦 Installing Node.js v22 & FFmpeg..."
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs ffmpeg git build-essential

# 2. Setup Folder Storage HLS
echo "📁 Setting up storage..."
mkdir -p public/live
sudo chmod -R 777 public/live

# 3. FIX CLONING: Cek jika package.json belum ada
if [ ! -f "package.json" ]; then
    echo "📥 Cloning MultiFlow repository..."
    # Kita gunakan folder sementara lalu pindahkan isinya agar tidak bentrok dengan install.sh
    git clone https://github.com/NoLiners/multiflow.git temp_repo
    cp -r temp_repo/. .
    rm -rf temp_repo
else
    echo "✅ Project sudah ada, melewati tahap cloning."
fi

# 4. Install Dependencies (Gunakan --legacy-peer-deps untuk hindari konflik engine)
echo "⚙️ Installing dependencies..."
npm install --legacy-peer-deps
npm install node-media-server crypto ejs-mate --save

# 5. FIX ERROR: 'version is not defined'
echo "🛠️ Patching node-media-server..."
if [ -f "node_modules/node-media-server/src/node_trans_server.js" ]; then
    sed -i "s/version: version/version: '2.1.0'/g" node_modules/node-media-server/src/node_trans_server.js
fi

# 6. Generate Secret & Firewall
echo "🔑 Finalizing configuration..."
npm run generate-secret || true
sudo ufw allow 7575/tcp
sudo ufw allow 1935/tcp
sudo ufw allow 8000/tcp
sudo ufw --force enable

# 7. Start PM2
echo "🚀 Launching with PM2..."
sudo npm install -g pm2
pm2 delete multiflow || true
pm2 start app.js --name multiflow
pm2 save

echo "================================================"
echo "✅ INSTALASI BERHASIL!"
echo "================================================"
