-- "Ucube Mahzeni" zemin + dekor seti. Kaynak: map_ucube.aseprite, export: 10x PNG'ler.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script map_ucube.lua

local OUT = app.params["out"]
local SCALE = 10

-- Palet: zemin = zemin_kahve.png tonları, dekor = oyundaki sprite tonları
local P = {
  m = "403030", b = "574744", h = "7d6561", l = "a18681",
  k = "24171b",
  ["2"] = "2c3e1b", ["3"] = "3c5426", ["4"] = "4b692f",
  x = "544537", y = "816548", z = "ab957f",
  p = "321448", r = "855475",
  e = "380b18", f = "7d0f1f", i = "b5c3df",
  o = "dfdfdf",
}

local function grid(w, h)
  local g = { w = w, h = h }
  for y = 0, h - 1 do
    g[y] = {}
    for x = 0, w - 1 do g[y][x] = "." end
  end
  return g
end

local function get(g, x, y)
  if x < 0 or y < 0 or x >= g.w or y >= g.h then return "." end
  return g[y][x]
end

local function set(g, x, y, c)
  if x >= 0 and y >= 0 and x < g.w and y < g.h then g[y][x] = c end
end

local function copy(g)
  local n = grid(g.w, g.h)
  for y = 0, g.h - 1 do for x = 0, g.w - 1 do n[y][x] = g[y][x] end end
  return n
end

local function disk(g, cx, cy, r, c)
  for y = math.floor(cy - r), math.ceil(cy + r) do
    for x = math.floor(cx - r), math.ceil(cx + r) do
      if (x - cx) ^ 2 + (y - cy) ^ 2 <= r * r + 0.5 then set(g, x, y, c) end
    end
  end
end

-- Kalınlık th: her adımda th x th kare boyar
local function line(g, x0, y0, x1, y1, c, th)
  th = th or 1
  local steps = math.max(math.abs(x1 - x0), math.abs(y1 - y0))
  for s = 0, steps do
    local t = steps == 0 and 0 or s / steps
    local x = math.floor(x0 + (x1 - x0) * t + 0.5)
    local y = math.floor(y0 + (y1 - y0) * t + 0.5)
    for dy = 0, th - 1 do for dx = 0, th - 1 do set(g, x + dx, y + dy, c) end end
  end
end

local function poly(g, pts, c, th)
  for n = 1, #pts - 1 do line(g, pts[n][1], pts[n][2], pts[n + 1][1], pts[n + 1][2], c, th) end
end

local function inside(set_, c) return set_:find(c, 1, true) ~= nil end

-- Konturu malzemenin en koyu tonu: gövdeye 4-komşu boş hücreler
local function outline(g, body, c)
  local marks = {}
  for y = 0, g.h - 1 do
    for x = 0, g.w - 1 do
      if g[y][x] == "." and (inside(body, get(g, x - 1, y)) or inside(body, get(g, x + 1, y))
          or inside(body, get(g, x, y - 1)) or inside(body, get(g, x, y + 1))) then
        marks[#marks + 1] = { x, y }
      end
    end
  end
  for _, m in ipairs(marks) do set(g, m[1], m[2], c) end
end

-- Işık sol-üstten: gövdenin üst/sol kenarı açık ton
local function light(g, body, c)
  local marks = {}
  for y = 0, g.h - 1 do
    for x = 0, g.w - 1 do
      if inside(body, g[y][x]) and (not inside(body, get(g, x, y - 1)) or not inside(body, get(g, x - 1, y))) then
        marks[#marks + 1] = { x, y }
      end
    end
  end
  for _, m in ipairs(marks) do set(g, m[1], m[2], c) end
end

local function hex(c)
  return Color { r = tonumber(c:sub(1, 2), 16), g = tonumber(c:sub(3, 4), 16), b = tonumber(c:sub(5, 6), 16), a = 255 }
end

local function to_image(g)
  local img = Image(g.w, g.h, ColorMode.RGB)
  img:clear(Color { r = 0, g = 0, b = 0, a = 0 })
  for y = 0, g.h - 1 do
    for x = 0, g.w - 1 do
      local c = g[y][x]
      if c ~= "." then img:drawPixel(x, y, hex(P[c])) end
    end
  end
  return img
end

-- ZEMİN: 64x64, 8 sıra x 4 tuğla (15x7 + 1 px harç), çift/tek sıra 8 px kaydırmalı.
-- Harç ve kaydırma 64'e modlu olduğu için dört kenar diksiz.
local function floor_tile()
  local g = grid(64, 64)
  local flat = { [3] = true, [9] = true, [14] = true, [20] = true, [27] = true }
  local worn = { [6] = true, [22] = true, [29] = true }
  local cracks = {
    [11] = { { 4, 0 }, { 5, 2 }, { 7, 3 }, { 8, 6 } },
    [17] = { { 14, 1 }, { 11, 3 }, { 10, 6 } },
    [25] = { { 0, 4 }, { 3, 3 }, { 6, 4 }, { 9, 2 } },
  }
  local missing = 12

  for y = 0, 63 do
    local row = y // 8
    local ry = y % 8
    local offset = (row % 2 == 0) and 0 or 8
    for x = 0, 63 do
      local u = (x - offset) % 64
      local cx = u % 16
      local id = row * 4 + u // 16
      local c
      if ry == 7 or cx == 15 then
        c = "m"
      elseif flat[id] or id == missing then
        c = "b"
      elseif ry == 0 and cx <= 12 then
        c = "h"
      elseif worn[id] and ry == 1 and cx <= 5 then
        c = "h"
      else
        c = "b"
      end
      g[y][x] = c
    end
  end

  -- Brick-local çizim yardımcısı (64'e sarar)
  local function brick_set(id, cx, cy, c)
    local row = id // 4
    local offset = (row % 2 == 0) and 0 or 8
    local x = (offset + (id % 4) * 16 + cx) % 64
    g[row * 8 + cy][x] = c
  end

  for id, pts in pairs(cracks) do
    for n = 1, #pts - 1 do
      local a, b = pts[n], pts[n + 1]
      local steps = math.max(math.abs(b[1] - a[1]), math.abs(b[2] - a[2]))
      for s = 0, steps do
        local t = steps == 0 and 0 or s / steps
        brick_set(id, math.floor(a[1] + (b[1] - a[1]) * t + 0.5), math.floor(a[2] + (b[2] - a[2]) * t + 0.5), "m")
      end
    end
  end

  -- Çökük tuğla: parçalara ayrılmış, sağ ucu eksik (koyu dikdörtgen tekrar göze batmasın)
  for cy = 0, 6 do
    for cx = 13, 14 do brick_set(missing, cx, cy, "m") end
  end
  for _, p in ipairs({ { 4, 0 }, { 4, 1 }, { 5, 2 }, { 5, 3 }, { 4, 4 }, { 4, 5 }, { 4, 6 },
                       { 6, 3 }, { 7, 3 }, { 8, 3 }, { 9, 4 }, { 10, 4 } }) do
    brick_set(missing, p[1], p[2], "m")
  end
  for cx = 0, 3 do brick_set(missing, cx, 0, "h") end
  for cx = 6, 9 do brick_set(missing, cx, 4, "h") end
  return g
end

-- DEKORLAR (saydam zemin üstünde, gölgesiz)
local function catlak()
  local g = grid(16, 16)
  poly(g, { { 7, 1 }, { 8, 5 }, { 6, 9 }, { 8, 14 } }, "k")
  line(g, 8, 5, 12, 7, "k")
  line(g, 12, 7, 13, 10, "k")
  line(g, 6, 9, 3, 11, "k")
  outline(g, "k", "m")
  return g
end

local function balcik_base()
  local g = grid(16, 16)
  disk(g, 7.5, 8, 4.5, "3")
  disk(g, 10.5, 9.5, 3, "3")
  disk(g, 4.5, 9.5, 2.6, "3")
  outline(g, "3", "2")
  light(g, "3", "4")
  return g
end

-- Kabarcık: 1 tohum -> küçük -> büyük -> patlama
local function balcik_frames()
  local frames = {}
  local f1 = balcik_base()
  set(f1, 9, 8, "4"); set(f1, 10, 8, "4")
  frames[1] = f1

  local f2 = balcik_base()
  for _, p in ipairs({ { 9, 6 }, { 10, 6 }, { 8, 7 }, { 11, 7 }, { 8, 8 }, { 11, 8 }, { 9, 9 }, { 10, 9 } }) do set(f2, p[1], p[2], "2") end
  set(f2, 9, 7, "4"); set(f2, 10, 7, "3"); set(f2, 9, 8, "3"); set(f2, 10, 8, "3")
  frames[2] = f2

  local f3 = balcik_base()
  for x = 8, 11 do set(f3, x, 5, "2"); set(f3, x, 10, "2") end
  for y = 6, 9 do set(f3, 7, y, "2"); set(f3, 12, y, "2") end
  for y = 6, 9 do for x = 8, 11 do set(f3, x, y, "3") end end
  set(f3, 8, 6, "4"); set(f3, 9, 6, "4"); set(f3, 8, 7, "4")
  frames[3] = f3

  local f4 = balcik_base()
  for _, p in ipairs({ { 7, 6 }, { 7, 7 }, { 12, 6 }, { 12, 7 }, { 9, 4 }, { 10, 4 }, { 9, 10 }, { 10, 10 } }) do set(f4, p[1], p[2], "4") end
  set(f4, 9, 7, "2"); set(f4, 10, 7, "2"); set(f4, 9, 8, "2"); set(f4, 10, 8, "2")
  frames[4] = f4
  return frames
end

-- Kemik gövdesi kirli kemik tonu, #dfdfdf sadece sol-üst ışık kenarı (düşmanlardan sönük kalsın)
local function kemik()
  local g = grid(16, 16)
  line(g, 4, 6, 10, 10, "z", 2)
  for _, p in ipairs({ { 4, 5 }, { 3, 7 }, { 11, 10 }, { 10, 12 } }) do disk(g, p[1], p[2], 1, "z") end
  line(g, 9, 4, 6, 12, "z")
  disk(g, 9.5, 3.5, 1, "z")
  outline(g, "z", "x")
  light(g, "z", "o")
  return g
end

local function sargi()
  local g = grid(16, 16)
  poly(g, { { 1, 11 }, { 4, 8 }, { 8, 10 }, { 12, 6 } }, "y", 2)
  line(g, 12, 6, 14, 3, "y")
  line(g, 13, 7, 15, 6, "y")
  outline(g, "y", "x")
  light(g, "y", "z")
  return g
end

local function fare_deligi()
  local g = grid(16, 16)
  disk(g, 6.5, 7, 3.2, "k")
  outline(g, "k", "m")
  -- Delik ağzındaki kırık tuğla kenarı (sağ-alt duvar ışık alır)
  for _, p in ipairs({ { 9, 10 }, { 10, 9 }, { 10, 10 }, { 8, 11 }, { 9, 11 } }) do set(g, p[1], p[2], "b") end
  -- Mor kuyruk ucu
  poly(g, { { 10, 6 }, { 12, 7 }, { 13, 9 }, { 12, 11 } }, "r")
  for y = 0, 15 do for x = 0, 15 do
    if g[y][x] == "." and (get(g, x - 1, y) == "r" or get(g, x + 1, y) == "r" or get(g, x, y - 1) == "r" or get(g, x, y + 1) == "r") then
      g[y][x] = "*"
    end
  end end
  for y = 0, 15 do for x = 0, 15 do if g[y][x] == "*" then g[y][x] = "p" end end end
  return g
end

-- Kurumuş koyu leke; kırmızı sadece içte birkaç piksel, göz akı küçük ve yassı (göz düşmanıyla karışmasın)
local function goz_kalinti()
  local g = grid(16, 16)
  disk(g, 7, 8, 3.2, "e")
  disk(g, 10.5, 6.5, 2, "e")
  disk(g, 4.5, 11, 1.6, "e")
  line(g, 11, 10, 13, 12, "e", 2)
  outline(g, "e", "k")
  for _, p in ipairs({ { 8, 8 }, { 9, 8 }, { 8, 9 }, { 10, 6 }, { 11, 6 } }) do set(g, p[1], p[2], "f") end
  set(g, 6, 7, "i"); set(g, 7, 7, "i")
  return g
end

local function izgara()
  local g = grid(32, 32)
  for y = 3, 28 do for x = 3, 28 do
    local frame = x <= 4 or x >= 27 or y <= 4 or y >= 27
    if frame then
      g[y][x] = "x"
    elseif (x - 5) % 4 < 2 then
      g[y][x] = "x"
    else
      g[y][x] = "k"
    end
  end end
  light(g, "x", "y")
  -- Pas lekeleri (ışık kenarını kırar)
  for _, p in ipairs({ { 9, 5 }, { 10, 5 }, { 3, 14 }, { 3, 15 }, { 17, 3 }, { 18, 3 }, { 21, 5 }, { 22, 5 } }) do
    set(g, p[1], p[2], "x")
  end
  return g
end

local function kafes()
  local g = grid(32, 32)
  -- Taban çerçevesi; sağ-alt köşe kırık
  for i = 4, 27 do
    set(g, i, 4, "x"); set(g, i, 5, "x")
    set(g, 4, i, "x"); set(g, 5, i, "x")
    if i <= 18 then set(g, i, 26, "x"); set(g, i, 27, "x") end
    if i <= 17 then set(g, 26, i, "x"); set(g, 27, i, "x") end
  end
  -- Yamulmuş parçalar
  line(g, 20, 27, 23, 25, "x", 2)
  line(g, 27, 20, 25, 23, "x", 2)
  light(g, "x", "y")
  -- Kopmuş parmaklık dipleri
  for n = 0, 4 do
    local a = 8 + n * 4
    set(g, a, 7, "x"); set(g, a + 1, 7, "x")
    set(g, 7, a, "x"); set(g, 7, a + 1, "x")
  end
  -- Deneyden kalan sönük leke
  disk(g, 13, 18, 2, "3")
  outline(g, "3", "2")
  return g
end

-- Sprite: zemin + dekorlar ayrı katman ve slice
local decors = {
  { "catlak", catlak(), 0, 64 },
  { "balcik", nil, 16, 64 },
  { "kemik", kemik(), 32, 64 },
  { "sargi", sargi(), 48, 64 },
  { "fare_deligi", fare_deligi(), 64, 64 },
  { "goz_kalinti", goz_kalinti(), 80, 64 },
  { "izgara", izgara(), 0, 80 },
  { "kafes", kafes(), 32, 80 },
}
local balcik = balcik_frames()

local spr = Sprite(96, 112, ColorMode.RGB)
for _ = 2, 4 do spr:newEmptyFrame() end
for n = 1, 4 do spr.frames[n].duration = 0.15 end

local function add_layer(name, frames_grids, x, y)
  local layer = spr:newLayer()
  layer.name = name
  for n = 1, 4 do
    local g = frames_grids[n] or frames_grids[1]
    spr:newCel(layer, n, to_image(g), Point(x, y))
  end
  local slice = spr:newSlice(Rectangle(x, y, frames_grids[1].w, frames_grids[1].h))
  slice.name = name
end

spr.layers[1].name = "zemin"
local zemin = floor_tile()
for n = 1, 4 do spr:newCel(spr.layers[1], n, to_image(zemin), Point(0, 0)) end
spr:newSlice(Rectangle(0, 0, 64, 64)).name = "zemin_ucube"

for _, d in ipairs(decors) do
  if d[1] == "balcik" then
    add_layer("dekor_balcik", balcik, d[3], d[4])
  else
    add_layer("dekor_" .. d[1], { d[2] }, d[3], d[4])
  end
end

spr:saveAs(OUT .. "/map_ucube.aseprite")

-- Export: nearest-neighbor 10x
local function scaled(g)
  local img = Image(g.w * SCALE, g.h * SCALE, ColorMode.RGB)
  img:clear(Color { r = 0, g = 0, b = 0, a = 0 })
  for y = 0, g.h - 1 do
    for x = 0, g.w - 1 do
      local c = g[y][x]
      if c ~= "." then
        local col = hex(P[c])
        for dy = 0, SCALE - 1 do for dx = 0, SCALE - 1 do img:drawPixel(x * SCALE + dx, y * SCALE + dy, col) end end
      end
    end
  end
  return img
end

scaled(zemin):saveAs(OUT .. "/zemin_ucube.png")
for _, d in ipairs(decors) do
  if d[1] ~= "balcik" then scaled(d[2]):saveAs(OUT .. "/dekor_" .. d[1] .. ".png") end
end

scaled(balcik[1]):saveAs(OUT .. "/dekor_balcik.png")
local sheet = Image(16 * SCALE * 4, 16 * SCALE, ColorMode.RGB)
sheet:clear(Color { r = 0, g = 0, b = 0, a = 0 })
local json = { '{"frames":[' }
for n = 1, 4 do
  sheet:drawImage(scaled(balcik[n]), Point((n - 1) * 16 * SCALE, 0))
  json[#json + 1] = string.format('  {"filename":"balcik_%d","frame":{"x":%d,"y":0,"w":%d,"h":%d},"duration":150}%s',
    n - 1, (n - 1) * 16 * SCALE, 16 * SCALE, 16 * SCALE, n < 4 and "," or "")
end
json[#json + 1] = '],'
json[#json + 1] = string.format('"meta":{"image":"dekor_balcik_sheet.png","size":{"w":%d,"h":%d},"scale":"%d",', 64 * SCALE, 16 * SCALE, SCALE)
json[#json + 1] = '"frameTags":[{"name":"balcik","from":0,"to":3,"direction":"forward"}]}}'
sheet:saveAs(OUT .. "/dekor_balcik_sheet.png")
local file = io.open(OUT .. "/dekor_balcik_sheet.json", "w")
file:write(table.concat(json, "\n"))
file:close()
print("ok")
