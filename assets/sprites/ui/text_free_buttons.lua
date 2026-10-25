-- Yazılı buton resimlerinin yazısız kopyaları (yazı Godot'ta çevrilebilir Label olarak gelir).
-- Saf beyaz yazı pikselleri, o satırda butonda en sık görülen renkle (gövde rengi) doldurulur.
-- Çıktı: <ad>_blank.png (kaynakla aynı boyut ve bölgeler, atlas region'ları değişmez).
-- Çalıştırma: aseprite -b --script-param out=<ui klasörü> --script text_free_buttons.lua

local OUT = app.params["out"]
local SRC = OUT .. "/.."
local NAMES = { "QUIT_PLAY", "MENU_RESUME", "TRY_AGAIN" }

local pc = app.pixelColor

local function is_white(p)
  return pc.rgbaA(p) > 0 and pc.rgbaR(p) == 255 and pc.rgbaG(p) == 255 and pc.rgbaB(p) == 255
end

for _, name in ipairs(NAMES) do
  local img = Image { fromFile = SRC .. "/" .. name .. ".png" }
  for y = 0, img.height - 1 do
    -- Satırdaki beyaz olmayan opak piksellerin en sık rengi
    local counts, best, best_n = {}, nil, 0
    for x = 0, img.width - 1 do
      local p = img:getPixel(x, y)
      if pc.rgbaA(p) > 0 and not is_white(p) then
        counts[p] = (counts[p] or 0) + 1
        if counts[p] > best_n then best, best_n = p, counts[p] end
      end
    end
    if best then
      for x = 0, img.width - 1 do
        if is_white(img:getPixel(x, y)) then img:drawPixel(x, y, best) end
      end
    end
  end
  img:saveAs(OUT .. "/" .. name .. "_blank.png")
end
