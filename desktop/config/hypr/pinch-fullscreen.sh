#!/bin/sh
# Vuốt chụm 2 tay (pinch) 3 ngón trên touchpad:
#   out = tách ngón ra   -> 2 cửa sổ đang chia đôi -> phóng toàn màn hình (1)
#   in  = chụm ngón vào -> đang toàn màn hình -> trả về chia đôi như cũ
#
# Chạy từ libinput-gestures (xem ~/.config/libinput-gestures.conf).
# Dispatcher fullscreen của Hyprland là TOGGLE nên phải kiểm tra trạng thái
# trước, nếu không pinch 2 lần liên tiếp sẽ fullscreen rồi thoát ngay.

MODE="$1"
STATE=$(hyprctl activewindow -j 2>/dev/null | jq -r '.fullscreen // 0')

# Không có cửa sổ đang hoạt động thì thôi
[ -n "$STATE" ] && [ "$STATE" != "null" ] || exit 0

case "$MODE" in
    out) [ "$STATE" = "0" ] || exit 0 ;;  # đã fullscreen rồi -> không làm gì
    in)  [ "$STATE" != "0" ] || exit 0 ;; # chưa fullscreen   -> không làm gì
    *)   exit 1 ;;
esac

hyprctl eval 'hl.dispatch(hl.dsp.window.fullscreen("fullscreen"))' >/dev/null 2>&1
