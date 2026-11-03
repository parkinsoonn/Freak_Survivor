-- Oyuncunun etrafındaki bariyer kalkanı (64x64, 8 kare döngü): mavi halka, halkada dönen iki parlama,
-- içte altıgen nokta deseni, sol üstte cam parlaması ve yanıp sönen kıvılcımlar.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script barrier_shield.lua

local OUT = app.params["out"]
dofile(OUT .. "/../ui/ui_common.lua")

local S, C, R, FRAMES = 64, 32, 26, 8

-- 0 = yukarı, saat yönünde derece
local function polar(x, y)
  local dx, dy = x + 0.5 - C, y + 0.5 - C
  return math.sqrt(dx * dx + dy * dy), (math.deg(math.atan(dx, -dy)) + 360) % 360
end

local function angle_diff(a, b)
  local d = math.abs(a - b) % 360
  return math.min(d, 360 - d)
end

local function spark(g, x, y, c)
  UI.set(g, x, y, "w")
  for _, o in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do UI.set(g, x + o[1], y + o[2], c) end
end

local frames = {}
for f = 0, FRAMES - 1 do
  local g = UI.grid(S, S)
  local spin = f * 360 / FRAMES
  for y = 0, S - 1 do
    for x = 0, S - 1 do
      local d, a = polar(x, y)
      if d >= R - 0.5 and d < R + 1.1 then
        -- Halkada karşılıklı iki parlama döner
        local near = math.min(angle_diff(a, spin), angle_diff(a, spin + 180))
        g[y][x] = near < 18 and "w" or (near < 40 and "c" or "b")
      elseif d >= R - 1.5 and d < R - 0.5 then
        g[y][x] = "B"
      elseif d < R - 3 and y % 6 == 0 and (x + (y / 6 % 2) * 3) % 6 == 0 then
        -- Seyrek altıgen nokta deseni (oyuncu görünsün), her karede bir satır yanar
        g[y][x] = (y / 6 + f) % 4 == 0 and "b" or "B"
      elseif d >= R - 4.5 and d < R - 3.5 and a > 292 and a < 335 then
        g[y][x] = "w"
      end
    end
  end

  -- İçte yanıp sönen kıvılcımlar: her karede farklı açı ve uzaklık
  for i = 0, 2 do
    local a = math.rad(f * 37 + i * 120 + 15)
    local r = R - 7 - ((f + i * 3) % 4) * 3
    spark(g, math.floor(C + math.sin(a) * r), math.floor(C - math.cos(a) * r), (f + i) % 2 == 0 and "b" or "c")
  end
  frames[#frames + 1] = g
end

UI.export(OUT, "barrier_shield", S, S, { { name = "shield", frames = frames, ms = 80 } }, { 1 })
