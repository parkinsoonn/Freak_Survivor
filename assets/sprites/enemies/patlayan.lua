-- Patlayan düşman (24x24, 4 karelik yürüme): kırmızı bomba gövdeli yaratık, fitil üstte, yüz alta (oyuncuya) bakar.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script patlayan.lua

local OUT = app.params["out"]
dofile(OUT .. "/../ui/ui_common.lua")

local S = 24
local SPARK = { "y", "w", "o", "w" }

local frames = {}
for f = 1, 4 do
  local g = UI.grid(S, S)

  -- Ayaklar sırayla öne çıkar
  local lift = (f % 2 == 0) and 1 or 0
  UI.rect(g, 7, 20 + lift, 3, 2, "k")
  UI.rect(g, 14, 21 - lift, 3, 2, "k")

  -- Gövde: sol üst parlama, sağ alt gölge
  for y = 0, S - 1 do
    for x = 0, S - 1 do
      local dx, dy = x + 0.5 - 12, y + 0.5 - 13
      if dx * dx + dy * dy <= 64 then
        g[y][x] = (dx > 2 and dy > 2) and "R" or "r"
      end
    end
  end
  UI.rect(g, 8, 8, 2, 1, "w")
  UI.set(g, 8, 9, "w")

  -- Fitil ve kıvılcım
  UI.rect(g, 12, 3, 1, 3, "N")
  UI.set(g, 13, 2, "N")
  UI.set(g, 14, 1, SPARK[f])
  if f % 2 == 1 then
    UI.set(g, 15, 1, "y")
    UI.set(g, 14, 0, "y")
  end

  -- Kızgın yüz: çatık kaşlar, gözler, dişli ağız
  UI.set(g, 8, 13, "k")
  UI.set(g, 9, 14, "k")
  UI.set(g, 15, 13, "k")
  UI.set(g, 14, 14, "k")
  UI.set(g, 9, 15, "y")
  UI.set(g, 14, 15, "y")
  UI.rect(g, 9, 17, 6, 2, "k")
  for x = 9, 14, 2 do UI.set(g, x, 17, "w") end

  frames[#frames + 1] = UI.outline(g, "k")
end

UI.export(OUT, "patlayan", S, S, { { name = "walk", frames = frames, ms = 120 } }, { 1 })
