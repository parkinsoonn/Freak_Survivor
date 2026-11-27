-- Metin butonu ailesi (24x14, 9-slice; kenar payı 4 piksel = x4 sheet'te 16). Yazı Godot'ta Label.
-- Satırlar: primary (altın), secondary (zeytin), danger (kırmızı). Sütunlar: normal, hover, pressed, disabled.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script button.lua

local OUT = app.params["out"]
dofile(OUT .. "/ui_common.lua")

UI.P.q = "f08a7a" -- açık kırmızı (danger hover / parlama)

local W, H = 24, 14

-- Gövde H-1 piksel; altında 1 piksel gölge. Basılıyken 1 piksel aşağı iner, gölge kaybolur.
local function button(fill, light, dark, shadow, dy)
  local g = UI.grid(W, H)
  local h = H - 1
  UI.rect(g, 0, dy, W, h, fill)
  UI.rect(g, 1, dy + 1, W - 2, 1, light)
  UI.set(g, 1, dy + 2, light)
  UI.rect(g, 1, dy + h - 2, W - 2, 1, dark)
  if dy == 0 then UI.rect(g, 1, h, W - 2, 1, shadow) end
  UI.frame(g, 0, dy, W, h, "k")
  for _, p in ipairs({ { 0, dy }, { W - 1, dy }, { 0, dy + h - 1 }, { W - 1, dy + h - 1 } }) do UI.set(g, p[1], p[2], ".") end
  return g
end

local function family(n, h, p, shadow)
  return { button(n[1], n[2], n[3], shadow, 0), button(h[1], h[2], h[3], shadow, 0), button(p[1], p[2], p[3], shadow, 1),
    button("X", "x", "z", "z", 0) }
end

UI.export(OUT, "button", W, H, {
  { name = "primary", frames = family({ "o", "y", "O" }, { "y", "c", "o" }, { "O", "o", "O" }, "O"), ms = 100 },
  { name = "secondary", frames = family({ "G", "g", "D" }, { "g", "c", "H" }, { "H", "G", "D" }, "D"), ms = 100 },
  { name = "danger", frames = family({ "r", "q", "R" }, { "q", "c", "r" }, { "R", "r", "R" }, "R"), ms = 100 },
}, { 1, 4 })
