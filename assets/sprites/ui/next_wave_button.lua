-- "SONRAKİ WAVE" butonu (84x24; yazı Godot'ta Label). Satırlar: normal (4 karelik nabız), hover, pressed.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script next_wave_button.lua

local OUT = app.params["out"]
dofile(OUT .. "/ui_common.lua")

local W, H = 84, 24
local PAD = 2 -- nabız parlaması için dış boşluk

-- glow: dış parlama kalınlığı (0-2), dy: basılıyken 1 piksel aşağı
local function button(fill, light, dark, glow, dy)
  local g = UI.grid(W, H)
  local x, y, w, h = PAD, PAD + dy, W - PAD * 2, H - PAD * 2 - 1
  if glow > 0 then
    UI.rect(g, x - glow + 1, y - glow + 1, w + glow * 2 - 2, h + glow * 2 - 2, glow == 2 and "c" or "y")
  end
  UI.rect(g, x, y, w, h, fill)
  UI.rect(g, x + 1, y + 1, w - 2, 1, light)
  UI.rect(g, x + 1, y + h - 2, w - 2, 1, dark)
  -- Gölge (basılıyken yok)
  if dy == 0 then UI.rect(g, x + 1, y + h, w - 2, 1, "O") end
  UI.frame(g, x, y, w, h, "k")
  for _, p in ipairs({ { x, y }, { x + w - 1, y }, { x, y + h - 1 }, { x + w - 1, y + h - 1 } }) do UI.set(g, p[1], p[2], ".") end
  return g
end

UI.export(OUT, "next_wave_button", W, H, {
  { name = "normal", frames = {
    button("o", "y", "O", 0, 0), button("o", "y", "O", 1, 0), button("o", "y", "O", 2, 0), button("o", "y", "O", 1, 0),
  }, ms = 150 },
  { name = "hover", frames = { button("y", "c", "o", 1, 0) }, ms = 100 },
  { name = "pressed", frames = { button("O", "o", "O", 0, 1) }, ms = 100 },
}, { 1 })
