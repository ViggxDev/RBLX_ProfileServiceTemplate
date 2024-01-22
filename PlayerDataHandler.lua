local PlayerDataHandler = {}

local dataTemplate = {
    Coins = 0,
    Level = 1,
    xp = 0,
    xpReq = 1000
}

local ProfileService = require(script.Parent.ProfileService)
local plrs = game:GetService("Players")

local ProfileStore = ProfileService.GetProfileStore(
    "PlayerProfile",
    dataTemplate
)

local Profiles = {}

local function getProfile(plr)
    if plr == nil then return end
    assert(Profiles[plr], string.format("Profile does not exist for %s", plr.UserId))

    return Profiles[plr]
end

function createLeaderstats(plr)
    local profile = getProfile(plr)

    -- Set up leaderstats
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = plr

    local coinsStat = Instance.new("IntValue")
    coinsStat.Name = "Coins"
    coinsStat.Value = profile.Data.Coins
    coinsStat.Parent = leaderstats

    local levelStat = Instance.new("IntValue")
    levelStat.Name = "Level"
    levelStat.Value = profile.Data.Level
    levelStat.Parent = leaderstats
end

function updateLeaderstats(plr)
    print("Updated leaderstats")

    local profile = getProfile(plr)

    local leaderstats = plr:FindFirstChild("leaderstats")
    local coins = leaderstats:FindFirstChild("Coins")
    local levels = leaderstats:FindFirstChild("Level")

    coins.Value = profile.Data.Coins
    levels.Value = profile.Data.Level
end

local function playerAdded(plr)
    local profile = ProfileStore:LoadProfileAsync("Player_"..plr.UserId)

    if profile then
        profile:AddUserId(plr.UserId)
        profile:Reconcile()

        profile:ListenToRelease(function()
            profile[plr] = nil

            plr:Kick()
        end)

        if not plr:IsDescendantOf(plrs) then
            profile:Release()
        else
            Profiles[plr] = profile

            createLeaderstats(plr)
        end
    else
        plr:Kick();
    end
end

function PlayerDataHandler:Init()
    for _, plr in plrs:GetPlayers() do
        task.spawn(playerAdded, plr)
    end

    game.Players.PlayerAdded:Connect(playerAdded)

    game.Players.PlayerRemoving:Connect(function(plr)
        if Profiles[plr] then
            Profiles[plr]:Release()
        end
    end)
end

function PlayerDataHandler:Get(plr, key)
    local profile = getProfile(plr)
    assert(profile.Data[key], string.format("Data does not exist for key: %s", key))

    return profile.Data[key]
end

function PlayerDataHandler:Set(plr, key, value)
    local profile = getProfile(plr)
    assert(profile.Data[key], string.format("Data does not exist for key: %s", key))

    assert(type(profile.Data[key]) == type(value))

    profile.Data[key] = value

    updateLeaderstats(plr)
end

function PlayerDataHandler:Update(plr, key, callback)
    local profile = getProfile(plr)

    local oldData = self:Get(plr, key)
    local newData = callback(oldData)

    self:Set(plr, key, newData)

    updateLeaderstats(plr)
end

return PlayerDataHandler
