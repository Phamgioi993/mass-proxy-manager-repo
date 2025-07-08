# Mass Proxy Manager

Script dùng để tự động cài đặt Dante SOCKS5 Proxy trên nhiều VPS.

## Gồm:
- `install.sh`: Script cài đặt proxy SOCKS5 trên từng VPS
- `mass-proxy-manager.sh`: Chạy từ máy quản lý, SSH vào VPS và cài proxy
- `servers.txt`: Danh sách IP VPS
- `proxy-info.txt`: Thông tin proxy sau khi cài

## Sử dụng

1. Điền IP vào `servers.txt`
2. Sửa `BOT_TOKEN` và `CHAT_ID` nếu dùng Telegram
3. Chạy:

```bash
chmod +x mass-proxy-manager.sh
./mass-proxy-manager.sh
```
