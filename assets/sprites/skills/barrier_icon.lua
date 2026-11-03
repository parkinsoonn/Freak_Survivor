-- Bariyer skill ikonu (32x32, tek kare): dash/bomba ikonları gibi kare çerçeve, içinde mavi enerji kalkanı.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script barrier_icon.lua

local OUT = app.params["out"]
dofile(OUT .. "/../ui/ui_common.lua")

-- Çerçeve için lacivert tonlar: koyu çizgi, kenar şeridi, dolgu
UI.P.a, UI.P.e, UI.P.f = "16243a", "34507a", "27405f"

local S = 32

-- inset kadar içeri çekilmiş kalkan silüeti: düz üst, yuvarlak köşeler, alta doğru sivrilen uç
local function inside(x, y, inset)
  local top, tip, waist = 7 + inset, 26 - inset, 15
  if y < top or y > tip then return false end
  local hw = 9 - inset
  if y > waist then hw = hw * (tip - y) / (tip - waist) end
  if y < top + 2 then hw = hw - (top + 2 - y) end
  return math.abs(x + 0.5 - 16) <= hw
end

local shield = UI.grid(S, S)
for y = 0, S - 1 do
  for x = 0, S - 1 do
    if inside(x, y, 2) then
      shield[y][x] = x < 16 and "b" or "B"
    elseif inside(x, y, 0) then
      shield[y][x] = "w"
    end
  end
end

-- Sol üstte cam parlaması
for _, p in ipairs({ { 10, 10 }, { 11, 10 }, { 10, 11 }, { 10, 12 }, { 10, 13 } }) do
  UI.set(shield, p[1], p[2], "w")
end
UI.outline(shield, "k")

-- Çerçeve (atom_bomba.png düzeni): siyah kontur, koyu, kenar şeridi, koyu iç çizgi, dolgu
local g = UI.grid(S, S)
UI.rect(g, 0, 0, S, S, "f")
UI.frame(g, 0, 0, S, S, "k")
UI.frame(g, 1, 1, S - 2, S - 2, "a")
UI.frame(g, 2, 2, S - 4, S - 4, "e")
UI.frame(g, 3, 3, S - 6, S - 6, "a")
for y = 0, S - 1 do
  for x = 0, S - 1 do
    if shield[y][x] ~= "." then g[y][x] = shield[y][x] end
  end
end

UI.export(OUT, "barrier_icon", S, S, { { name = "icon", frames = { g }, ms = 100 } }, { 1 })
