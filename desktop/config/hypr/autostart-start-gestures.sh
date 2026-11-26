#!/bin/sh
# Đảm bảo libinput-gestures.service có Wayland env trước khi khởi động.
# Session này chạy qua SDDM -> start-hyprland (không qua uwsm) nên
# graphical-session.target không bao giờ kích hoạt, service WantedBy target đó
# sẽ không tự start. exec-once trong hyprland.conf gọi script này.

systemctl --user import-environment \
    WAYLAND_DISPLAY DISPLAY XDG_RUNTIME_DIR \
    XDG_CURRENT_DESKTOP XDG_SESSION_TYPE \
    HYPRLAND_INSTANCE_SIGNATURE 2>/dev/null

systemctl --user start --no-block libinput-gestures
