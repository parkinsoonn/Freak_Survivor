-- Wave banner'ı arka planı (180x45; yazı Godot'ta Label). "intro": kurdele üstünde parlama şeridi geçer, son kare temiz.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script wave_banner.lua

local OUT = app.params["out"]
dofile(OUT .. "/ui_common.lua")

local W, H = 180, 45
local NOTCH = 8 -- uçlardaki V kesiğin derinliği

local function inside(x, y)
  local top, bottom = 3, H - 4
  if y < top or y > bottom then return false end
  -- Sol ve sağ uçta V kesik
  local mid = (top + bottom) / 2
  local cut = NOTCH * (1 - math.abs(y - mid) / (mid - top))
  return x >= cut and x <= W - 1 - cut
end

local function banner(shine_x)
  local g = UI.grid(W, H)
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      if inside(x, y) then g[y][x] = "G" end
    end
  end
  -- Altın şeritler ve kabartma
  for x = 0, W - 1 do
    for _, row in ipairs({ { 6, "o" }, { 7, "y" }, { H - 8, "O" }, { H - 7, "o" }, { 4, "g" }, { H - 5, "D" } }) do
      if inside(x, row[1]) then g[row[1]][x] = row[2] end
    end
  end
  -- Çapraz parlama şeridi (6 piksel)
  if shine_x then
    for y = 0, H - 1 do
      for x = 0, W - 1 do
        local d = x - shine_x + y * 0.5
        if inside(x, y) and d >= 0 and d < 6 then g[y][x] = (d < 2) and "c" or "g" end
      end
    end
  end
  return UI.outline(g, "k")
end

local frames = {}
for _, sx in ipairs({ -10, 30, 70, 110, 150, 190 }) do frames[#frames + 1] = banner(sx) end
frames[#frames + 1] = banner(nil)

UI.export(OUT, "wave_banner", W, H, { { name = "intro", frames = frames, ms = 60 } }, { 1 })
