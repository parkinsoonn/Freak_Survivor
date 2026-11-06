-- Dalga süresi çubuğu (16x6, 9-slice; kenar payı 2 piksel = x4 sheet'te 8). Kare 0: boş çubuk, kare 1: dolgu.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script hud_timer_bar.lua

local OUT = app.params["out"]
dofile(OUT .. "/ui_common.lua")

local W, H = 16, 6

local empty = UI.grid(W, H)
UI.rect(empty, 0, 0, W, H, "D")
UI.rect(empty, 1, H - 2, W - 2, 1, "H")
UI.frame(empty, 0, 0, W, H, "k")

-- Dolgu çerçevenin içinde kalır (dış 1 piksel boş): açık üst, koyu alt
local fill = UI.grid(W, H)
UI.rect(fill, 1, 1, W - 2, H - 2, "y")
UI.rect(fill, 1, 1, W - 2, 1, "c")
UI.rect(fill, 1, H - 2, W - 2, 1, "o")

UI.export(OUT, "hud_timer_bar", W, H, { { name = "bar", frames = { empty, fill }, ms = 100 } }, { 4 })
