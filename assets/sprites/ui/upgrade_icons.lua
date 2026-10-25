-- Market kategori ve geliştirme ikonları (16x16). Sıra upgrades.gd ICONS ile aynı.
-- Çalıştırma: aseprite -b --script-param out=<klasör> --script upgrade_icons.lua

local OUT = app.params["out"]
dofile(OUT .. "/ui_common.lua")

local S = 16

-- Merkezden uzaklığa göre halka (açı: yukarıdan saat yönünde derece)
local function ring(g, r0, r1, c, keep)
  for y = 0, S - 1 do
    for x = 0, S - 1 do
      local dx, dy = x + 0.5 - 8, y + 0.5 - 8
      local d = math.sqrt(dx * dx + dy * dy)
      local a = (math.deg(math.atan(dx, -dy)) + 360) % 360
      if d >= r0 and d <= r1 and (keep == nil or keep(a)) then g[y][x] = c end
    end
  end
end

-- Çapraz ışın kılıcı: sağ üstten sol alta bıçak, sol altta sap
local function diagonal_saber(g, len)
  for t = 0, len do
    UI.set(g, 12 - t, 3 + t, "w")
    UI.set(g, 13 - t, 3 + t, "p")
    UI.set(g, 12 - t, 2 + t, "P")
  end
  local hx, hy = 12 - len, 3 + len
  for t = 1, 3 do
    UI.set(g, hx - t, hy + t, "S")
    UI.set(g, hx - t + 1, hy + t, "s")
  end
  UI.set(g, hx, hy + 1, "S")
  UI.set(g, hx - 1, hy, "S")
  return g
end

local ICONS = {}

ICONS.karakter = UI.art({
  "................",
  ".....kkkkkk.....",
  "....kGGGGGGk....",
  "...kGgGGGGGGk...",
  "...kGGGGGGGGk...",
  "..kkkkkkkkkkkk..",
  "...knnnnnnnnk...",
  "...knkknnkknk...",
  "...knnnnnnnnk...",
  "...knnnRRnnnk...",
  "....knnnnnnk....",
  ".....kkkkkk.....",
  "....kGGGGGGk....",
  "...kGgGGGGGGk...",
  "...kGGGGGGGGk...",
  "...kkkkkkkkkk...",
})

ICONS.tabanca = UI.art({
  "................",
  "................",
  "..kkkkkkkkkkkkk.",
  ".kSssssssssssSk.",
  ".kSSSSSSSSSSSSk.",
  ".kkkkkSSkkkkkkk.",
  "....kSSkSk......",
  "....kSSkkk......",
  "...kSSSk........",
  "...kSSk.........",
  "..kSSSk.........",
  "..kNNNk.........",
  "..kkkkk.........",
  "................",
  "................",
  "................",
})

ICONS.isin_kilici = UI.outline(diagonal_saber(UI.grid(S, S), 8), "k")

ICONS.hiz = UI.art({
  "................",
  "................",
  "................",
  "..kk.....kk.....",
  "..kbk....kbk....",
  "...kbk....kbk...",
  "....kbk....kbk..",
  ".....kbk....kbk.",
  ".....kBk....kBk.",
  "....kBk....kBk..",
  "...kBk....kBk...",
  "..kBk....kBk....",
  "..kk.....kk.....",
  "................",
  "................",
  "................",
})

ICONS.can = UI.art({
  "................",
  "..kkk..kkk......",
  ".krrrkkrrrk.....",
  "krwrrrrrrrrk....",
  "krwrrrrrrrrk....",
  "krrrrrrrrrRk....",
  ".krrrrrrrRk.....",
  "..krrrrrRk......",
  "...krrrRk.......",
  "....krRk...kkk..",
  ".....kk....kyk..",
  ".........kkkykkk",
  ".........kyyyyyk",
  ".........kkkykkk",
  "...........kyk..",
  "...........kkk..",
})

ICONS.yaricap = UI.art({
  "................",
  ".....bbbbbb.....",
  "...bb......bb...",
  "..b..........b..",
  ".b....kkkk....b.",
  ".b...kyyyyk...b.",
  "b...kyywyyok...b",
  "b...kyyyyyok...b",
  "b...kyyyyyok...b",
  "b...kyyyyook...b",
  ".b...kooook...b.",
  ".b....kkkk....b.",
  "..b..........b..",
  "...bb......bb...",
  ".....bbbbbb.....",
  "................",
})

ICONS.kalp = UI.art({
  "................",
  "..kkkk....kkkk..",
  ".krrrrk..krrrrk.",
  "krrwwrrkkrrrrrrk",
  "krwwrrrrrrrrrrrk",
  "krwrrrrrrrrrrrrk",
  "krrrrrrrrrrrrrRk",
  ".krrrrrrrrrrrRk.",
  "..krrrrrrrrrRk..",
  "...krrrrrrrRk...",
  "....krrrrrRk....",
  ".....krrrRk.....",
  "......krRk......",
  ".......kk.......",
  "................",
  "................",
})

ICONS.dash = UI.art({
  "................",
  "................",
  "................",
  ".........kk.....",
  ".........kbk....",
  ".SSSS....kbbk...",
  "......kkkkbbbk..",
  "SSSS..kbbbbbbbk.",
  "......kbbbbbbbbk",
  "SSSS..kBBBBBBBk.",
  "......kkkkBBBk..",
  ".SSSS....kBBk...",
  ".........kBk....",
  ".........kk.....",
  "................",
  "................",
})

ICONS.atis_hizi = UI.art({
  "................",
  "......kkkk......",
  ".......kk.......",
  ".....kkkkkk.....",
  "...kkwwwwwwkk...",
  "..kwwwwkwwwwwk..",
  "..kwwwwkwwwwwk..",
  ".kwwwwwkwwwwwwk.",
  ".kwwwwwkkkkwwwk.",
  ".kwwwwwwwwwwwwk.",
  ".kwwwwwwwwwwwwk.",
  "..kwwwwwwwwwwk..",
  "..kswwwwwwwwsk..",
  "...kkswwwwskk...",
  ".....kkkkkk.....",
  "................",
})

ICONS.mermi_adedi = UI.art({
  "................",
  "................",
  "..kk...kk...kk..",
  ".kyyk.kyyk.kyyk.",
  ".kyyk.kyyk.kyyk.",
  ".kkkk.kkkk.kkkk.",
  ".kook.kook.kook.",
  ".kook.kook.kook.",
  ".kook.kook.kook.",
  ".kook.kook.kook.",
  ".kook.kook.kook.",
  ".kOOk.kOOk.kOOk.",
  ".kOOk.kOOk.kOOk.",
  ".kkkk.kkkk.kkkk.",
  "................",
  "................",
})

ICONS.mermi_hizi = UI.art({
  "................",
  "................",
  "................",
  "................",
  "................",
  "......kkkkkkk...",
  "SSS..kooooyyyk..",
  ".....kooooyyyyk.",
  "SSSS.kOOOOooook.",
  "SSS..kOOOOoook..",
  "......kkkkkkk...",
  "................",
  "................",
  "................",
  "................",
  "................",
})

ICONS.mermi_boyutu = UI.art({
  "................",
  ".........kkkk...",
  "........kyyyyk..",
  ".......kyyyyyyk.",
  ".......kyyyyyyk.",
  ".......kkkkkkkk.",
  ".kk....kooooook.",
  "kyyk...kooooook.",
  "kyyk...kooooook.",
  "kkkk...kooooook.",
  "kook...kooooook.",
  "kook...kOOOOOOk.",
  "kOOk...kOOOOOOk.",
  "kkkk...kkkkkkkk.",
  "................",
  "................",
})

ICONS.kilic_adedi = UI.art({
  "...kk......kk...",
  "..kpwk....kpwk..",
  "..kpwk....kpwk..",
  "..kpwk....kpwk..",
  "..kpwk....kpwk..",
  "..kpwk....kpwk..",
  "..kpwk....kpwk..",
  "..kpwk....kpwk..",
  "..kPwk....kPwk..",
  "..kPwk....kPwk..",
  ".kkkkkk..kkkkkk.",
  "..kSSk....kSSk..",
  "..kssk....kssk..",
  "..kSSk....kSSk..",
  "..kkkk....kkkk..",
  "................",
})

-- Dairesel ok: sağ üstte boşluk, ok başı boşluğa doğru
local spin = UI.grid(S, S)
ring(spin, 4.2, 6.2, "P", function(a) return a > 60 end)
for _, p in ipairs({ { 12, 1 }, { 11, 2 }, { 12, 2 }, { 13, 2 }, { 10, 3 }, { 11, 3 }, { 12, 3 }, { 13, 3 }, { 14, 3 } }) do
  UI.set(spin, p[1], p[2], "p")
end
ICONS.donus_hizi = UI.outline(spin, "k")

-- Büyük kılıç + köşelerde büyütme işaretleri
local big = diagonal_saber(UI.grid(S, S), 8)
for _, p in ipairs({ { 0, 0 }, { 1, 0 }, { 2, 0 }, { 0, 1 }, { 0, 2 }, { 15, 15 }, { 14, 15 }, { 13, 15 }, { 15, 14 }, { 15, 13 } }) do
  UI.set(big, p[1], p[2], "y")
end
ICONS.kilic_boyutu = UI.outline(big, "k")

-- Yörünge: ortada oyuncu, kesikli halka, halkada kılıç ucu
local orbit = UI.grid(S, S)
ring(orbit, 5.6, 6.8, "b", function(a) return math.floor(a / 30) % 2 == 0 end)
UI.rect(orbit, 7, 7, 2, 2, "n")
UI.rect(orbit, 11, 2, 2, 2, "p")
ICONS.yorunge = UI.outline(orbit, "k")

local ORDER = {
  "karakter", "tabanca", "isin_kilici",
  "hiz", "can", "yaricap", "kalp", "dash",
  "atis_hizi", "mermi_adedi", "mermi_hizi", "mermi_boyutu",
  "kilic_adedi", "donus_hizi", "kilic_boyutu", "yorunge",
}

-- Tek satır: her ikon kendi tag'i değil, "icons" tag'inin bir karesi (JSON'da icons_<i>)
local frames = {}
for _, id in ipairs(ORDER) do frames[#frames + 1] = assert(ICONS[id], id) end
UI.export(OUT, "upgrade_icons", S, S, { { name = "icons", frames = frames, ms = 400 } }, { 1 })
