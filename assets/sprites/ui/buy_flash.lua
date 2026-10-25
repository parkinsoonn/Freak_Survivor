-- Satın alma parlaması (32x32, 6 kare): ortadan genişleyen halka ve ışınlar.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script buy_flash.lua

local OUT = app.params["out"]
dofile(OUT .. "/ui_common.lua")

local S = 32

-- sparse: halkada her kaçıncı 30 derecelik dilim dolu (1 = hepsi)
local function ring(g, r, c, sparse)
  for y = 0, S - 1 do
    for x = 0, S - 1 do
      local dx, dy = x + 0.5 - 16, y + 0.5 - 16
      local d = math.sqrt(dx * dx + dy * dy)
      local slice = math.floor((math.deg(math.atan(dx, -dy)) + 360) % 360 / 30)
      if d >= r - 0.5 and d < r + 0.6 and slice % sparse == 0 then g[y][x] = c end
    end
  end
end

-- Dört yöne ışın: from..to arası
local function rays(g, from, to, c)
  for t = from, to do
    for _, o in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
      UI.set(g, 16 + o[1] * t - (o[1] < 0 and 1 or 0), 16 + o[2] * t - (o[2] < 0 and 1 or 0), c)
    end
  end
end

local frames = {}
local f = UI.grid(S, S)
UI.rect(f, 15, 15, 2, 2, "w")
rays(f, 1, 3, "c")
frames[1] = f

f = UI.grid(S, S)
ring(f, 4, "w", 1)
rays(f, 2, 7, "y")
frames[2] = f

f = UI.grid(S, S)
ring(f, 7, "c", 1)
ring(f, 6, "y", 1)
rays(f, 5, 11, "y")
frames[3] = f

f = UI.grid(S, S)
ring(f, 10, "y", 1)
rays(f, 9, 13, "o")
frames[4] = f

f = UI.grid(S, S)
ring(f, 12, "o", 2)
rays(f, 12, 14, "o")
frames[5] = f

f = UI.grid(S, S)
ring(f, 14, "O", 3)
frames[6] = f

UI.export(OUT, "buy_flash", S, S, { { name = "flash", frames = frames, ms = 50 } }, { 1 })
