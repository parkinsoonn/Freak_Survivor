-- Yıldırımın vurduğu düşmandaki kıvılcım (16x16, 4 kare, tek seferlik): ortadan saçılan mavi-beyaz çatlaklar.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script lightning_spark.lua

local OUT = app.params["out"]
dofile(OUT .. "/../ui/ui_common.lua")

local S = 16
-- Sekiz yöne kırık ışınlar; her karede uzar, son karede sadece uçlar kalır
local DIRS = { { 1, 0 }, { 1, 1 }, { 0, 1 }, { -1, 1 }, { -1, 0 }, { -1, -1 }, { 0, -1 }, { 1, -1 } }

local frames = {}
for f = 1, 4 do
  local g = UI.grid(S, S)
  local from, to = (f == 4) and 5 or 1, ({ 2, 4, 6, 7 })[f]
  for i, d in ipairs(DIRS) do
    for t = from, to do
      -- Tek yönlerde her 2 adımda bir yana kırılır (zikzak)
      local jog = (i % 2 == 1 and t % 2 == 0) and 1 or 0
      local x, y = 8 + d[1] * t + d[2] * jog, 8 + d[2] * t + d[1] * jog
      UI.set(g, x, y, (t >= to - 1) and "b" or "w")
    end
  end
  if f <= 2 then UI.rect(g, 7, 7, 2, 2, "w") end
  if f == 1 then UI.frame(g, 6, 6, 4, 4, "c") end
  frames[#frames + 1] = g
end

UI.export(OUT, "lightning_spark", S, S, { { name = "spark", frames = frames, ms = 50 } }, { 1 })
