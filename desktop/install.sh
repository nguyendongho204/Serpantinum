#!/usr/bin/env bash
# Cài giao diện desktop Serpantinum (dotfiles + theme SDDM).
# Chạy: ./desktop/install.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$ROOT/.." && pwd)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d-%H%M%S)"
THEME_NAME="qylock-winter"
THEME_SRC="$ROOT/sddm/themes/$THEME_NAME"
THEME_DEST="/usr/share/sddm/themes/$THEME_NAME"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
LOCK_VIDEO="$HOME/Videos/lock-galaxy-eye-2k24.mp4"

INSTALL_APP=1
INSTALL_SDDM=1
INSTALL_SYSTEMD=1
KEEP_SETTINGS=0

for arg in "$@"; do
    case "$arg" in
        --no-app) INSTALL_APP=0 ;;
        --no-sddm) INSTALL_SDDM=0 ;;
        --no-systemd) INSTALL_SYSTEMD=0 ;;
        --keep-settings) KEEP_SETTINGS=1 ;;
        -h|--help)
            cat <<'HELP'
Dùng: ./desktop/install.sh [tuỳ chọn]

  --no-app         Không cài/cập nhật ứng dụng Serpantinum
  --no-sddm        Không cài theme và cấu hình SDDM (không cần sudo)
  --no-systemd     Không cài systemd user service
  --keep-settings  Giữ nguyên ~/.config/serpantinum/settings.json
  -h, --help       Hiện trợ giúp
HELP
            exit 0
            ;;
        *) echo "Tuỳ chọn không hợp lệ: $arg" >&2; exit 1 ;;
    esac
done

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

[ -d "$ROOT/config" ] || die "Không tìm thấy desktop/config"

# ---------- 1. Ứng dụng Serpantinum ----------
if [ "$INSTALL_APP" -eq 1 ]; then
    if command -v serpantinum >/dev/null 2>&1; then
        say "Đã có lệnh serpantinum — bỏ qua cài ứng dụng"
    elif [ -x "$REPO_ROOT/install/install.sh" ]; then
        say "Cài ứng dụng Serpantinum"
        bash "$REPO_ROOT/install/install.sh"
    else
        warn "Không thấy install/install.sh. Hãy cài ứng dụng Serpantinum trước."
    fi
fi

# ---------- 2. Dotfiles người dùng ----------
backup() {
    local p="$1"
    if [ -e "$p" ]; then
        cp -a "$p" "$p.bak-$STAMP"
        return 0
    fi
    return 1
}

install_tree() {
    local src="$1" dest="$2" label="$3"
    local had=0
    if backup "$dest"; then had=1; fi
    mkdir -p "$dest"
    cp -a "$src/." "$dest/"
    if [ "$had" -eq 1 ]; then
        say "$label → $dest (sao lưu: $dest.bak-$STAMP)"
    else
        say "$label → $dest"
    fi
}

install_file() {
    local src="$1" dest="$2" mode="${3:-644}"
    mkdir -p "$(dirname "$dest")"
    backup "$dest" >/dev/null || true
    install -m "$mode" "$src" "$dest"
}

say "Cài cấu hình vào $XDG_CONFIG_HOME"
for d in hypr kitty alacritty btop cava fcitx5 easyeffects gtk-3.0 gtk-4.0 qt6ct xsettingsd fastfetch fontconfig fish systemd; do
    [ -d "$ROOT/config/$d" ] || continue
    install_tree "$ROOT/config/$d" "$XDG_CONFIG_HOME/$d" "config/$d"
done

# File đơn lẻ
install_file "$ROOT/config/libinput-gestures.conf" "$XDG_CONFIG_HOME/libinput-gestures.conf"

# fish/config.fish nằm trong thư mục fish ở trên.

# ---------- 3. Icon, wallpaper, video khoá ----------
if [ -d "$ROOT/icons" ]; then
    install_tree "$ROOT/icons" "$HOME/.icons" "icons"
fi

mkdir -p "$WALLPAPER_DIR" "$HOME/Videos" "$HOME/.local/bin"
for wp in "$ROOT"/wallpapers/*.jpg; do
    [ -e "$wp" ] || continue
    install_file "$wp" "$WALLPAPER_DIR/$(basename "$wp")"
done
if [ -f "$ROOT/wallpapers/lock-galaxy-eye-2k24.mp4" ]; then
    install_file "$ROOT/wallpapers/lock-galaxy-eye-2k24.mp4" "$LOCK_VIDEO"
fi

# ---------- 4. Helper chuột phụ ----------
if [ -f "$ROOT/bin/mousekey.py" ]; then
    install_file "$ROOT/bin/mousekey.py" "$HOME/.local/bin/mousekey.py" 755
fi

# ---------- 5. Settings.json ----------
SER_SETTINGS="$XDG_CONFIG_HOME/serpantinum/settings.json"
mkdir -p "$(dirname "$SER_SETTINGS")"
if [ "$KEEP_SETTINGS" -eq 1 ] && [ -f "$SER_SETTINGS" ]; then
    say "Giữ nguyên settings.json hiện có"
else
    install_file "$ROOT/config/serpantinum/settings.json" "$SER_SETTINGS"
fi

# Thay placeholder __HOME__ bằng đường dẫn thật.
if [ -f "$SER_SETTINGS" ]; then
    sed -i "s|__HOME__|$HOME|g" "$SER_SETTINGS"
fi
[ -f "$XDG_CONFIG_HOME/qt6ct/qt6ct.conf" ] && sed -i "s|__HOME__|$HOME|g" "$XDG_CONFIG_HOME/qt6ct/qt6ct.conf"

# ---------- 6. Quyền thực thi ----------
chmod +x "$XDG_CONFIG_HOME"/hypr/*.sh 2>/dev/null || true
chmod +x "$XDG_CONFIG_HOME"/hypr/*.py 2>/dev/null || true
chmod +x "$HOME/.local/bin/mousekey.py" 2>/dev/null || true

# ---------- 7. systemd user ----------
if [ "$INSTALL_SYSTEMD" -eq 1 ] && command -v systemctl >/dev/null 2>&1; then
    say "Bật systemd user service"
    systemctl --user daemon-reload >/dev/null 2>&1 || true
    systemctl --user enable --now fcitx5.service >/dev/null 2>&1 || warn "Không bật được fcitx5.service"
    systemctl --user enable --now touchpad-volume.service >/dev/null 2>&1 || warn "Không bật được touchpad-volume.service"
    systemctl --user enable libinput-gestures.service >/dev/null 2>&1 || warn "Không bật được libinput-gestures.service"
fi

# ---------- 8. SDDM ----------
if [ "$INSTALL_SDDM" -eq 1 ]; then
    if ! command -v sddm >/dev/null 2>&1; then
        warn "Không thấy SDDM — bỏ qua theme đăng nhập."
    else
        SUDO=""
        if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi

        say "Cài theme SDDM $THEME_NAME"
        $SUDO install -d /usr/share/sddm/themes /etc/sddm.conf.d /etc/sddm/scripts
        if $SUDO test -e "$THEME_DEST"; then
            $SUDO mv "$THEME_DEST" "$THEME_DEST.bak-$STAMP"
            say "Đã sao lưu theme cũ: $THEME_DEST.bak-$STAMP"
        fi
        $SUDO cp -a "$THEME_SRC" "$THEME_DEST"

        if [ -f "$ROOT/sddm/.sddm-poster.jpg" ]; then
            $SUDO install -m644 "$ROOT/sddm/.sddm-poster.jpg" /usr/share/sddm/themes/.sddm-poster.jpg
        fi
        for f in theme.conf 10-material-you.conf 20-xsetup.conf; do
            if [ -f "/etc/sddm.conf.d/$f" ]; then
                $SUDO cp -a "/etc/sddm.conf.d/$f" "/etc/sddm.conf.d/$f.bak-$STAMP"
            fi
            $SUDO install -m644 "$ROOT/sddm/$f" "/etc/sddm.conf.d/$f"
        done
        if [ -f /etc/sddm/scripts/Xsetup ]; then
            $SUDO cp -a /etc/sddm/scripts/Xsetup "/etc/sddm/scripts/Xsetup.bak-$STAMP"
        fi
        $SUDO install -m755 "$ROOT/sddm/Xsetup" /etc/sddm/scripts/Xsetup
        if [ -d /usr/share/sddm/scripts ]; then
            if [ -f /usr/share/sddm/scripts/Xsetup ]; then
                $SUDO cp -a /usr/share/sddm/scripts/Xsetup "/usr/share/sddm/scripts/Xsetup.bak-$STAMP"
            fi
            $SUDO install -m755 "$ROOT/sddm/Xsetup" /usr/share/sddm/scripts/Xsetup
        fi
    fi
fi

# ---------- 9. Kiểm tra phụ thuộc ----------
say "Kiểm tra phụ thuộc"
missing=()
for c in hyprctl quickshell python3 ffmpeg feh grim slurp cliphist fcitx5 kitty; do
    command -v "$c" >/dev/null 2>&1 || missing+=("$c")
done
if [ "${#missing[@]}" -gt 0 ]; then
    warn "Thiếu lệnh: ${missing[*]}"
    warn "Xem desktop/packages/README.md để cài gói cần thiết."
fi

# ---------- 10. Kết thúc ----------
cat <<EOF

$(printf '\033[1;32mHoàn tất.\033[0m')

Bước tiếp theo:
  1. Đăng xuất, chọn phiên "Hyprland" ở SDDM rồi đăng nhập lại.
  2. Mở Cài đặt Serpantinum → Màn hình → Màn hình đăng nhập để chọn theme SDDM.
  3. Nếu bố cục màn hình sai: Cài đặt → Màn hình, rồi áp dụng.

Phím tắt:
  Super + L        mở màn hình đăng nhập SDDM
  Super + Shift+L  khoá màn hình Serpantinum
  Super + Return   mở kitty
  Super + D        launcher

Cấu hình cũ được sao lưu cạnh file gốc với hậu tố .bak-$STAMP.
EOF
