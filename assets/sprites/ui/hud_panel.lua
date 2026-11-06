-- Oyun içi HUD paneli (16x16, 9-slice; kenar payı 5 piksel = x4 sheet'te 20). market_panel'in ince hali.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script hud_panel.lua

local OUT = app.params["out"]
dofile(OUT .. "/ui_common.lua")

local S = 16
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
UI.rect(g, 3, S - 4, S - 6, 1, "D")
-- Yuvarlatılmış dış köşeler
for _, p in ipairs({ { 0, 0 }, { S - 1, 0 }, { 0, S - 1 }, { S - 1, S - 1 } }) do UI.set(g, p[1], p[2], ".") end

UI.export(OUT, "hud_panel", S, S, { { name = "panel", frames = { g }, ms = 100 } }, { 4 })
