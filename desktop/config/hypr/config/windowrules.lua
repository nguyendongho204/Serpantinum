-- Window rules cho Firefox Picture-in-Picture (xem YouTube trong mini-player)
--
-- Cách bật PiP trong Firefox:
--   1. Bấm vào video YouTube để nó phát
--   2. Đưa chuột lên video -> hiện nút PiP (hình chữ nhật nhỏ), bấm vào
--      hoặc: click PHẢI 2 lần lên video -> "Picture-in-Picture"
--
-- Cửa sổ PiP có class "firefox". Title phụ thuộc ngôn ngữ của Firefox:
--   en-US -> "Picture-in-Picture"
--   vi-VN -> "Hình trong hình"
-- nên phải khớp cả hai.
hl.window_rule({
  name = "pip-firefox",
  match = {
    class = "^(firefox|google-chrome|microsoft-edge)$",
    title = "^(Picture-in-Picture|Hình trong hình)$",
  },

  float    = true,  -- không xếp chồng theo layout dwindle
  pin      = true,  -- dính mọi workspace: chuyển tab/WS vẫn thấy
  opacity  = "1.0 1.0",
  opaque   = true,
  rounding = 10,
  size     = "480 270",
  move     = "100%-500 100%-300",  -- góc dưới bên phải
})

-- Xem trước theme SDDM: cửa sổ nổi, căn giữa, kích thước 16:10
-- (greeter chạy trong Xwayland lồng nhau để không chiếm toàn màn hình)
hl.window_rule({
  name = "sddm-theme-preview",
  match = { class = "^sddm-greeter-qt6$" },

  fullscreen  = true,
  rounding    = 0,
  border_size = 0,
})

-- Kitty: khung kinh long (nen trong suot + blur do compositor lo, vien sang mong)
hl.window_rule({
  name = "kitty-glass",
  match = { class = "^kitty$" },
  rounding    = 16,
  border_size = 1,
})

-- Video players & Zoom: luôn sắc nét 100%, không bị mờ xuyên thấu
hl.window_rule({
  name = "media-players-opaque",
  match = { class = "^(mpv|vlc|zoom)$" },
  opacity     = "1.0 1.0",
  opaque      = true,
})

-- Tat blur cho MOI cua so app...
hl.window_rule({
  name = "no-blur-apps",
  match = { class = ".*" },
  no_blur = true,
})

-- ...nhưng bật lại blur cho kitty (terminal kính).
-- Rule đặt SAU sẽ ghi đè hiệu lực no_blur của rule trước.
hl.window_rule({
  name = "blur-glass-apps",
  match = { class = "^kitty$" },
  no_blur = false,
})

