-- Market paneli çerçevesi (32x32, 9-slice; kenar payı 8 piksel = x4 sheet'te 32).
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script market_panel.lua

local OUT = app.params["out"]
dofile(OUT .. "/ui_common.lua")

local S = 32
local g = UI.grid(S, S)

UI.rect(g, 0, 0, S, S, "G")
UI.frame(g, 0, 0, S, S, "k")
-- Altın kenar şeridi: üst/sol açık, alt/sağ koyu
UI.frame(g, 1, 1, S - 2, S - 2, "o")
UI.rect(g, 2, 1, S - 4, 1, "y")
UI.rect(g, 1, 2, 1, S - 4, "y")
UI.rect(g, 2, S - 2, S - 4, 1, "O")
UI.rect(g, S - 2, 2, 1, S - 4, "O")
UI.frame(g, 2, 2, S - 4, S - 4, "k")
-- İç kabartma
UI.rect(g, 3, 3, S - 6, 1, "g")
UI.rect(g, 3, 3, 1, S - 6, "g")
UI.rect(g, 3, S - 4, S - 6, 1, "D")
UI.rect(g, S - 4, 3, 1, S - 6, "D")

-- Köşe perçinleri
for _, p in ipairs({ { 4, 4 }, { S - 6, 4 }, { 4, S - 6 }, { S - 6, S - 6 } }) do
  UI.rect(g, p[1], p[2], 2, 2, "o")
  UI.set(g, p[1], p[2], "c")
  UI.set(g, p[1] + 1, p[2] + 1, "O")
end

UI.export(OUT, "market_panel", S, S, { { name = "panel", frames = { g }, ms = 100 } }, { 4 })
