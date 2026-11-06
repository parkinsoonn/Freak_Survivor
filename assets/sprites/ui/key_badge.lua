-- Skill ikonlarının altındaki tuş kapağı (12x10, 9-slice; kenar payı 3 piksel = x4 sheet'te 12). Yazı Godot'ta Label.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script key_badge.lua

local OUT = app.params["out"]
dofile(OUT .. "/ui_common.lua")

local W, H = 12, 10
local g = UI.grid(W, H)

-- Yüz + alt kenarda kalın gölge (basılabilir tuş görünümü)
UI.rect(g, 0, 0, W, H, "s")
UI.rect(g, 1, 1, W - 2, 1, "w")
UI.rect(g, 1, H - 3, W - 2, 2, "S")
UI.frame(g, 0, 0, W, H, "k")
for _, p in ipairs({ { 0, 0 }, { W - 1, 0 }, { 0, H - 1 }, { W - 1, H - 1 } }) do UI.set(g, p[1], p[2], ".") end

UI.export(OUT, "key_badge", W, H, { { name = "key", frames = { g }, ms = 100 } }, { 4 })
