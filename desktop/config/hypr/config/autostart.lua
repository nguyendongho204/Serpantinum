local home = os.getenv("HOME") or ""

hl.on("hyprland.start", function()
  -- Service libinput-gestures WantedBy=graphical-session.target, nhưng session
  -- này chạy qua SDDM -> start-hyprland (không qua uwsm) nên target đó không
  -- bao giờ kích hoạt. Phải start trực tiếp.
  hl.exec_cmd(home .. "/.config/hypr/autostart-start-gestures.sh")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
  hl.exec_cmd("systemctl --user enable --now easyeffects")
  hl.exec_cmd("serpantinumd start")
  hl.exec_cmd("fcitx5 -d --replace")
end)
