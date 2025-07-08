#!/bin/bash
SCRIPT_URL="https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install.sh"
SERVERS_FILE="servers.txt"
SSH_USER="root"
SSH_KEY="$HOME/.ssh/id_rsa"

BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
CHAT_ID="YOUR_TELEGRAM_CHAT_ID"

function install_dante() {
  SERVER="$1"
  echo -e "\n🔧 Cài đặt Dante trên $SERVER ..."
  ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$SSH_USER@$SERVER" bash -s <<EOF
sudo -i
wget -O install.sh $SCRIPT_URL
sed -i 's/\r//' install.sh
chmod +x install.sh
./install.sh
EOF
}

while IFS= read -r server; do
  install_dante "$server"
done < "$SERVERS_FILE"
