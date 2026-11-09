-- Test actual menu scripts against isolated game boundaries using Fengari.
-- Usage: lua check-menu.lua <rex-first|bike-first> <zrex.lua> <blood-burner.lua>
local order, rex, bike = arg[1], arg[2], arg[3]
assert(order == "rex-first" or order == "bike-first")
local total = 0
local function check(condition, message)
    assert(condition, message)
    total = total + 1
    print("PASS " .. message)
end

local mode, root, timer, buildCount
local refs = {"super_tesla_storm", "super_dark_flare", "super_dark_flare_13s",
              "super_dark_flare_shadow_ball", "super_healing_aura", "super_energy_mine"}
local bundles, rows, ids = {}, {}, {}
for i, ref in ipairs(refs) do
    bundles[ref] = {name = "stock_" .. ref, image = "icon:" .. ref, hudicon = "hud:" .. ref, custom = i}
    rows[i] = {ref = ref, lootID = 2700 + i, priority = i, index = i, superBundle = bundles[ref],
               isUnlocked = false, unlockRank = 44, isRestrictedFieldUpgradeEquipped = true}
    ids[ref] = i
end
xhash = function(s) return "#" .. s end
local decodedKeys = dofile(assert(arg[4], "Pass raw mode-key fixture"))(function() return mode end)
check(Game["fd36e3caf4f0d8db"] == nil and Game[xhash("fd36e3caf4f0d8db")] == nil,
      "plain hex and ordinary name hashes cannot reach the mode API")
LUI = {GetRoot = function() return root end, FlowManager = {RequestAddMenu = function() return "flow" end}}
local waiting = function() timer = {}; return timer end
local nested
MenuBuilder = { BuildRegisteredType = function(name)
    buildCount = (buildCount or 0) + 1
    if name == "outer" then
        local a, b, c = MenuBuilder.BuildRegisteredType("inner")
        nested = a == "inner" and b == nil and c == 17
        root = {Wait = waiting}
    end
    return name, nil, 17
end }

-- Both scripts initially load with no root/SUPER/LOOT. Early menu builds must recover.
if order == "bike-first" then dofile(bike); dofile(rex)
else dofile(rex); dofile(bike) end
check(timer == nil, "no timer scheduled against a missing UI root")
SUPER = {
    GetBundleByRef = function(ref) return bundles[ref] end,
    getindexforref = function(ref) return ids[ref] or 0 end,
    getbundlebyindex = function(index) if index == 0 then return bundles[refs[1]] end; return rows[index] and bundles[rows[index].ref] end,
    getallfieldupgrades = function() return rows end
}
LOOT = {getscriptbundleforref = function(_, ref) return bundles[ref] end,
    getitemid = function(ref) return ids[ref] and 2700 + ids[ref] end,
    IsUnlocked = function() return false end, isitembanned = function() return true end}
PROGRESSION = {IsUnlocked = function() return false end}
Restrictions = {IsSuperRestricted = function() return true end}
Engine = {Localize = function(k) return "stock:" .. k end,
    LocalizeToUpper = function(k) return "upper:" .. k end}
mode = 1
local a,b,c = MenuBuilder.BuildRegisteredType("outer")
check(nested and buildCount == 2 and a == "outer" and b == nil and c == 17, "reentrant menu and nil middle return preserved")
check(timer and type(timer.onComplete) == "function", "builder discovers new root; retry pump scheduled outside Zombies")
check(SUPER.getallfieldupgrades() == rows and Engine.Localize("owner_zrex_field_upgrade_name") == "stock:owner_zrex_field_upgrade_name", "Multiplayer untouched")

mode = 2
timer.onComplete()
check(decodedKeys(), "all three raw mode IDs decoded")
local shadowIndex = ids[refs[4]]
ids[refs[4]] = nil
check(SUPER.getbundlebyindex(0) == bundles[refs[1]], "missing augment lookup never takes the zero-index stock bundle")
ids[refs[4]] = shadowIndex
local wrappers = {SUPER.GetBundleByRef, SUPER.getallfieldupgrades, MenuBuilder.BuildRegisteredType}
for i = 1, 20 do OwnerZRexMenu.refresh() end
check(SUPER.GetBundleByRef == wrappers[1] and SUPER.getallfieldupgrades == wrappers[2] and MenuBuilder.BuildRegisteredType == wrappers[3], "twenty refreshes do not wrap hooks repeatedly")
local result = SUPER.getallfieldupgrades()
check(result ~= rows and #result == #rows, "copied Zombies list preserves row count")
for i = 2, 4 do
    local ref, row, stock = refs[i], result[i], rows[i]
    check(row ~= stock and row.ref == ref and row.lootID == stock.lootID and row.index == stock.index and row.priority == stock.priority, ref .. " retains native identity and position")
    check(row.isUnlocked and row.unlockRank == 0 and not row.isRestrictedFieldUpgradeEquipped and not stock.isUnlocked and stock.superBundle == bundles[ref], ref .. " copy gets unlock flags, source stays intact")
    local view = SUPER.GetBundleByRef(ref)
    check(view.name == "owner_zrex_field_upgrade_name" and view.image == bundles[ref].image and view.hudicon == bundles[ref].hudicon, ref .. " title overridden and stock icons retained")
    check(SUPER.getbundlebyindex(i).name == view.name and LOOT.getscriptbundleforref("fu",ref).name == view.name, ref .. " ref/index/loot presentation agrees")
    check(PROGRESSION.IsUnlocked(1, stock.lootID) and not Restrictions.IsSuperRestricted(ref), ref .. " allowed by stock ref and loot ID")
end
check(Engine.Localize("owner_zrex_field_upgrade_name") == "ALLY -FieldUpgrade" and Engine.Localize("owner_zrex_field_upgrade_description"):find("240 seconds",1,true) and Engine.Localize("owner_zrex_field_upgrade_description"):find("Uber Klaus",1,true), "requested display name identifies the timed ally")
check(Engine.Localize("stock_dark_flare") == "stock:stock_dark_flare", "stock Dark Flare localization key untouched")
check(SUPER.GetBundleByRef(refs[1]) == bundles[refs[1]] and SUPER.GetBundleByRef(refs[6]) == bundles[refs[6]], "Tesla Storm and Energy Mine unchanged")
check(SUPER.GetBundleByRef(refs[5]).name == "VEHICLES/BLOOD_BURNER", "Healing Aura still routes to Blood Burner's bundle")
mode = nil
check(SUPER.getallfieldupgrades() == rows and not rows[2].isUnlocked and rows[2].superBundle == bundles[refs[2]], "unknown mode restores original Dark Flare list")
check(result[2].superBundle.name == bundles[refs[2]].name and not LOOT.IsUnlocked(2702), "cached proxy and progression fail closed in unknown mode")
print("ALL MENU CHECKS PASSED " .. order .. " " .. total)
