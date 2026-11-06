-- Nişancı düşman (24x24, 4 karelik yürüme): mor kabuklu tükürücü, ağız tüpü alta (oyuncuya) bakar.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script nisanci.lua

local OUT = app.params["out"]
dofile(OUT .. "/../ui/ui_common.lua")

-- Kabuğun gölge tonu (ortak palette koyu mor yok)
UI.P.v = "62289a"

local S = 24
local GLOW = { "R", "r", "y", "r" }

local frames = {}
for f = 1, 4 do
  local g = UI.grid(S, S)

  -- Bacaklar: sol ve sağ çiftler karşılıklı adım atar
  local step = (f % 2 == 0) and 1 or -1
  for _, side in ipairs({ { 3, 1 }, { 20, -1 } }) do
    UI.rect(g, side[1], 7 + step * side[2], 1, 3, "N")
    UI.rect(g, side[1], 13 - step * side[2], 1, 3, "N")
  end

  -- Kabuk: sol üst açık, sağ alt koyu, sırtta benekler
  for y = 0, S - 1 do
    for x = 0, S - 1 do
      local dx, dy = x + 0.5 - 12, y + 0.5 - 11
      if dx * dx + dy * dy <= 64 then
        g[y][x] = (dx + dy < -7) and "p" or ((dx + dy > 6) and "v" or "P")
      end
    end
  end
  for _, p in ipairs({ { 9, 6 }, { 14, 7 }, { 11, 9 } }) do UI.set(g, p[1], p[2], "p") end

  -- Gözler ve ağız tüpü; tüpün içi her karede farklı parlar
  UI.set(g, 8, 15, "y")
  UI.set(g, 15, 15, "y")
  UI.rect(g, 10, 17, 4, 4, "S")
  UI.rect(g, 11, 18, 2, 3, "X")
  UI.rect(g, 11, 20, 2, 1, GLOW[f])
  UI.rect(g, 9, 21, 6, 1, "S")

  frames[#frames + 1] = UI.outline(g, "k")
end

UI.export(OUT, "nisanci", S, S, { { name = "walk", frames = frames, ms = 150 } }, { 1 })
