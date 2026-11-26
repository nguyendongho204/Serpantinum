# Serpantinum Desktop — toàn bộ giao diện

Bộ dotfiles để dựng lại **toàn bộ giao diện desktop** trong ảnh: Hyprland, thanh trạng thái/Serpantinum, terminal, font, màu, gesture touchpad, wallpaper và màn hình đăng nhập SDDM dạng video.

![Wallpaper](wallpapers/serpantinum-wallpaper.jpg)

> Đây là phần **giao diện hệ thống**, tách khỏi ứng dụng Serpantinum.
> Ứng dụng nằm ở thư mục gốc repo và được cài tự động bởi `desktop/install.sh`.

---

## Có gì trong này

| Thư mục | Nội dung |
| --- | --- |
| `config/hypr` | Hyprland 0.56+ (Lua config), keybind, layout, gesture, shader, monitor |
| `config/serpantinum` | Mẫu `settings.json`: thanh bar, theme, màu, khoá màn hình |
| `config/kitty`, `alacritty`, `fish` | Terminal, màu, prompt |
| `config/gtk-3.0`, `gtk-4.0`, `qt6ct`, `xsettingsd` | Theme GTK/Qt, icon, cursor |
| `config/btop`, `cava`, `fastfetch`, `easyeffects`, `fcitx5` | Công cụ đi kèm |
| `config/systemd/user` | Service fcitx5, touchpad-volume, libinput-gestures |
| `icons` | Cursor mặc định |
| `wallpapers` | Wallpaper 4K + video khoá màn hình |
| `sddm/themes/qylock-winter` | Theme đăng nhập SDDM (video) |
| `sddm/*.conf`, `sddm/Xsetup` | Cấu hình SDDM + poster chống màn hình đen |
| `packages` | Danh sách gói pacman/AUR |
| `bin/mousekey.py` | Phím phụ chuột: Ctrl+C / Ctrl+V |

---

## Yêu cầu

- **Arch Linux / CachyOS** (đã test). Distro khác cần tự đổi tên gói.
- **Hyprland ≥ 0.56** — bản này dùng `hyprland.lua` gốc của Hyprland, không dùng `hyprland.conf`.
- **SDDM** nếu muốn dùng theme đăng nhập video.
- **Quickshell** (`quickshell` trên AUR; CachyOS dùng `noctalia-qs`).
- Python 3, ffmpeg, imagemagick, feh, grim, slurp, cliphist, wl-clipboard.
- Kitty, fish, fcitx5, btop, cava, easyeffects, fastfetch.
- Font: `ttf-jetbrains-mono`, `ttf-iosevka-nerd`; cursor `bibata-cursor-theme`.

Cài gói:

```bash
cd Serpantinum
sudo pacman -S --needed $(grep -v '^#' desktop/packages/pacman.txt | tr '\n' ' ')
yay -S --needed $(grep -v '^#' desktop/packages/aur.txt | tr '\n' ' ')
```

> Trên CachyOS, `quickshell` có thể đã được cung cấp bởi `noctalia-qs`.
> Nếu dùng distro khác, hãy cài tương đương và bỏ qua tên gói pacman.

---

## Cài đặt

```bash
git clone https://github.com/nguyendongho204/Serpantinum.git
cd Serpantinum
./desktop/install.sh
```

Script sẽ:

1. Cài ứng dụng Serpantinum nếu chưa có (`install/install.sh`).
2. Sao lưu cấu hình cũ rồi copy dotfiles vào `~/.config`, `~/.icons`, `~/.local/bin`.
3. Copy wallpaper vào `~/Pictures/Wallpapers` và video khoá vào `~/Videos`.
4. Thay `__HOME__` trong `settings.json`/`qt6ct.conf` bằng đường dẫn thật.
5. Bật service systemd user (fcitx5, touchpad-volume, libinput-gestures).
6. Cài theme SDDM `qylock-winter`, poster và cấu hình `/etc/sddm.conf.d`.

Tuỳ chọn:

```bash
./desktop/install.sh --no-sddm        # không đụng vào SDDM, không cần sudo
./desktop/install.sh --no-app         # chỉ cài dotfiles
./desktop/install.sh --no-systemd     # không bật service user
./desktop/install.sh --keep-settings  # giữ settings.json hiện có
```

Cấu hình cũ được giữ tại `*.bak-YYYYMMDD-HHMMSS` cạnh file gốc.

### Sau khi cài

1. Đăng xuất.
2. Ở SDDM chọn phiên **Hyprland** rồi đăng nhập.
3. Mở **Cài đặt Serpantinum → Màn hình → Màn hình đăng nhập** để chọn theme.
4. Nếu bố cục màn hình sai: **Cài đặt → Màn hình**, chỉnh rồi áp dụng.

---

## Phím tắt chính

```text
Super + Return       kitty
Super + D            launcher
Super + L            mở màn hình đăng nhập SDDM (giữ phiên chạy nền)
Super + Shift + L    khoá màn hình Serpantinum (giữ nguyên phiên)
Super + Shift + Q    thoát cửa sổ
Super + 1..0         chuyển workspace
Super + Alt + Tab    chuyển workspace kiểu Windows 11
Alt + Tab            chuyển workspace theo MRU
Super + Alt + G/V/D  layout grid / stack / dwindle
Print                chụp màn hình
```

Xem đầy đủ trong `config/hypr/config/keybinds.lua`.

---

## Ghi chú quan trọng

- **Bố cục màn hình** trong bản gốc là laptop + màn hình ngoài. File `config/hypr/config/monitors.lua` để trống để Hyprland tự nhận; hãy chỉnh lại theo máy bạn.
- **Touchpad gesture** phụ thuộc `libinput-gestures` và phần cứng touchpad. Nếu không có touchpad, có thể bỏ qua.
- **Theme video** có thể đứng 2–3 giây lần đầu khi greeter giải mã frame; đây là hạn chế đã biết. Dùng theme ảnh nếu cần mở tức thì.
- **`Super + L`** dùng `SwitchToGreeter` của SDDM. Phiên cũ vẫn chạy nền, nhưng đăng nhập lại có thể mở phiên mới. Muốn quay lại đúng tab cũ, dùng `Super + Shift + L`.
- **Không có Face ID / vân tay** trong bộ này. Vân tay chỉ hoạt động nếu máy có phần cứng và `fprintd`.
- **Không kèm dữ liệu cá nhân**: không có trình duyệt profile, SSH key, API key, chatbot, wayvnc, OpenCode hay lịch sử chat.
- **Không tự cài theme SDDM khác**. Chỉ có `qylock-winter`; theme khác cài vào `/usr/share/sddm/themes` rồi chọn trong tab Màn hình đăng nhập.

---

## Gỡ / khôi phục

Mỗi lần cài đều tạo bản sao lưu:

```bash
ls ~/.config/hypr.bak-* ~/.config/serpantinum.bak-* 2>/dev/null
ls /usr/share/sddm/themes/qylock-winter.bak-* 2>/dev/null
```

Khôi phục bằng cách đổi tên thư mục `.bak-...` về tên gốc. Gỡ ứng dụng: xoá `~/.local/share/serpantinum` và symlink `~/.local/bin/serpantinum`.

---

## Ghi công / giấy phép

- **Serpantinum** — ý tưởng và mã nguồn gốc bởi [ilyamiro](https://github.com/ilyamiro/serpantinum), giấy phép **AGPL-3.0**.
- **Qylock Winter** — theme SDDM bởi **Darkkal44**, giấy phép **GPL-3.0** (xem `sddm/themes/qylock-winter/LICENSE.qylock`).
- **Wallpaper** — ảnh sưu tầm trên Pinterest, không rõ tác giả/giấy phép. Nếu bạn là tác giả và muốn gỡ, hãy mở issue.
- Phần tuỳ biến, đóng gói và bảo trì bởi **damournora**.

Mã nguồn trong repo: **AGPL-3.0** (xem `LICENSE` ở thư mục gốc).
