-- Oyuncu can barı: kalp (11x10) + dolgu (16x6, hud_timer_bar ile aynı ölçü; boş ray = hud_timer_bar kare 0).
-- health_heart: normal, hit (beyaz flaş), dead. health_bar: high (yeşil), mid (altın), low (kırmızı).
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script health_bar.lua

local OUT = app.params["out"]
dofile(OUT .. "/ui_common.lua")

UI.P.q = "f08a7a"
UI.P.u, UI.P.v, UI.P.V = "b0e07a", "6cc04a", "3e7a2a" -- yeşil açık/orta/koyu

local HEART = {
  ".rr...rr.",
  "rqrr.rrrr",
  "rqrrrrrrr",
  "rrrrrrrrr",
  ".rrrrrrR.",
  "..rrrrR..",
  "...rrR...",
  "....R....",
}

local function heart(map)
  local g = UI.grid(11, 10)
  for y, row in ipairs(HEART) do
    for x = 1, #row do
      local c = row:sub(x, x)
      if c ~= "." then g[y][x] = map[c] end
    end
  end
  return UI.outline(g, "k")
end

local function fill(light, mid, dark)
  local g = UI.grid(16, 6)
  UI.rect(g, 1, 1, 14, 4, mid)
  UI.rect(g, 1, 1, 14, 1, light)
  UI.rect(g, 1, 4, 14, 1, dark)
  return g
end

UI.export(OUT, "health_heart", 11, 10, {
  { name = "heart", frames = {
    heart({ r = "r", q = "q", R = "R" }), heart({ r = "c", q = "w", R = "y" }), heart({ r = "X", q = "x", R = "z" }),
  }, ms = 100 },
}, { 1, 4 })

UI.export(OUT, "health_bar", 16, 6, {
  { name = "fill", frames = { fill("u", "v", "V"), fill("c", "y", "o"), fill("q", "r", "R") }, ms = 100 },
}, { 1, 4 })
