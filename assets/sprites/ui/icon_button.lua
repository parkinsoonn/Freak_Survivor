-- Kare ikon butonu (16x16, 9-slice; kenar payı 4 piksel = x4 sheet'te 16) + üstüne binen glifler.
-- Satır 0 "button": normal, hover, pressed, disabled. Satır 1 "glyphs": sol ok, sağ ok, ses açık, ses kapalı.
-- Glifler normal gövdeye göre ortalı; pressed durumunda Godot'ta 1 piksel aşağı kaydırılır.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script icon_button.lua

local OUT = app.params["out"]
dofile(OUT .. "/ui_common.lua")

local S = 16

local function button(fill, light, dark, shadow, dy)
  local g = UI.grid(S, S)
  local h = S - 1
  UI.rect(g, 0, dy, S, h, fill)
  UI.rect(g, 1, dy + 1, S - 2, 1, light)
  UI.set(g, 1, dy + 2, light)
  UI.rect(g, 1, dy + h - 2, S - 2, 1, dark)
  if dy == 0 then UI.rect(g, 1, h, S - 2, 1, shadow) end
  UI.frame(g, 0, dy, S, h, "k")
  for _, p in ipairs({ { 0, dy }, { S - 1, dy }, { 0, dy + h - 1 }, { S - 1, dy + h - 1 } }) do UI.set(g, p[1], p[2], ".") end
  return g
end

-- Gövde merkezi y=7
local function arrow(dir)
  local g = UI.grid(S, S)
  for i = 0, 4 do
    local x = dir < 0 and (5 + i) or (10 - i)
    UI.rect(g, x, 7 - i, 1, i * 2 + 1, "c")
  end
  return UI.outline(g, "k")
end

local function speaker(muted)
  local g = UI.grid(S, S)
  UI.rect(g, 3, 6, 2, 3, "c")
  for i = 0, 3 do UI.rect(g, 5 + i, 6 - i, 1, 3 + i * 2, "c") end
  UI.outline(g, "k")
  if muted then
    for i = 0, 3 do
      UI.set(g, 10 + i, 5 + i, "r")
      UI.set(g, 13 - i, 5 + i, "r")
    end
  else
    for _, p in ipairs({ { 10, 6 }, { 10, 7 }, { 10, 8 }, { 12, 4 }, { 13, 5 }, { 13, 6 }, { 13, 7 }, { 13, 8 }, { 13, 9 }, { 12, 10 } }) do
      UI.set(g, p[1], p[2], "c")
    end
  end
  return g
end

UI.export(OUT, "icon_button", S, S, {
  { name = "button", frames = {
    button("G", "g", "D", "D", 0), button("g", "c", "H", "D", 0), button("H", "G", "D", "D", 1), button("X", "x", "z", "z", 0),
  }, ms = 100 },
  { name = "glyphs", frames = { arrow(-1), arrow(1), speaker(false), speaker(true) }, ms = 100 },
}, { 1, 4 })
