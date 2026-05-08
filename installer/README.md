# Đóng gói TCS Production thành installer

## Bước 1 — Cài Inno Setup (1 lần duy nhất)

Tải miễn phí: https://jrsoftware.org/isdl.php (file `innosetup-6.x.x.exe`).

Cài bản tiếng Anh, mặc định nó nằm ở `C:\Program Files (x86)\Inno Setup 6\`.

## Bước 2 — Build Flutter release

```powershell
cd d:\odoo17\server\flutter\odoo_production
flutter clean
flutter pub get
flutter build windows --release
```

Sau khi xong, kiểm tra folder `build\windows\x64\runner\Release\` có `odoo_production.exe`.

## Bước 3 — Compile installer

Mở **Inno Setup Compiler**, File → Open → chọn `installer\setup.iss`, rồi nhấn **Build → Compile** (hoặc phím F9).

Hoặc chạy bằng dòng lệnh:

```powershell
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "d:\odoo17\server\flutter\odoo_production\installer\setup.iss"
```

Output: `installer\Output\TCSProduction-Setup-1.0.0.exe` — copy file này sang máy đích, double-click để cài.

## Cập nhật phiên bản

Khi release bản mới: sửa `MyAppVersion` trong `setup.iss` → build lại Flutter → compile lại installer.

## Lưu ý

- `MyAppId` (GUID) **không được đổi** giữa các lần release — nó là khóa nhận diện app cho Windows. Đổi GUID = Windows coi như app khác, không upgrade được.
- Installer yêu cầu quyền Admin (`PrivilegesRequired=admin`). Nếu muốn cài user-only (vào `%LOCALAPPDATA%`), đổi thành `PrivilegesRequired=lowest` và `DefaultDirName={localappdata}\TCSProduction`.
- Server URL hiện đang hardcode `http://192.168.1.5:8069` trong `lib/app/core/constants/api_constants.dart`. Trước khi build cho khách, kiểm tra lại IP/domain server.

## Hướng dẫn cài cho end-user

Khi double-click installer, Windows SmartScreen sẽ hiện dialog xanh **"Windows protected your PC"** với dòng `Publisher: Unknown publisher`. Đây là cảnh báo mặc định cho mọi `.exe` không ký digital certificate, không phải lỗi hay virus.

Cách bypass:

1. Trong dialog xanh, click chữ **"More info"** (ở góc trái dưới dòng cảnh báo).
2. Sau khi click, một nút **"Run anyway"** xuất hiện ở góc dưới phải.
3. Click **"Run anyway"** → installer chạy bình thường.

Nếu không thấy "More info", có thể máy đó đã enable SmartScreen ở mức "Block" — cần admin vào *Settings → Privacy & security → Windows Security → App & browser control → Reputation-based protection* và đổi "Check apps and files" từ `Block` sang `Warn`.

Mỗi lần update bản mới, end-user vẫn sẽ thấy warning này (vì hash file đổi). Lặp lại bước Run anyway.
