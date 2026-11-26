#!/usr/bin/env bash
# Trình cài đặt Serpantinum (bản damournora)
set -euo pipefail

SOURCE_PATH="${BASH_SOURCE[0]:-}"
if [ -n "$SOURCE_PATH" ] && [ -f "$SOURCE_PATH" ]; then
    ROOT="$(cd "$(dirname "$(realpath "$SOURCE_PATH")")/.." && pwd)"
else
    ROOT=""
fi

# Khi chạy qua "curl | bash" hoặc file tạm, tải repo về cache.
if [ -z "$ROOT" ] || [ ! -d "$ROOT/src" ]; then
    command -v git >/dev/null 2>&1 || { echo "Cần git để tải Serpantinum." >&2; exit 1; }
    CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/serpantinum-installer"
    rm -rf "$CACHE"
    mkdir -p "$(dirname "$CACHE")"
    git clone --depth 1 https://github.com/nguyendongho204/Serpantinum.git "$CACHE"
    ROOT="$CACHE"
fi

SRC_DIR="$ROOT/src"
BIN_DIR="$ROOT/bin"
DEST="$HOME/.local/share/serpantinum"
LOCAL_BIN="$HOME/.local/bin"
STATE_DIR="$HOME/.local/state/serpantinum"

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }

[ -d "$SRC_DIR" ] || { echo "Không tìm thấy src/ trong $ROOT" >&2; exit 1; }

say "Kiểm tra phụ thuộc"
missing=()
for c in quickshell hyprctl python3 ffmpeg feh git; do
    command -v "$c" >/dev/null 2>&1 || missing+=("$c")
done
command -v convert >/dev/null 2>&1 || command -v magick >/dev/null 2>&1 || missing+=("imagemagick")
[ -x /usr/lib/qt6/bin/qmlformat ] || command -v qmlformat >/dev/null 2>&1 || missing+=("qt6-declarative")
command -v sddm >/dev/null 2>&1 || warn "Không thấy sddm — tab Màn hình đăng nhập sẽ không dùng được."
if [ "${#missing[@]}" -gt 0 ]; then
    warn "Thiếu: ${missing[*]}"
    warn "Trên Arch/CachyOS có thể cài:"
    echo "  sudo pacman -S --needed quickshell hyprland sddm python ffmpeg imagemagick feh qt6-declarative matugen"
fi

say "Cài Serpantinum vào $DEST"
if [ -d "$DEST" ]; then
    backup="$DEST.bak-$(date +%Y%m%d-%H%M%S)"
    mv "$DEST" "$backup"
    say "Đã sao lưu bản cũ: $backup"
fi
mkdir -p "$DEST"
cp -a "$SRC_DIR" "$DEST/src"
mkdir -p "$DEST/bin"
install -m755 "$BIN_DIR/serpantinum" "$DEST/bin/serpantinum"
install -m755 "$BIN_DIR/serpantinumd" "$DEST/bin/serpantinumd"
install -m644 "$ROOT/version.txt" "$DEST/version.txt"

mkdir -p "$LOCAL_BIN"
ln -sfn "$DEST/bin/serpantinum" "$LOCAL_BIN/serpantinum"

say "Cài helper chọn theme đăng nhập"
install -m755 "$ROOT/install/helpers/sddm-theme-list" "$LOCAL_BIN/sddm-theme-list"
install -m755 "$ROOT/install/helpers/sddm-theme-preview" "$LOCAL_BIN/sddm-theme-preview"
sudo install -m755 "$ROOT/install/helpers/sddm-theme-set" /usr/local/bin/sddm-theme-set
sudo install -m755 "$ROOT/install/helpers/sddm-theme-delete" /usr/local/bin/sddm-theme-delete
sudo install -m755 "$ROOT/install/helpers/sddm-switch-to-greeter" /usr/local/bin/sddm-switch-to-greeter

# Cho phép UI đổi/xóa theme SDDM mà không hỏi mật khẩu.
target_user="${SUDO_USER:-$USER}"
tmp_sudo="$(mktemp)"
printf '%s ALL=(root) NOPASSWD: /usr/local/bin/sddm-theme-set, /usr/local/bin/sddm-theme-delete\n' "$target_user" > "$tmp_sudo"
sudo install -m440 "$tmp_sudo" /etc/sudoers.d/serpantinum-sddm
rm -f "$tmp_sudo"
sudo visudo -cf /etc/sudoers.d/serpantinum-sddm >/dev/null
say "Đã cấu hình sudoers cho $target_user"

# Poster trước greeter (giảm màn hình đen) — chỉ khi có SDDM.
if [ -d /usr/share/sddm ]; then
    say "Cài poster Xsetup cho SDDM"
    sudo install -d /etc/sddm/scripts /etc/sddm.conf.d
    sudo install -m755 "$ROOT/install/sddm/Xsetup" /etc/sddm/scripts/Xsetup
    sudo install -m644 "$ROOT/install/sddm/20-xsetup.conf" /etc/sddm.conf.d/20-xsetup.conf
    if [ -f /usr/share/sddm/scripts/Xsetup ] && [ ! -f /usr/share/sddm/scripts/Xsetup.pre-serpantinum ]; then
        sudo cp -a /usr/share/sddm/scripts/Xsetup /usr/share/sddm/scripts/Xsetup.pre-serpantinum
    fi
    sudo install -m755 "$ROOT/install/sddm/Xsetup" /usr/share/sddm/scripts/Xsetup
fi

mkdir -p "$STATE_DIR"
ver="$(cat "$ROOT/version.txt" 2>/dev/null || echo 2.2.6)"
printf 'SERPANTINUM_VERSION=%s\n' "$ver" > "$STATE_DIR/version"

say "Hoàn tất"
echo
echo "Thêm vào cấu hình Hyprland:"
echo '  exec-once = serpantinumd start'
echo
echo "Keybind gợi ý:"
echo '  Super + L        -> sddm-switch-to-greeter   # màn hình đăng nhập SDDM'
echo '  Super + Shift+L  -> serpantinum lock         # màn hình khoá Serpantinum'
echo
echo "Đăng xuất/khởi động lại để dùng. Nếu dùng SDDM, hãy chọn theme trong:"
echo "  Cài đặt -> Màn hình -> Màn hình đăng nhập"
