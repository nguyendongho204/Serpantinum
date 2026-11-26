# Serpantinum — bản damournora

Fork giao diện **Serpantinum** dành cho Hyprland, bổ sung bộ chọn **màn hình đăng nhập SDDM** ngay trong Cài đặt.

> Dựa trên dự án gốc [Serpantinum](https://github.com/ilyamiro/serpantinum) của **ilyamiro** (AGPL-3.0).
> Phần tuỳ biến và bảo trì bởi **damournora**.

## Tính năng thêm

- Tab **Màn hình → Màn hình đăng nhập** trong Cài đặt.
- Liệt kê theme SDDM đã cài, có ảnh xem trước (video → thumbnail).
- **Tìm kiếm** theme theo tên/mô tả.
- **Xem trước full màn hình** bằng SDDM greeter Qt6 thật.
- **Áp dụng** theme (có hiệu lực sau khi đăng xuất/khởi động lại).
- **Xoá theme** có xác nhận; chặn xoá theme đang dùng.
- **Kiểm tra theme lỗi** bằng `qmlformat` Qt6, hiển thị cảnh báo và chặn áp dụng.
- **Poster chống màn hình đen**: trích frame đầu video làm nền X root + poster trong theme.
- `Super + L` mở **màn hình đăng nhập SDDM** (`SwitchToGreeter`), giữ phiên cũ chạy nền.
- `Super + Shift + L` mở **màn hình khoá Serpantinum**.

## Yêu cầu

- Arch Linux / CachyOS (đã test), Hyprland, SDDM.
- `quickshell`, `qt6-declarative`, `python`, `ffmpeg`, `imagemagick`, `feh`.
- Tuỳ chọn: `matugen` (màu theme), `brightnessctl`, `playerctl`.

```bash
sudo pacman -S --needed quickshell hyprland sddm python ffmpeg imagemagick feh qt6-declarative matugen
```

## Cài đặt

```bash
git clone https://github.com/nguyendongho204/Serpantinum.git
cd Serpantinum
chmod +x install/install.sh
./install/install.sh
```

Hoặc cài trực tiếp:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/nguyendongho204/Serpantinum/main/install/install.sh)"
```

Trình cài đặt sẽ:

- Copy source vào `~/.local/share/serpantinum`.
- Tạo lệnh `serpantinum` trong `~/.local/bin`.
- Cài helper chọn theme SDDM.
- Thêm rule sudoers chỉ cho phép đổi/xoá theme SDDM.
- Cài poster Xsetup cho SDDM (giảm màn hình đen).

## Sau khi cài

Thêm vào cấu hình Hyprland:

```text
exec-once = serpantinumd start
```

Keybind gợi ý:

```text
Super + L        -> sddm-switch-to-greeter
Super + Shift+L  -> serpantinum lock
```

Đăng xuất/khởi động lại, sau đó mở:

**Cài đặt → Màn hình → Màn hình đăng nhập**

## Theme SDDM

Repo **không kèm theme SDDM**. Cài theme vào `/usr/share/sddm/themes/`, ví dụ bộ Qylock, rồi mở tab Màn hình đăng nhập để chọn.

- Theme Qylock dạng symlink: xoá trong UI chỉ xoá liên kết, không xoá bộ gốc.
- Theme video có thể đứng 2–3 giây khi greeter giải mã frame đầu; dùng theme ảnh tĩnh nếu muốn mở tức thì.

## Ghi chú

- `Super + L` dùng `SwitchToGreeter`; phiên cũ vẫn chạy nền, nhưng đăng nhập lại có thể mở phiên mới. Muốn quay lại đúng tab cũ, dùng `Super + Shift + L`.
- Không dùng được Face ID kiểu Apple; máy không có IR camera.
- Vân tay chỉ hoạt động nếu có phần cứng và `fprintd`.
- Cập nhật từ upstream có thể ghi đè các tuỳ biến này.

## Giấy phép

AGPL-3.0. Xem [LICENSE](LICENSE). Dự án gốc: <https://github.com/ilyamiro/serpantinum>.
