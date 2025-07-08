#!/bin/bash

# ================================
# Tự động cài đặt Dante SOCKS5 Proxy
# ================================

# ⏳ Đợi apt nếu đang bị khóa
function wait_for_apt() {
  while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
        fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
        fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
    echo "⚠️  Đang chờ apt được giải phóng..."
    sleep 3
  done
}

# 🌐 Tự phát hiện interface chính
function detect_interface() {
  ip route get 8.8.8.8 | awk '{print $5; exit}'
}

# ▶️ Bắt đầu
wait_for_apt
apt update -y && apt install -y dante-server net-tools curl

# 🔐 Tạo thông tin proxy ngẫu nhiên
USERNAME="user$(openssl rand -hex 2)"
PASSWORD="$(openssl rand -hex 4)"
PORT=$((RANDOM % 10000 + 10000))
INTERFACE=$(detect_interface)

# 🛠 Tạo file cấu hình danted
cat <<EOF > /etc/danted.conf
logoutput: /var/log/danted.log
internal: $INTERFACE port = $PORT
external: $INTERFACE

method: username
user.notprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    protocol: tcp udp
    method: username
    log: connect disconnect error
}
EOF

# 👤 Tạo user SOCKS5
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
echo "$IP:$PORT:$USERNAME:$PASSWORD" > proxy-info.txt
