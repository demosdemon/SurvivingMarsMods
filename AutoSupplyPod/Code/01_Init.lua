function SpawnSupplyPodInOrbit(cargo)
    local sponsor = GetMissionSponsor()
    local class = sponsor.pod_class
    local pod = PlaceBuilding(class, {city = UICity})
    
    pod.cargo = cargo
    pod.name = GenerateRocketName()
    pod:SetCommand("WaitInOrbit")
    
    return pod
end

local storable_resources = {
    "Metals",
    "Concrete",
    "Food",
    "PreciousMetals",
    "Polymers",
    "MachineParts",
    "Fuel",
    "Electronics",
    "WasteRock",
    "Seeds",
}

local mod_Debug = true
local mod_Enabled = false
local mod_SkipDayOne = false
local mod_MaxPodAmount = false
local mod_SupplyPodThread = false
local mod_options = {}

local function Log(msg)
    if mod_Debug then
        print("[AutoSupplyPod] " .. msg)
    end
end

local function ModOptions()
    options = CurrentModOptions
    mod_Debug = options:GetProperty("Debug")
    mod_Enabled = options:GetProperty("Enabled")
    mod_SkipDayOne = options:GetProperty("SkipDayOne")
    mod_SupplyPodCargoLimit = options:GetProperty("MaxPodAmount")
    
    for i = 1, #storable_resources do
        local id = storable_resources[i]
        mod_options[id] = {
            enabled = options:GetProperty(id .. "Enable"),
            threshold = options:GetProperty(id .. "Threshold"),
            refil = options:GetProperty(id .. "Refil"),
        }
    end
end

function OnMsg.ModsReloaded()
    Log("Begin ModsReloaded")
    ModOptions()
    Log("End ModsReloaded")
end

function OnMsg.ApplyModOptions(id)
    Log("Begin ApplyModOptions")
    if id ~= CurrentModId then
        Log("id <> CurrentModId")
        return
    end
    
    ModOptions()
    Log("End ApplyModOptions")
end

function GetResourceDemand(options)
    Log("Begin GetResourceDemand")
    options = options or mod_options
    colony_supplies = {}
    GatherResourceOverviewData(colony_supplies)
    
    local result = {}
    
    for i = 1, #storable_resources do
        local id = storable_resources[i]
        local opts = options[id]
        if opts and opts.enabled then
            local supply = colony_supplies[id] or 0
            Log("Resource: " .. id .. ", Supply: " .. supply .. ", Threshold: " .. opts.threshold .. ", Refil: " .. opts.refil)
            if supply <= (opts.threshold * const.ResourceScale) then
                result[#result + 1] = {class = id, amount = opts.refil}
            end
        end
    end
    
    Log("End GetResourceDemand")
    return result
end

function SupplyPodRefil(options)
    if mod_SupplyPodThread then
        Log("SupplyPodThread already in progress")
        return
    end
    
    mod_SupplyPodThread = CreateGameTimeThread(function(options)
        local demand = GetResourceDemand(options)
        
        local cargo = {}
        local cargo_amt = 0
        local reload = function()
            Sleep(5000)
            -- TODO: Dispatch Notification
            SpawnSupplyPodInOrbit(cargo)
            cargo = {}
            cargo_amt = 0
        end
        
        for idx = 1, #demand do
            local item = demand[idx]
            while item.amount > 0 do
                if (cargo_amt + item.amount) > mod_MaxPodAmount then
                    local amt = mod_MaxPodAmount - cargo_amt
                    item.amount = item.amount - amt
                    cargo[#cargo + 1] = {class = item.class, amount = amt}
                    reload()
                else
                    cargo_amt = cargo_amt + item.amount
                    cargo[#cargo + 1] = {class = item.class, amount = item.amount}
                    item.amount = 0
                end
            end
        end
        
        if #cargo > 0 then
            reload()
        end
        
        mod_SupplyPodThread = false
    end, options or mod_options)

end

function OnMsg.NewDay(day)
    if not mod_Enabled then
        return
    end

    if day == 1 and mod_SkipDayOne then
        Log("Skipping resupply on first day.")
        return
    end

    SupplyPodRefil()
end
