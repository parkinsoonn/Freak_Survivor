-- Market ekranının solunda duran tüccar + idle döngüsü. Çıktı: merchant.aseprite, 1x/10x sheet + JSON, 4x idle GIF.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script merchant.lua

local OUT = app.params["out"]
local SIZE, MS = 64, 130

-- Palet (20 renk): kontur diğer sprite'larla aynı, altınlar gold_coin ile aynı, yeşil yok (market zemini zeytin yeşili)
local P = {
  k = "3a3a3a",                               -- kontur
  D = "2b1d45", M = "47306b", L = "6a4c95",   -- pelerin / başlık
  f = "120c1a",                               -- başlığın içi
  n = "2a3a6b",                               -- lacivert yama
  r = "4a2f1f", e = "6e4a2e", a = "94683f",   -- deri (çanta, bot, eldiven, kemer)
  s = "4d4d5c", t = "8a8a99",                 -- metal
  g = "8a5a12", h = "d9a01e", l = "f5d23c", c = "fff6c8", -- altın paleti (gözler ve dişler de)
  B = "3fa9f5", b = "b8ecff",                 -- ışın kılıcı parıltısı
  o = "ffb347", y = "ffe4a3",                 -- fener ışığı
}

local N4 = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

local function key(x, y) return y * SIZE + x end
local function inb(x, y) return x >= 0 and y >= 0 and x < SIZE and y < SIZE end
local function has(m, x, y) return inb(x, y) and m[key(x, y)] == true end

-- Maske: piksel merkezi şekil içindeyse dolu
local function mask_of(fn)
  local m = {}
  for y = 0, SIZE - 1 do
    for x = 0, SIZE - 1 do
      if fn(x + 0.5, y + 0.5) then m[key(x, y)] = true end
    end
  end
  return m
end

local function poly(pts, dx, dy)
  return mask_of(function(px, py)
    local inside, j = false, #pts
    for i = 1, #pts do
      local xi, yi, xj, yj = pts[i][1] + dx, pts[i][2] + dy, pts[j][1] + dx, pts[j][2] + dy
      if (yi > py) ~= (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi) + xi then inside = not inside end
      j = i
    end
    return inside
  end)
end

local function ellipse(cx, cy, rx, ry)
  return mask_of(function(px, py)
    local nx, ny = (px - cx) / rx, (py - cy) / ry
    return nx * nx + ny * ny <= 1
  end)
end

-- Uçlar dahil
local function rect(x0, y0, x1, y1)
  return mask_of(function(px, py) return px > x0 and px < x1 + 1 and py > y0 and py < y1 + 1 end)
end

local function union(...)
  local u = {}
  for _, m in ipairs({ ... }) do for k in pairs(m) do u[k] = true end end
  return u
end

local function inter(a, b)
  local u = {}
  for k in pairs(a) do if b[k] then u[k] = true end end
  return u
end

-- Önce kontur halkası, sonra dolgu. skip: halkanın üzerine yazmayacağı renkler (aynı kumaşın parçaları kaynaşsın)
local function paint(g, m, tone, ring, skip)
  if ring then
    for k in pairs(m) do
      local x, y = k % SIZE, k // SIZE
      for _, o in ipairs(N4) do
        local nx, ny = x + o[1], y + o[2]
        if inb(nx, ny) and not m[key(nx, ny)] and not (skip and skip[g[key(nx, ny)]]) then g[key(nx, ny)] = ring end
      end
    end
  end
  for k in pairs(m) do
    g[k] = type(tone) == "function" and tone(k % SIZE, k // SIZE, m) or tone
  end
end

-- Işık sol üstten: satırın sağ %30'u ve alt kenar koyu, sol kenar ve üst kenar açık
local function band(d, mid, li)
  return function(x, y, m)
    local x0, x1 = x, x
    while has(m, x0 - 1, y) do x0 = x0 - 1 end
    while has(m, x1 + 1, y) do x1 = x1 + 1 end
    if not has(m, x, y + 1) then return d end
    if x1 - x0 < 3 then return mid end
    local r = (x - x0) / (x1 - x0)
    if r >= 0.7 then return d end
    if r <= 0.15 or not has(m, x, y - 1) then return li end
    return mid
  end
end

local function stamp(g, x0, y0, rows)
  for j, row in ipairs(rows) do
    for i = 1, #row do
      local ch = row:sub(i, i)
      if ch ~= "." then g[key(x0 + i - 1, y0 + j - 1)] = ch end
    end
  end
end

local PURPLE = band("D", "M", "L")
local LEATHER = band("r", "e", "a")
local GOLD = band("g", "h", "l")
local FABRIC = { D = true, M = true, L = true }

-- Nefes: üst gövde 1 px yukarı (kareler 1-4). Başlık 1, etek 2 kare gecikmeyle izler.
local BREATH = { 1, 1, 1, 1, 0, 0, 0, 0 }
local function lag(i, n) return BREATH[(i - 1 - n) % 8 + 1] end
local BLINK = 7                                  -- gözler bu karede kapalı
local LANTERN = { 1, 1, 0, 1, 1, 1, 0, 1 }       -- 1 = parlak
local SABER = { 1, 0, 1, 1, 0, 1, 1, 0 }
local SPARK = { 0, 0, 1, 2, 3, 1, 0, 0 }         -- sikke parıltısı evresi

local function merchant(i)
  local b, bh, sway = BREATH[i], lag(i, 1), lag(i, 2)
  local g = {}

  -- Çantadan çıkan tabanca namlusu ve ışın kılıcı kabzası
  local barrel = union(rect(15, 6 - b, 17, 15 - b), rect(16, 5 - b, 16, 5 - b))
  paint(g, barrel, function(x) return x == 15 and "t" or "s" end, "k")
  g[key(16, 6 - b)] = "k"
  paint(g, rect(42, 8 - b, 44, 15 - b), function(x, y)
    if y == 8 - b or y == 11 - b or y == 13 - b then return "s" end
    return x == 44 and "s" or "t"
  end, "k")
  if SABER[i] == 1 then
    paint(g, rect(43, 4 - b, 43, 7 - b), "b")
    paint(g, union(rect(42, 5 - b, 42, 6 - b), rect(44, 5 - b, 44, 6 - b)), "B")
  else
    paint(g, rect(43, 5 - b, 43, 7 - b), "B")
  end

  -- Sırt çantası (omuzların iki yanından taşar)
  paint(g, poly({ { 15, 15 }, { 45, 15 }, { 47, 17 }, { 47, 34 }, { 13, 34 }, { 13, 17 } }, 0, -b), LEATHER, "k")

  -- Botlar (sabit)
  paint(g, union(rect(21, 55, 26, 60), rect(19, 58, 20, 60)), LEATHER, "k")
  paint(g, union(rect(34, 55, 39, 60), rect(40, 58, 41, 60)), LEATHER, "k")

  -- Yamalı etek ucu: gecikmeli 1 px salınım
  paint(g, poly({ { 12, 49 }, { 48, 49 }, { 49, 53 }, { 47, 56 }, { 44, 54 }, { 41, 57 }, { 38, 55 }, { 34, 57 },
    { 30, 55 }, { 26, 57 }, { 23, 55 }, { 19, 57 }, { 16, 54 }, { 13, 56 }, { 11, 53 } }, sway, 0), PURPLE, "k")

  -- Pelerin: omuzlar nefesle kalkar, bel aşağısı sabit (gövde esner)
  local cloak = poly({ { 20, 24 - b }, { 40, 24 - b }, { 44, 30 - b }, { 46, 40 }, { 48, 51 }, { 12, 51 }, { 14, 40 },
    { 16, 30 - b } }, 0, 0)
  paint(g, cloak, PURPLE, "k", FABRIC)
  for y = 42, 51 do
    g[key(25, y)] = "D"
    g[key(36, y + 1)] = "D"
  end
  paint(g, rect(18, 34, 21, 37), "n", "D")
  paint(g, rect(38, 44, 41, 47), "e", "D")
  for _, p in ipairs({ { 38, 44 }, { 41, 44 }, { 38, 47 }, { 41, 47 } }) do g[key(p[1], p[2])] = "a" end

  -- Kemer + altın toka
  paint(g, inter(cloak, rect(0, 40, SIZE - 1, 41)), function(_, y) return y == 40 and "e" or "r" end)
  stamp(g, 28, 39, { "lhhg", "h..g", "h..g", "hggg" })

  -- Belden sarkan fener
  paint(g, rect(13, 42, 13, 43), "s")
  local bright = LANTERN[i] == 1
  paint(g, rect(11, 44, 15, 50), function(x, y)
    if y == 44 or y == 50 or x == 11 or x == 15 then return "s" end
    if x == 13 and (y == 47 or (bright and (y == 46 or y == 48))) then return "y" end
    return "o"
  end, "k")

  -- Başlık: sol üste kıvrılan sivri uç, 1 kare gecikmeli
  local hood = union(ellipse(30, 19 - bh, 11, 10.5), poly({ { 21, 13 }, { 15, 6 }, { 18, 6 }, { 26, 10 } }, 0, -bh))
  paint(g, hood, PURPLE, "k")
  local face = ellipse(31, 21 - bh, 7, 6.5)
  for k in pairs(hood) do
    local x, y = k % SIZE, k // SIZE
    if not face[k] then
      for _, o in ipairs(N4) do
        if has(face, x + o[1], y + o[2]) then g[k] = (x < 31 or y < 19 - bh) and "L" or "M" end
      end
    end
  end
  paint(g, face, "f")

  -- Karanlıkta parlayan gözler ve sivri sırıtış
  local eye = i == BLINK and { "..", "ll", ".." } or { "cc", "cc", "ll" }
  stamp(g, 27, 20 - bh, eye)
  stamp(g, 33, 20 - bh, eye)
  stamp(g, 28, 24 - bh, { "c.c.c.c", ".c.c.c." })

  -- Sağ kol market kartlarına doğru uzanır, eldivenli elde altın sikke
  paint(g, poly({ { 37, 27 }, { 42, 25 }, { 50, 32 }, { 48, 36 }, { 42, 33 }, { 38, 33 } }, 0, -b), PURPLE, "k")
  paint(g, ellipse(49.5, 34 - b, 2.6, 2.6), LEATHER, "k")
  paint(g, ellipse(50.5, 29 - b, 3.6, 3.6), GOLD, "k")
  g[key(49, 28 - b)] = "c"

  -- Sikke parıltısı: "+" belirip söner
  local sx, sy, st = 54, 24 - b, SPARK[i]
  if st == 1 then
    g[key(sx, sy)] = "l"
  elseif st >= 2 then
    g[key(sx, sy)] = "c"
    for _, o in ipairs(N4) do
      g[key(sx + o[1], sy + o[2])] = st == 2 and "l" or "c"
      if st == 3 then g[key(sx + o[1] * 2, sy + o[2] * 2)] = "l" end
    end
  end
  return g
end

local IDLE = {}
for i = 1, 8 do IDLE[i] = merchant(i) end
local TAGS = { { name = "idle", frames = IDLE, ms = MS } }

local function hex(c)
  return Color { r = tonumber(c:sub(1, 2), 16), g = tonumber(c:sub(3, 4), 16), b = tonumber(c:sub(5, 6), 16), a = 255 }
end

local function image(g, s)
  local img = Image(SIZE * s, SIZE * s, ColorMode.RGB)
  img:clear(Color { r = 0, g = 0, b = 0, a = 0 })
  for k, ch in pairs(g) do
    local x, y, col = k % SIZE, k // SIZE, hex(P[ch])
    for dy = 0, s - 1 do for dx = 0, s - 1 do img:drawPixel(x * s + dx, y * s + dy, col) end end
  end
  return img
end

-- .aseprite: tüm kareler, tag başına bir aralık
local spr = Sprite(SIZE, SIZE, ColorMode.RGB)
spr.layers[1].name = "merchant"
local n = 0
for _, t in ipairs(TAGS) do
  local from = n + 1
  for _, g in ipairs(t.frames) do
    n = n + 1
    if n > 1 then spr:newEmptyFrame() end
    spr.frames[n].duration = t.ms / 1000
    spr:newCel(spr.layers[1], spr.frames[n], image(g, 1), Point(0, 0))
  end
  local tag = spr:newTag(from, n)
  tag.name = t.name
end
spr:saveAs(OUT .. "/merchant.aseprite")

-- Sheet'ler: tag başına bir satır (gold_coin_sheet.json ile aynı biçim)
local cols = 0
for _, t in ipairs(TAGS) do cols = math.max(cols, #t.frames) end
local function sheet(s)
  local img = Image(cols * SIZE * s, #TAGS * SIZE * s, ColorMode.RGB)
  img:clear(Color { r = 0, g = 0, b = 0, a = 0 })
  for row, t in ipairs(TAGS) do
    for i, g in ipairs(t.frames) do img:drawImage(image(g, s), Point((i - 1) * SIZE * s, (row - 1) * SIZE * s)) end
  end
  return img
end
sheet(1):saveAs(OUT .. "/merchant_sheet.png")
sheet(10):saveAs(OUT .. "/merchant_sheet_x10.png")

local frames, tags, idx = {}, {}, 0
for row, t in ipairs(TAGS) do
  local durs = {}
  for i = 1, #t.frames do
    frames[#frames + 1] = string.format('  {"filename":"%s_%d","frame":{"x":%d,"y":%d,"w":%d,"h":%d},"duration":%d}',
      t.name, i - 1, (i - 1) * SIZE, (row - 1) * SIZE, SIZE, SIZE, t.ms)
    durs[#durs + 1] = tostring(t.ms)
  end
  tags[#tags + 1] = string.format('  {"name":"%s","from":%d,"to":%d,"direction":"forward","row":%d,"durations":[%s]}',
    t.name, idx, idx + #t.frames - 1, row - 1, table.concat(durs, ","))
  idx = idx + #t.frames
end
local file = io.open(OUT .. "/merchant_sheet.json", "w")
file:write('{"frames":[\n' .. table.concat(frames, ",\n") .. '\n],\n')
file:write(string.format('"meta":{"app":"Aseprite","image":"merchant_sheet.png","format":"RGBA8888","size":{"w":%d,"h":%d},"frameSize":{"w":%d,"h":%d},"layout":"one row per tag","frameTags":[\n',
  cols * SIZE, #TAGS * SIZE, SIZE, SIZE))
file:write(table.concat(tags, ",\n") .. '\n]}}\n')
file:close()

-- 4x idle önizleme GIF'i
local gif = Sprite(SIZE * 4, SIZE * 4, ColorMode.RGB)
for i, g in ipairs(IDLE) do
  if i > 1 then gif:newEmptyFrame() end
  gif.frames[i].duration = MS / 1000
  gif:newCel(gif.layers[1], gif.frames[i], image(g, 4), Point(0, 0))
end
gif:saveAs(OUT .. "/merchant_idle.gif")
