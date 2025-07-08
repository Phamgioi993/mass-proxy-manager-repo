#!/bin/bash

# ==============================
# Cài đặt Dante SOCKS5 Proxy
# ==============================

# Tự động đợi lock apt nếu đang bị chiếm dụng
function wait_for_apt() {
  while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
        fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
        fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
    echo "Đang chờ apt unlock..."
    sleep 3
  done
}

# Tự động phát hiện interface chính
function detect_interface() {
  ip route get 8.8.8.8 | awk -- '{print $5; exit}'
}

# Thực thi cài đặt
wait_for_apt
apt update -y && apt install -y dante-server net-tools curl jq

# Tạo user/pass random
USERNAME="user$(openssl rand -hex 2)"
PASSWORD="$(openssl rand -hex 6)"

# Phát hiện interface
INTERFACE=$(detect_interface)
PORT=$(shuf -i 20000-40000 -n 1)

# Backup cấu hình cũ nếu có
mv /etc/danted.conf /etc/danted.conf.bak 2>/dev/null

# Tạo cấu hình mới
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

pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    protocol: tcp udp
    method: username
    log: connect disconnect error
}
EOF

# Tạo user đăng nhập SOCKS5
useradd -M -s /usr/sbin/nologin $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Bật và khởi động dịch vụ
systemctl restart danted
systemctl enable danted

# Mở port firewall nếu có UFW
if command -v ufw >/dev/null 2>&1; then
  ufw allow $PORT/tcp
fi

# Mở port firewall bằng gcloud nếu có
if command -v gcloud >/dev/null 2>&1; then
  gcloud compute firewall-rules create socks5-proxy-$PORT \
    --allow=tcp:$PORT --direction=INGRESS --priority=1000 --quiet \
    --action=ALLOW --rules=tcp:$PORT || true
fi

# Lấy IP public
IP=$(curl -s ipv4.icanhazip.com)

# Hiển thị thông tin
echo -e "\n✅ SOCKS5 Proxy đã được cài đặt thành công!"
echo -e "🔐 Proxy: $IP:$PORT:$USERNAME:$PASSWORD"
echo -e "📄 Đã lưu vào /root/proxy-credentials.txt và /root/proxy-connection.txt"

# Lưu ra file định dạng đầy đủ
echo "$IP:$PORT:$USERNAME:$PASSWORD" > /root/proxy-credentials.txt

# Lưu định dạng cho ứng dụng (host, port, user, pass)
echo "HOST=$IP" > /root/proxy-connection.txt
echo "PORT=$PORT" >> /root/proxy-connection.txt
echo "USERNAME=$USERNAME" >> /root/proxy-connection.txt
echo "PASSWORD=$PASSWORD" >> /root/proxy-connection.txt
