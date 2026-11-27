-- Dash ve nuke skill ikonları (32x32): barrier_icon ile aynı lacivert çerçeve, içte yeni çizim. Kareler: dash, nuke.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script skill_icons.lua

local OUT = app.params["out"]
dofile(OUT .. "/ui_common.lua")

UI.P.a, UI.P.e, UI.P.f = "16243a", "34507a", "27405f" -- barrier_icon çerçeve tonları

local S = 32

local function framed(art)
  local g = UI.grid(S, S)
  UI.rect(g, 0, 0, S, S, "f")
  UI.frame(g, 0, 0, S, S, "k")
  UI.frame(g, 1, 1, S - 2, S - 2, "a")
  UI.frame(g, 2, 2, S - 4, S - 4, "e")
  UI.frame(g, 3, 3, S - 6, S - 6, "a")
  for y = 0, S - 1 do
    for x = 0, S - 1 do
      if art[y][x] ~= "." then g[y][x] = art[y][x] end
    end
  end
  return g
end

-- Dash: üç ok başı (arkadan öne koyu -> açık) ve hız çizgileri
local dash = UI.grid(S, S)
for _, ch in ipairs({ { 7, "O" }, { 12, "o" }, { 17, "y" } }) do
  local x0, c = ch[1], ch[2]
  for t = 0, 5 do
    for k = 0, 2 do
      UI.set(dash, x0 + t + k, 10 + t, c)
      UI.set(dash, x0 + t + k, 21 - t, c)
    end
  end
end
for t = 0, 5 do UI.set(dash, 19 + t, 10 + t, "c") end -- ön ok başında parlama
UI.outline(dash, "k")
UI.rect(dash, 4, 14, 3, 1, "b")
UI.rect(dash, 4, 17, 2, 1, "b")

-- Nuke: burnu yukarı bomba, sarı şerit, kanatçıklar, altta alev
local nuke = UI.grid(S, S)
for y = 0, S - 1 do
  for x = 0, S - 1 do
    local dx, dy = (x + 0.5 - 16) / 5.5, (y + 0.5 - 14) / 8
    if dx * dx + dy * dy <= 1 then nuke[y][x] = x < 16 and "s" or "S" end
  end
end
UI.rect(nuke, 11, 11, 5, 2, "y")
UI.rect(nuke, 16, 11, 5, 2, "o")
for y = 8, 10 do UI.set(nuke, 13, y, "w") end
UI.rect(nuke, 9, 19, 3, 4, "S")
UI.rect(nuke, 20, 19, 3, 4, "S")
UI.rect(nuke, 15, 21, 2, 3, "S")
UI.outline(nuke, "k")
for x = 9, 22 do
  local h = (x % 3 == 0) and 3 or 2
  for y = 0, h - 1 do UI.set(nuke, x, 27 - y, y == 0 and "o" or (x % 2 == 0 and "y" or "r")) end
end

UI.export(OUT, "skill_icons", S, S, { { name = "icons", frames = { framed(dash), framed(nuke) }, ms = 100 } }, { 1 })
