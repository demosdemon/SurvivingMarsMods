local max_PodAmount = 1000
local max_RefilAmount = 4000

local properties = {
    PlaceObj("ModItemOptionToggle", {
        "name", "Debug",
        "DisplayName", "Enable Debug Logging",
        "DefaultValue", false,
    }),
    PlaceObj("ModItemOptionToggle", {
        "name", "Enabled",
        "DisplayName", "Enable Automatic Supply Pods",
        "DefaultValue", true,
    }),
    PlaceObj("ModItemOptionToggle", {
        "name", "SkipDayOne",
        "DisplayName", "Skip Resupply on Sol 1",
        "DefaultValue", true,
    }),
    PlaceObj("ModItemOptionNumber", {
        "name", "MaxPodAmount",
        "DisplayName", "Max Pod Amount",
        "DefaultValue", max_PodAmount,
        "MinValue", 1,
        "MaxValue", max_PodAmount,
    }),
}

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

for id, item in pairs(Resources) do
    if table.find(storable_resources, id) then
        properties[#properties + 1] = PlaceObj("ModItemOptionToggle", {
            "name", id .. "Enable",
            "DisplayName", table.concat(T(754117323318, "Enable") .. " " .. T(item.display_name)),
            "DefaultValue", true,
        })
        properties[#properties + 1] = PlaceObj("ModItemOptionNumber", {
            "name", id .. "Threshold",
            "DisplayName", table.concat(T(item.display_name) .. " " .. T(754117323318 + 100, "Threshold Amount")),
            "DefaultValue", 80,
            "MinValue", 0,
            "MaxValue", max_RefilAmount,
        })
        properties[#properties + 1] = PlaceObj("ModItemOptionNumber", {
            "name", id .. "Refil",
            "DisplayName", table.concat(T(item.display_name) .. " " .. T(754117323318 + 200, "Refil Amount")),
            "DefaultValue", 180,
            "MinValue", 0,
            "MaxValue", max_RefilAmount,
        })
    end
end

return properties
