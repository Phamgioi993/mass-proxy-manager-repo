#!/bin/bash

# ==============================
# Cài đặt Dante SOCKS5 Proxy
# ==============================

# Tự động đợi lock apt nếu đang bị chiếm dụng
function wait_for_apt() {
  while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
        fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
        fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
    echo "⚠️  Đang chờ apt được giải phóng..."
    sleep 3
  done
}

# Tự động phát hiện interface chính
function detect_interface() {
  ip route get 8.8.8.8 | awk '{print $5; exit}'
}

# Gửi thông tin proxy về Telegram
function send_to_telegram() {
  BOT_TOKEN="8101043998:AAEXeV13VjLn7w9Gev60ea6Sl2v2fOlhy_A"
  CHAT_ID="YOUR_CHAT_ID"
  MESSAGE="$1"
  
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
       -d "chat_id=$CHAT_ID" \
       -d "text=$MESSAGE"
}

# Bắt đầu
wait_for_apt
apt update -y && apt install -y dante-server net-tools curl

# Tạo thông tin proxy ngẫu nhiên
USERNAME="user$(openssl rand -hex 2)"
PASSWORD="$(openssl rand -hex 4)"
PORT=$((RANDOM % 10000 + 10000))
INTERFACE=$(detect_interface)

# 🛠 Tạo file cấu hình danted
cat <<EOF > /etc/danted.conf
logoutput: /var/log/danted.log
internal: $INTERFACE port = $PORT
external: $INTERFACE
method: username none
user.notprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
    command: connect
}
EOF

# Tạo user SOCKS5
useradd -M -s /usr/sbin/nologin "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd

# 🔥 Khởi động dịch vụ
systemctl restart danted
systemctl enable danted

# 🔓 Mở port nếu dùng UFW
if command -v ufw >/dev/null 2>&1; then
  ufw allow "$PORT"/tcp
fi

# 🌍 Lấy IP Public
IP=$(curl -s ipv4.icanhazip.com)

# ✅ Hiển thị & lưu thông tin
echo ""
echo -e "✅ SOCKS5 Proxy đã được cài đặt thành công!"
echo -e "🔐 Proxy: $IP:$PORT:$USERNAME:$PASSWORD"
echo "$IP:$PORT:$USERNAME:$PASSWORD" > /root/proxy-info.txt
echo "PROXY=\"$IP:$PORT:$USERNAME:$PASSWORD\"" > /root/proxy-connection.txt

# Gửi thông tin proxy về Telegram
send_to_telegram "✅ SOCKS5 Proxy đã được cài đặt thành công! 🔐 Proxy: $IP:$PORT:$USERNAME:$PASSWORD"
