-- Dönen altın sikke pickup'ı. Çıktı: gold_coin.aseprite, 1x/10x sheet + JSON, 4x spin GIF.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script gold_coin.lua

local OUT = app.params["out"]
local SIZE, CY, B = 32, 16, 7 -- tuval, dikey merkez, dikey yarıçap

-- Palet: kontur magnet pickup'ından (#3a3a3a), altın tonları zeminden ayrışsın diye sıcak/sarı
local P = {
  k = "3a3a3a", d = "8a5a12", m = "d9a01e", l = "f5d23c", c = "fff6c8", w = "ffffff",
}

-- Ortadaki yıldız (6x6), sol üst köşe (13,13)
local STAR = {
  "..ll..",
  "..ll..",
  "llllll",
  ".llll.",
  ".llll.",
  "ll..ll",
}

local function hex(c)
  return Color { r = tonumber(c:sub(1, 2), 16), g = tonumber(c:sub(3, 4), 16), b = tonumber(c:sub(5, 6), 16), a = 255 }
end

local function grid()
  local g = {}
  for y = 0, SIZE - 1 do
    g[y] = {}
    for x = 0, SIZE - 1 do g[y][x] = "." end
  end
  return g
end

local function ellipse(cx, a)
  local m = grid()
  for y = 0, SIZE - 1 do
    for x = 0, SIZE - 1 do
      local nx, ny = (x + 0.5 - cx) / a, (y + 0.5 - CY) / B
      if nx * nx + ny * ny <= 1 then m[y][x] = true end
    end
  end
  return m
end

local function inside(m, x, y)
  return x >= 0 and y >= 0 and x < SIZE and y < SIZE and m[y][x] == true
end

-- 4-komşu erozyon derinliği: kenar pikseli 1, bir içerisi 2, ...
local function depth(m)
  local d, cur, n = {}, m, 0
  for y = 0, SIZE - 1 do d[y] = {} end
  while true do
    n = n + 1
    local nxt, any = grid(), false
    for y = 0, SIZE - 1 do
      for x = 0, SIZE - 1 do
        if inside(cur, x, y) then
          any = true
          if inside(cur, x - 1, y) and inside(cur, x + 1, y) and inside(cur, x, y - 1) and inside(cur, x, y + 1) then
            nxt[y][x] = true
          else
            d[y][x] = n
          end
        end
      end
    end
    if not any then return d end
    cur = nxt
  end
end

-- total: siluet genişliği, side: kenar şeridinin tarafı (0 = tam yüz, 1 sağ, -1 sol), glint: parlamanın yatay konumu (-1..1)
local function coin(total, side, glint)
  local g = grid()
  if side == "edge" then -- 90 derece: yalnız kenar görünür
    local u, ud = ellipse(16, total / 2), nil
    ud = depth(u)
    for y = 0, SIZE - 1 do
      for x = 0, SIZE - 1 do
        if inside(u, x, y) then g[y][x] = ud[y][x] == 1 and "k" or (x < 16 and "m" or "d") end
      end
    end
    return g
  end
  local a = (side == 0 and total or total - 2) / 2
  local cxf = 16 - side
  local face = ellipse(cxf, a)
  local edge = side == 0 and grid() or ellipse(16 + side, a)
  local u = grid()
  for y = 0, SIZE - 1 do
    for x = 0, SIZE - 1 do
      if inside(face, x, y) or inside(edge, x, y) then u[y][x] = true end
    end
  end
  local ud, fd = depth(u), depth(face)
  local rim = {}
  for y = 0, SIZE - 1 do
    for x = 0, SIZE - 1 do
      if inside(u, x, y) then
        local nx, ny = (x + 0.5 - cxf) / a, (y + 0.5 - CY) / B
        if ud[y][x] == 1 then
          g[y][x] = "k"
        elseif not inside(face, x, y) then
          g[y][x] = "d"
        elseif fd[y][x] <= 2 then
          g[y][x] = (nx + ny < -0.2) and "l" or "m"
          if ny < -0.3 then rim[#rim + 1] = { x = x, y = y, nx = nx } end
        elseif fd[y][x] == 3 then
          g[y][x] = "d"
        else
          g[y][x] = "m"
        end
      end
    end
  end
  -- yıldız: yatay eksende yüz genişliğine göre sıkıştırılır
  local function star(x, y)
    local ox = math.floor(16 + (x + 0.5 - cxf) * 7 / a)
    local row = STAR[y - 12]
    local i = ox - 12
    return row ~= nil and i >= 1 and i <= 6 and row:sub(i, i) == "l"
  end
  for y = 0, SIZE - 1 do
    for x = 0, SIZE - 1 do
      if inside(face, x, y) and (fd[y][x] or 0) >= 4 and star(x, y) then g[y][x] = "l" end
    end
  end
  -- parlama: üst kenarda glint'e en yakın kenar pikseli beyaz, sağındaki krem
  if glint and #rim > 0 then
    local best = rim[1]
    for _, r in ipairs(rim) do
      if math.abs(r.nx - glint) < math.abs(best.nx - glint) then best = r end
    end
    g[best.y][best.x] = "w"
    for _, r in ipairs(rim) do
      if r.y == best.y and r.x == best.x + 1 then g[r.y][r.x] = "c" end
    end
  end
  return g
end

-- Yarım tur (ön ve arka yüz aynı): genişlik ~14*|cos|, sonra döngü başa sarar
local SPIN = {
  coin(14, 0, -0.5),
  coin(12, 1, -0.3),
  coin(10, 1, -0.1),
  coin(6, 1, 0.2),
  coin(4, "edge"),
  coin(6, -1, -0.2),
  coin(10, -1, 0.1),
  coin(12, -1, 0.3),
}

-- Parıltı: sağ üstte "+" belirip söner, tam yüz karesinin üstüne
local function sparkle(stage)
  local g = coin(14, 0, -0.5)
  local sx, sy = 22, 9
  if stage == 1 or stage == 4 then
    g[sy][sx] = "c"
  elseif stage == 2 then
    g[sy][sx] = "w"
    for _, o in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do g[sy + o[2]][sx + o[1]] = "c" end
  else
    g[sy][sx] = "w"
    for _, o in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
      g[sy + o[2]][sx + o[1]] = "c"
      g[sy + o[2] * 2][sx + o[1] * 2] = "l"
    end
  end
  return g
end

local TAGS = {
  { name = "spin", frames = SPIN, ms = 80 },
  { name = "sparkle", frames = { sparkle(1), sparkle(2), sparkle(3), sparkle(4) }, ms = 60 },
}

local function image(g, s)
  local img = Image(SIZE * s, SIZE * s, ColorMode.RGB)
  img:clear(Color { r = 0, g = 0, b = 0, a = 0 })
  for y = 0, SIZE - 1 do
    for x = 0, SIZE - 1 do
      local c = g[y][x]
      if c ~= "." then
        local col = hex(P[c])
        for dy = 0, s - 1 do for dx = 0, s - 1 do img:drawPixel(x * s + dx, y * s + dy, col) end end
      end
    end
  end
  return img
end

-- .aseprite: tüm kareler, tag başına bir aralık
local spr = Sprite(SIZE, SIZE, ColorMode.RGB)
spr.layers[1].name = "coin"
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
spr:saveAs(OUT .. "/gold_coin.aseprite")

-- Sheet'ler: tag başına bir satır (boss_ucube_sheet.json ile aynı biçim)
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
sheet(1):saveAs(OUT .. "/gold_coin_sheet.png")
sheet(10):saveAs(OUT .. "/gold_coin_sheet_x10.png")

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
local file = io.open(OUT .. "/gold_coin_sheet.json", "w")
file:write('{"frames":[\n' .. table.concat(frames, ",\n") .. '\n],\n')
file:write(string.format('"meta":{"app":"Aseprite","image":"gold_coin_sheet.png","format":"RGBA8888","size":{"w":%d,"h":%d},"frameSize":{"w":%d,"h":%d},"layout":"one row per tag","frameTags":[\n',
  cols * SIZE, #TAGS * SIZE, SIZE, SIZE))
file:write(table.concat(tags, ",\n") .. '\n]}}\n')
file:close()

-- 4x spin önizleme GIF'i
local gif = Sprite(SIZE * 4, SIZE * 4, ColorMode.RGB)
for i, g in ipairs(SPIN) do
  if i > 1 then gif:newEmptyFrame() end
  gif.frames[i].duration = 0.08
  gif:newCel(gif.layers[1], gif.frames[i], image(g, 4), Point(0, 0))
end
gif:saveAs(OUT .. "/gold_coin_spin.gif")
