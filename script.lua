local HttpService = game:GetService('HttpService')
local RunService = game:GetService('RunService')

RunService:Set3dRenderingEnabled(false) -- Optional

local TargetScrapedDirectory = "scraped-assets.txt"
local ConsoleTitle = "ROBLOX Catalog Accessory Scraper - Vapin' Cat#5497"

if not isfile(TargetScrapedDirectory) then
    writefile(TargetScrapedDirectory, "")
end

local RequestCatalogUrl = "https://catalog.roblox.com/v1/search/items/details"
local EnglishWordList = "https://raw.githubusercontent.com/VapingCat/ROBLOX-Accessory-Scraper/main/words.json"

local WordList = HttpService:JSONDecode(syn.request({
    Url = EnglishWordList, 
    Method = "GET"
}).Body)

local RatelimitTimeoutDuration = 30
local RetrieveAccessoryObjectDelay = 1/30

local ScrapedCount = 0

rconsoleclear()

local function UpdateConsoleTitle()
    rconsolename(ConsoleTitle..(' [%d]'):format(ScrapedCount))
end

local rconsole = setmetatable({}, {
    __index = function(self, index)
        local Color = ("@@%s@@"):format(index:upper())
        
        return function(...)
            local Chunks = {}
            
            for _,v in pairs({...}) do
                table.insert(Chunks, tostring(v))
            end
            
            rconsoleprint(Color)
            rconsoleprint(table.concat(Chunks, ' '))
        end
    end
})

rconsole.light_green(('All Scraped Accessories Are Saved to `%s`\n'):format(TargetScrapedDirectory))

while true do
    local Cursor = ""
    
    local Keyword = WordList[math.random(1, #WordList)]
    local KeywordQuery = "&keyword="..Keyword
    
    rconsole.cyan(('Searching keyword `%s`..\n'):format(Keyword))
    
    while Cursor do
        local CursorQuery = Cursor == "" and "" or "&cursor="..Cursor
        local SortQuery = "?category=11&subcategory=19&limit=30"
        
        local Url = RequestCatalogUrl..SortQuery..CursorQuery..KeywordQuery
        local Response = syn.request({Url = Url, Method = "GET"})
        
        if Response.StatusCode == 429 then
            rconsole.red(('Ratelimited. Timing out for %d seconds.\n'):format(RatelimitTimeoutDuration))
            
            task.wait(RatelimitTimeoutDuration)
            continue
        elseif not Response.Success then
            rconsole.red('Unknown error occurred.\n')
        end
        
        local Data = HttpService:JSONDecode(Response.Body)
        Cursor = Data['nextPageCursor']
        
        for _,Asset in pairs(Data['data'] or {}) do
            local Success, Accessory = pcall(function()
                return game:GetObjects('rbxassetid://'..Asset['id'])[1]
            end)
            
            if not Success then continue end
            
            rconsole.dark_gray(Asset['id']..' ')
            
            if (Asset['creatorTargetId'] or 1) == 1 then
                rconsole.light_blue('ROBLOX ')
            end
            
            if (Asset['price'] or 0) <= 0 then
                rconsole.light_green('FREE ')
            end
            
            rconsole.white('- '..Asset['name']..'\n')
            
            local Handle = Accessory:FindFirstChild('Handle')
            
            local Success, HatData = pcall(function()
                return {
                    CreatedBy = Asset['creatorTargetId'],
                    CatalogId = Asset['id'],
                    CatalogName = Asset['name'],
                    CatalogPrice = Asset['price'],
                    AccessoryName = Accessory.Name
                }
            end)
            
            HatData = Success and HatData or {}
            
            if Handle then
                local Sound = Handle:FindFirstChildOfClass('Sound')
                local Particles = Handle:FindFirstChildOfClass('ParticleEmitter')
                
                local Success, AdditionalHatData = pcall(function()
                    return {
                        HandleSize = {Handle.Size.X, Handle.Size.Y, Handle.Size.Z},
                        HandleColor = Handle.BrickColor.Name,
                        HandleShape = Handle.Shape.Name,
                        HandleMaterial = Handle.Material.Name,
                        HandleTransparency = Handle.Transparency,
                        HandleReflectance = Handle.Reflectance,
                        ContainsSound = Sound ~= nil and Sound.SoundId,
                        ContainsParticles = Particles ~= nil and Particles.Texture
                    }
                end)
                
                for i, v in pairs(Success and AdditionalHatData or {}) do
                    HatData[i] = v
                end
            end
            
            local EncodedHatData = HttpService:JSONEncode(HatData)
            appendfile(TargetScrapedDirectory, EncodedHatData..'\n')
            
            ScrapedCount = ScrapedCount + 1
            UpdateConsoleTitle()
            
            Accessory:Destroy()
            task.wait(RetrieveAccessoryObjectDelay)
        end
    end
end
