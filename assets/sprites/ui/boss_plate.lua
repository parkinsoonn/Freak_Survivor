-- Boss isim plakası (48x14, 9-slice; yatay pay 8, dikey pay 4 piksel = x4 sheet'te 32 / 16). Yazı Godot'ta Label (krem).
-- Uçlarda wave_banner gibi V kesik, koyu kırmızı gövde, altın şeritler.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script boss_plate.lua

local OUT = app.params["out"]
dofile(OUT .. "/ui_common.lua")

local W, H, NOTCH = 48, 14, 4

local function inside(x, y)
  local top, bottom = 1, H - 2
  if y < top or y > bottom then return false end
  local mid = (top + bottom) / 2
  local cut = NOTCH * (1 - math.abs(y - mid) / (mid - top))
  return x >= 1 + cut and x <= W - 2 - cut
end

local g = UI.grid(W, H)
for y = 0, H - 1 do
  for x = 0, W - 1 do
    if inside(x, y) then g[y][x] = "R" end
  end
end
for x = 0, W - 1 do
  for _, row in ipairs({ { 2, "o" }, { 3, "y" }, { H - 4, "O" }, { H - 3, "o" } }) do
    if inside(x, row[1]) then g[row[1]][x] = row[2] end
  end
end
UI.outline(g, "k")

UI.export(OUT, "boss_plate", W, H, { { name = "plate", frames = { g }, ms = 100 } }, { 1, 4 })
