local HttpService = game:GetService('HttpService')

local TargetScrapedDirectory = "scraped-assets.txt"

local Assets = readfile(TargetScrapedDirectory):split('\n')
local Accessories = {}

for i,v in pairs(Assets) do
    pcall(function()
        table.insert(Accessories, HttpService:JSONDecode(v))
    end)
end

for _,Accessory in pairs(Accessories) do
    if Accessory.HandleColor:lower():find('white') then
        print(Accessory.CatalogName)
    end
end
