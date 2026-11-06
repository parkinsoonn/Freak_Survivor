-- Nişancının mermisi (8x8, 2 karelik titreşim): mor enerji topu.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script enemy_bullet.lua

local OUT = app.params["out"]
dofile(OUT .. "/../ui/ui_common.lua")

local S = 8

local frames = {}
for f = 1, 2 do
  local g = UI.grid(S, S)
  for y = 0, S - 1 do
    for x = 0, S - 1 do
      local dx, dy = x + 0.5 - 4, y + 0.5 - 4
      local d = math.sqrt(dx * dx + dy * dy)
      if d <= 2.9 then g[y][x] = d <= (f == 1 and 1.2 or 1.8) and "w" or (d <= 2.1 and "p" or "P") end
    end
  end
  frames[#frames + 1] = UI.outline(g, "k")
end

UI.export(OUT, "enemy_bullet", S, S, { { name = "fly", frames = frames, ms = 100 } }, { 1 })
