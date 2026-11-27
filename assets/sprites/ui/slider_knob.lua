-- Ses slider'ının tutamacı (8x12). Ray ve dolgu hud_timer_bar'dan (boş + altın dolgu) gelir.
-- Kareler: normal, hover, pressed.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script slider_knob.lua

local OUT = app.params["out"]
dofile(OUT .. "/ui_common.lua")

local W, H = 8, 12

local function knob(fill, light, dark, dy)
  local g = UI.grid(W, H)
  local h = H - 1
  UI.rect(g, 0, dy, W, h, fill)
  UI.rect(g, 1, dy + 1, W - 2, 1, light)
  UI.rect(g, 1, dy + h - 2, W - 2, 1, dark)
  -- Ortada tırtık
  UI.rect(g, 3, dy + 4, 1, 3, dark)
  UI.rect(g, 4, dy + 4, 1, 3, light)
  if dy == 0 then UI.rect(g, 1, h, W - 2, 1, "O") end
  UI.frame(g, 0, dy, W, h, "k")
  for _, p in ipairs({ { 0, dy }, { W - 1, dy }, { 0, dy + h - 1 }, { W - 1, dy + h - 1 } }) do UI.set(g, p[1], p[2], ".") end
  return g
end

UI.export(OUT, "slider_knob", W, H, {
  { name = "knob", frames = { knob("o", "y", "O", 0), knob("y", "c", "o", 0), knob("O", "o", "O", 1) }, ms = 100 },
}, { 1, 4 })
