-- Upgrade kartı çerçevesi (24x24, 9-slice; kenar payı 6 piksel = x4 sheet'te 24).
-- Satırlar: normal, hover (5 karelik parlama), disabled, max.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script upgrade_card.lua

local OUT = app.params["out"]
dofile(OUT .. "/ui_common.lua")

local S = 24

-- fill: iç renk, light/dark: kabartma, ring: konturun içindeki halka (nil = yok)
local function card(fill, light, dark, ring)
  local g = UI.grid(S, S)
  UI.rect(g, 1, 1, S - 2, S - 2, fill)
  UI.rect(g, 2, 2, S - 4, 1, light)
  UI.rect(g, 2, 2, 1, S - 4, light)
  UI.rect(g, 2, S - 3, S - 4, 1, dark)
  UI.rect(g, S - 3, 2, 1, S - 4, dark)
  if ring then UI.frame(g, 1, 1, S - 2, S - 2, ring) end
  -- Köşeler yuvarlak: konturu köşeden bir piksel içeri al
  UI.frame(g, 0, 0, S, S, "k")
  for _, p in ipairs({ { 0, 0 }, { S - 1, 0 }, { 0, S - 1 }, { S - 1, S - 1 } }) do UI.set(g, p[1], p[2], ".") end
  for _, p in ipairs({ { 1, 1 }, { S - 2, 1 }, { 1, S - 2 }, { S - 2, S - 2 } }) do UI.set(g, p[1], p[2], "k") end
  return g
end

-- Hover: altın halka nabız gibi parlar, ortadaki karede köşelerde kıvılcım
local HOVER_RING = { "O", "o", "y", "c", "y" }
local hover = {}
for i, ring in ipairs(HOVER_RING) do
  local g = card("H", "g", "D", ring)
  if i == 4 then
    for _, p in ipairs({ { 2, 2 }, { S - 3, 2 }, { 2, S - 3 }, { S - 3, S - 3 } }) do UI.set(g, p[1], p[2], "w") end
  end
  hover[#hover + 1] = g
end

local max = card("H", "g", "D", "o")
UI.frame(max, 2, 2, S - 4, S - 4, "y")
for _, p in ipairs({ { 3, 3 }, { S - 4, 3 }, { 3, S - 4 }, { S - 4, S - 4 } }) do UI.set(max, p[1], p[2], "w") end

UI.export(OUT, "upgrade_card", S, S, {
  { name = "normal", frames = { card("H", "g", "D") }, ms = 100 },
  { name = "hover", frames = hover, ms = 90 },
  { name = "disabled", frames = { card("X", "x", "z") }, ms = 100 },
  { name = "max", frames = { max }, ms = 100 },
}, { 4 })
