local mainMod = _G.mainMod or "SUPER"
local terminal = _G.terminal or "kitty"
local home = os.getenv("HOME") or ""

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- nut phu chuot: 1 (276) = Ctrl+C, 2 (275) = Ctrl+V
hl.bind("mouse:276", hl.dsp.exec_cmd(home .. "/.local/bin/mousekey.py copy"), { locked = true })
hl.bind("mouse:275", hl.dsp.exec_cmd(home .. "/.local/bin/mousekey.py paste"), { locked = true })

hl.bind(mainMod .. " + SHIFT + Left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })

hl.bind(mainMod .. " + CTRL + Left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + Right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + CTRL + Up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + Down", hl.dsp.window.move({ direction = "d" }))

hl.bind(mainMod .. " + Left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + Up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + Down", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("serpantinum brightness lower"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("serpantinum brightness raise"), { locked = true })

hl.bind("Print", hl.dsp.exec_cmd("serpantinum screenshot"), { locked = true })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("serpantinum screenshot --edit"), { locked = true })
hl.bind("SUPER + Print", hl.dsp.exec_cmd("serpantinum screenshot --full"), { locked = true })
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd("serpantinum screenshot --full --edit"), { locked = true })

hl.bind("XF86PowerOff", hl.dsp.exec_cmd("serpantinum lock"), { locked = true })

-- Nắp máy: ghi log chẩn đoán + bật lại màn hình khi mở nắp
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("sh -c 'echo \"$(date +%s) closed\" >> '" .. home .. "/.cache/lid-events.log'"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("sh -c 'echo \"$(date +%s) opened\" >> '" .. home .. "/.cache/lid-events.log; hyprctl dispatch dpms on'"), { locked = true })
-- Super+L: mở màn hình đăng nhập SDDM (giữ phiên chạy nền)
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("sddm-switch-to-greeter"), { repeating = true, locked = true })
-- Super+Shift+L: màn hình khoá Serpantinum (giữ nguyên phiên)
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("serpantinum lock"), { repeating = true, locked = true })

hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("serpantinum volume mic-toggle"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("serpantinum volume mute-toggle"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("serpantinum volume lower"), { repeating = true, locked = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("serpantinum volume raise"), { repeating = true, locked = true })

hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))

hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("serpantinum reload"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("serpantinum msg toggle clipboard"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("serpantinum msg toggle launcher"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("serpantinum msg toggle music"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("serpantinum msg toggle system"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("serpantinum msg toggle wallpaper"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("serpantinum msg toggle calendar"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("serpantinum msg toggle network"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("serpantinum msg toggle volume"))
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("serpantinum msg toggle guide"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("serpantinum msg toggle autohide"))
-- Super+G / Super+P: để trống trong bản chia sẻ (công cụ cá nhân).

for i = 1, 10 do
  local ws = tostring(i)
  local key = tostring(i % 10)
  hl.bind(mainMod .. " + " .. key, hl.dsp.exec_cmd("serpantinum msg workspace " .. ws))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.exec_cmd("serpantinum msg workspace " .. ws .. " move"))
end

-- Alt+Tab kieu Windows 11 nhung gom theo workspace ("trang"):
-- moi workspace = 1 o, ben trong la luoi thumbnail cac cua so cua workspace do.
-- Giu Alt de chon, tha Alt de chuyen workspace.
local SWITCHER_RUN_DIR = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/serpantinum"
local SWITCHER_STATE = SWITCHER_RUN_DIR .. "/workspace-switcher.state"

local switcher = { active = false, spaces = {}, index = 1 }
local switcher_esc_bind = nil

-- MRU workspace: moi nhat dung dau.
local ws_mru = {}

local function ws_mru_touch(id)
  if not id or id < 1 then return end
  for i, v in ipairs(ws_mru) do
    if v == id then
      table.remove(ws_mru, i)
      break
    end
  end
  table.insert(ws_mru, 1, id)
end

local function ws_mru_rank(id)
  for i, v in ipairs(ws_mru) do
    if v == id then return i end
  end
  return 99999
end

hl.on("workspace.active", function(ws)
  local id = ws and ws.id
  if id and id >= 1 then ws_mru_touch(id) end
end)

local function switcher_json_str(s)
  s = tostring(s or "")
  s = s:gsub("\\", "\\\\"):gsub('"', '\\"')
  return '"' .. s .. '"'
end

local function switcher_write()
  local f = io.open(SWITCHER_STATE, "w")
  if not f then return end
  local sparts = {}
  for _, sp in ipairs(switcher.spaces) do
    local wparts = {}
    for _, w in ipairs(sp.wins) do
      wparts[#wparts + 1] = '{"address":' .. switcher_json_str(w.address)
        .. ',"class":' .. switcher_json_str(w.class)
        .. ',"title":' .. switcher_json_str(w.title)
        .. ',"x":' .. tostring(w.x or 0) .. ',"y":' .. tostring(w.y or 0)
        .. ',"w":' .. tostring(w.w or 0) .. ',"h":' .. tostring(w.h or 0)
        .. ',"floating":' .. tostring(w.floating or "0") .. '}'
    end
    sparts[#sparts + 1] = '{"id":' .. tostring(sp.id) .. ',"count":' .. tostring(sp.count)
      .. ',"wins":[' .. table.concat(wparts, ",") .. ']}'
  end
  f:write('{"active":' .. tostring(switcher.active) .. ',"sel":' .. tostring(switcher.index)
    .. ',"cur":' .. tostring(switcher.cur or 0)
    .. ',"spaces":[' .. table.concat(sparts, ",") .. ']}')
  f:close()
end

local function switcher_drop_esc()
  if switcher_esc_bind then
    pcall(function() switcher_esc_bind:remove() end)
    switcher_esc_bind = nil
  end
end

function serpantinum_cancel_switch()
  if not switcher.active then return end
  switcher.active = false
  switcher_write()
  switcher_drop_esc()
end

function serpantinum_commit_switch()
  if not switcher.active then return end
  local target = switcher.spaces[switcher.index]
  switcher.active = false
  switcher_write()
  switcher_drop_esc()
  if target then
    hl.exec_cmd("serpantinum msg workspace " .. target.id)
  end
end

-- Gom cua so theo workspace tren monitor dang focus. Moi workspace giu toi da 4 cua so
-- (moi nhat truoc) de ve luoi thumbnail.
local function switcher_collect(monName)
  local byWs = {}
  for _, w in ipairs(hl.get_windows()) do
    local ws = w.workspace
    local wsid = ws and ws.id
    if ws and wsid and wsid >= 1 and w.mapped then
      local wmon = w.monitor and w.monitor.name
      if not monName or wmon == monName then
        local fid = w.focus_history_id
        if not fid or fid < 0 then fid = 999999 end
        local g = byWs[wsid]
        if not g then
          g = { id = wsid, wins = {} }
          byWs[wsid] = g
        end
        local at = w.at
        local sz = w.size
        g.wins[#g.wins + 1] = {
          address = w.address or "",
          class = w.class or "",
          title = w.title or "",
          fid = fid,
          x = at and at.x or 0,
          y = at and at.y or 0,
          w = sz and sz.x or 0,
          h = sz and sz.y or 0,
          floating = w.floating and "1" or "0",
        }
      end
    end
  end

  local ids = {}
  for id, _ in pairs(byWs) do ids[#ids + 1] = id end
  table.sort(ids, function(a, b)
    local ra, rb = ws_mru_rank(a), ws_mru_rank(b)
    if ra ~= rb then return ra < rb end
    return a < b
  end)

  local out = {}
  for _, id in ipairs(ids) do
    local g = byWs[id]
    table.sort(g.wins, function(a, b)
      if a.floating ~= b.floating then return a.floating < b.floating end
      return a.fid < b.fid
    end)
    local wins = {}
    for i = 1, math.min(#g.wins, 8) do wins[i] = g.wins[i] end
    out[#out + 1] = { id = id, count = #g.wins, wins = wins }
  end
  return out
end

function serpantinum_cycle_workspace(step)
  local cur = hl.get_active_workspace()
  if not cur then return end

  if cur.special or cur.id < 1 then
    cur = hl.get_last_workspace()
    if not cur or cur.special or cur.id < 1 then return end
  end

  if not switcher.active then
    ws_mru_touch(cur.id)
    local spaces = switcher_collect(cur.monitor and cur.monitor.name)
    if #spaces == 0 then return end

    local pos
    for i, sp in ipairs(spaces) do
      if sp.id == cur.id then pos = i break end
    end
    if not pos then
      -- Workspace hien tai trong: bat dau tu dau/cuoi danh sach MRU
      pos = (step > 0) and 0 or (#spaces + 1)
    end

    switcher.spaces = spaces
    switcher.cur = cur.id
    switcher.index = ((pos - 1 + step) % #spaces) + 1
    switcher.active = true
    switcher_write()

    switcher_drop_esc()
    switcher_esc_bind = hl.bind("Escape", function() serpantinum_cancel_switch() end, { ignore_mods = true })
  else
    local n = #switcher.spaces
    if n == 0 then return end
    switcher.index = ((switcher.index - 1 + step) % n) + 1
    switcher_write()
  end
end

-- Tha phim Alt (trai = 64, phai = 108) thi chot workspace dang chon.
hl.on("input.keyboard.key", function(keycode, timeMs, state)
  if not switcher.active then return end
  if state ~= 0 then return end
  if keycode == 64 or keycode == 108 then
    serpantinum_commit_switch()
  end
end)

os.execute("mkdir -p '" .. SWITCHER_RUN_DIR .. "'")
switcher_write()

hl.bind("ALT + Tab", function() serpantinum_cycle_workspace(1) end, { description = "Trang ke tiep (Alt+Tab)" })
hl.bind("ALT + SHIFT + ISO_Left_Tab", function() serpantinum_cycle_workspace(-1) end, { description = "Trang truoc (Alt+Shift+Tab)" })
hl.bind("ALT + SHIFT + Tab", function() serpantinum_cycle_workspace(-1) end, { description = "Trang truoc (du phong)" })

-- Layout luoi 2x2 (xem config/layouts.lua): Super+Alt+G xep luoi, Super+Alt+D ve dwindle
hl.bind(mainMod .. " + ALT + G", hl.dsp.layout("grid"))
hl.bind(mainMod .. " + ALT + V", hl.dsp.layout("stack"))
hl.bind(mainMod .. " + ALT + D", hl.dsp.layout("dwindle"))
