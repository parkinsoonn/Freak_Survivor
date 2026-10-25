-- UI asset üreteçlerinin ortak kısmı (gold_coin.lua örüntüsü): ızgara çizimi + .aseprite / sheet / JSON / GIF çıktısı.
-- Her üreteç: dofile(app.params["out"] .. "/ui_common.lua")

UI = {}

-- Palet: menü paneli zeytin yeşili (#727644), siyah kontur/yazı, beyaz/altın vurgular
UI.P = {
  k = "1c1c1c", -- kontur
  w = "ffffff", c = "fff6c8", -- beyaz, krem
  y = "f5d23c", o = "d9a01e", O = "8a5a12", -- altın açık/orta/koyu (gold_coin ile aynı)
  g = "9a9e5c", G = "727644", H = "5d6137", D = "4f522e", -- zeytin açık/panel/kart/koyu
  x = "5a5a48", X = "4a4a3a", z = "3a3a2c", -- devre dışı griler
  r = "e04848", R = "8a1e1e", -- kırmızı
  p = "e8a0ff", P = "a040f0", -- ışın kılıcı moru
  b = "7ad0ff", B = "2a70c0", -- mavi
  s = "c8c8c8", S = "6a6a6a", -- gri
  n = "e0b080", N = "7a5030", -- ten, kahve
}

local function hex(c)
  return Color { r = tonumber(c:sub(1, 2), 16), g = tonumber(c:sub(3, 4), 16), b = tonumber(c:sub(5, 6), 16), a = 255 }
end

function UI.grid(w, h)
  local g = { w = w, h = h }
  for y = 0, h - 1 do
    g[y] = {}
    for x = 0, w - 1 do g[y][x] = "." end
  end
  return g
end

function UI.set(g, x, y, c)
  if x >= 0 and y >= 0 and x < g.w and y < g.h then g[y][x] = c end
end

function UI.get(g, x, y)
  if x >= 0 and y >= 0 and x < g.w and y < g.h then return g[y][x] end
  return "."
end

function UI.rect(g, x, y, w, h, c)
  for yy = y, y + h - 1 do
    for xx = x, x + w - 1 do UI.set(g, xx, yy, c) end
  end
end

-- 1 piksellik çerçeve (içi boş)
function UI.frame(g, x, y, w, h, c)
  UI.rect(g, x, y, w, 1, c)
  UI.rect(g, x, y + h - 1, w, 1, c)
  UI.rect(g, x, y, 1, h, c)
  UI.rect(g, x + w - 1, y, 1, h, c)
end

-- Dolu piksellerin 4-komşu boş komşularını konturla
function UI.outline(g, c)
  local add = {}
  for y = 0, g.h - 1 do
    for x = 0, g.w - 1 do
      if g[y][x] == "." then
        for _, o in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
          local n = UI.get(g, x + o[1], y + o[2])
          if n ~= "." and n ~= c then
            add[#add + 1] = { x, y }
            break
          end
        end
      end
    end
  end
  for _, a in ipairs(add) do g[a[2]][a[1]] = c end
  return g
end

-- Metin satırlarından ızgara; her satır tam genişlikte olmalı
function UI.art(rows)
  local w = #rows[1]
  local g = UI.grid(w, #rows)
  for y, row in ipairs(rows) do
    assert(#row == w, "satır " .. y .. " genişliği " .. #row .. " (beklenen " .. w .. ")")
    for x = 1, w do g[y - 1][x - 1] = row:sub(x, x) end
  end
  return g
end

function UI.image(g, s)
  local img = Image(g.w * s, g.h * s, ColorMode.RGB)
  img:clear(Color { r = 0, g = 0, b = 0, a = 0 })
  for y = 0, g.h - 1 do
    for x = 0, g.w - 1 do
      local c = g[y][x]
      if c ~= "." then
        local col = hex(assert(UI.P[c], "palette: " .. c))
        for dy = 0, s - 1 do for dx = 0, s - 1 do img:drawPixel(x * s + dx, y * s + dy, col) end end
      end
    end
  end
  return img
end

-- tags: { { name, frames = { grid... }, ms } }, her tag sheet'te bir satır.
-- scales: sheet ölçekleri (1 = <ad>_sheet.png, 4 = <ad>_sheet_x4.png). GIF: tüm kareler 4x.
function UI.export(out, name, w, h, tags, scales)
  local spr = Sprite(w, h, ColorMode.RGB)
  spr.layers[1].name = name
  local n = 0
  for _, t in ipairs(tags) do
    local from = n + 1
    for _, g in ipairs(t.frames) do
      assert(g.w == w and g.h == h, t.name .. " boyutu")
      n = n + 1
      if n > 1 then spr:newEmptyFrame() end
      spr.frames[n].duration = t.ms / 1000
      spr:newCel(spr.layers[1], spr.frames[n], UI.image(g, 1), Point(0, 0))
    end
    local tag = spr:newTag(from, n)
    tag.name = t.name
  end
  spr:saveAs(out .. "/" .. name .. ".aseprite")

  local cols = 0
  for _, t in ipairs(tags) do cols = math.max(cols, #t.frames) end
  for _, s in ipairs(scales) do
    local img = Image(cols * w * s, #tags * h * s, ColorMode.RGB)
    img:clear(Color { r = 0, g = 0, b = 0, a = 0 })
    for row, t in ipairs(tags) do
      for i, g in ipairs(t.frames) do img:drawImage(UI.image(g, s), Point((i - 1) * w * s, (row - 1) * h * s)) end
    end
    img:saveAs(out .. "/" .. name .. "_sheet" .. (s == 1 and "" or "_x" .. s) .. ".png")
  end

  local frames, jtags, idx = {}, {}, 0
  for row, t in ipairs(tags) do
    local durs = {}
    for i = 1, #t.frames do
      frames[#frames + 1] = string.format('  {"filename":"%s_%d","frame":{"x":%d,"y":%d,"w":%d,"h":%d},"duration":%d}',
        t.name, i - 1, (i - 1) * w, (row - 1) * h, w, h, t.ms)
      durs[#durs + 1] = tostring(t.ms)
    end
    jtags[#jtags + 1] = string.format('  {"name":"%s","from":%d,"to":%d,"direction":"forward","row":%d,"durations":[%s]}',
      t.name, idx, idx + #t.frames - 1, row - 1, table.concat(durs, ","))
    idx = idx + #t.frames
  end
  local file = io.open(out .. "/" .. name .. "_sheet.json", "w")
  file:write('{"frames":[\n' .. table.concat(frames, ",\n") .. '\n],\n')
  file:write(string.format('"meta":{"app":"Aseprite","image":"%s_sheet.png","format":"RGBA8888","size":{"w":%d,"h":%d},"frameSize":{"w":%d,"h":%d},"layout":"one row per tag","frameTags":[\n',
    name, cols * w, #tags * h, w, h))
  file:write(table.concat(jtags, ",\n") .. '\n]}}\n')
  file:close()

  local gif = Sprite(w * 4, h * 4, ColorMode.RGB)
  local i = 0
  for _, t in ipairs(tags) do
    for _, g in ipairs(t.frames) do
      i = i + 1
      if i > 1 then gif:newEmptyFrame() end
      gif.frames[i].duration = math.max(t.ms, 100) / 1000
      gif:newCel(gif.layers[1], gif.frames[i], UI.image(g, 4), Point(0, 0))
    end
  end
  gif:saveAs(out .. "/" .. name .. ".gif")
end
