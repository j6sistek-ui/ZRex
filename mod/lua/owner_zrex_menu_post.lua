-- Ally validation prototype: presentation for the existing Dark Flare slot.
-- Stock item identity, icon and loadout storage are intentionally inherited.
local previous = rawget(_G, "OwnerZRexMenu")
if type(previous) == "table" and type(previous.refresh) == "function" then
    previous.refresh()
    return
end

local state = { enabled = true }
rawset(_G, "OwnerZRexMenu", state)

local refs = { "super_dark_flare", "super_dark_flare_13s", "super_dark_flare_shadow_ball" }
local nameKey = "owner_zrex_field_upgrade_name"
local descriptionKey = "owner_zrex_field_upgrade_description"
local title = "ALLY -FieldUpgrade"
local description = "Summon one ally for up to 240 seconds. Defaults to Uber Klaus for testing. Requires locally available creature assets and open ground."
local hashes, lootIds, indexes = {}, {}, {}
local hooked = setmetatable({}, { __mode = "k" })
local proxies = setmetatable({}, { __mode = "kv" })
local isProxy = setmetatable({}, { __mode = "k" })
local listBundles = setmetatable({}, { __mode = "k" })

local function hash(name)
    if hashes[name] ~= nil then return hashes[name] end
    local clua = rawget(_G, "CLUA")
    local fn = rawget(_G, "xhash") or rawget(_G, "PushXHash") or (clua and clua.PushXHash)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, name)
    if ok and value ~= nil then hashes[name] = value; return value end
end

local function read(object, key)
    if object == nil then return nil end
    local ok, value = pcall(function() return object[key] end)
    if ok and value ~= nil then return value end
    local id = hash(key)
    if id ~= nil and id ~= key then
        ok, value = pcall(function() return object[id] end)
        if ok then return value end
    end
end

local function matches(value, name)
    return value ~= nil and (value == name or value == hash(name))
end

local function darkFlare(value)
    if value == nil then return false end
    for _, ref in ipairs(refs) do
        if matches(value, ref) then return true end
    end
    return false
end

-- The game's Game/Enum methods are raw 64-bit literals, not hashes of their hex text.
-- This fixed, one-constant chunk matches the shipped bo6_zombie_builds_post.lua H codec.
local modeKeys = {}
local function modeKey(hex)
    if modeKeys[hex] ~= nil then return modeKeys[hex] end
    local bytes = {}
    for i = 16, 2, -2 do
        bytes[#bytes + 1] = string.char(tonumber(hex:sub(i - 1, i), 16))
    end
    local header = string.char(27, 76, 74, 132, 26, 25)
    local body = string.char(0, 0, 2, 0, 1, 0, 2, 40, 0, 0, 0, 77, 0, 2, 0, 4, 0)
    local getter = load(header .. body .. table.concat(bytes) .. string.char(0))
    if getter then modeKeys[hex] = getter() end
    return modeKeys[hex]
end

local function zombiesContext()
    local mode = rawget(_G, "Game")[modeKey("fd36e3caf4f0d8db")]()
    local modes = rawget(_G, "Enum")[modeKey("aac7e3ce067d9a9f")]
    local zombies = modes[modeKey("08f73707b5922e00")]
    return mode ~= nil and zombies ~= nil and mode == zombies
end

local function active()
    if not state.enabled then return false end
    local ok, result = pcall(zombiesContext)
    return ok and result == true
end

-- Hook by either spelling without rewrapping another mod's outer wrapper on a retry.
local function hook(object, key, factory)
    if type(object) ~= "table" then return end
    local seen = hooked[object]
    if not seen then seen = {}; hooked[object] = seen end
    for _, candidate in ipairs({key, hash(key)}) do
        if not seen[candidate] then
            local ok, original = pcall(function() return object[candidate] end)
            if ok and type(original) == "function" then
                local wrapped = factory(original)
                local written = pcall(function() object[candidate] = wrapped end)
                if written then seen[candidate] = true end
            end
        end
    end
end

local function present(bundle)
    if bundle == nil or isProxy[bundle] then return bundle end
    if proxies[bundle] then return proxies[bundle] end
    local view = setmetatable({}, { __index = function(_, key)
        if active() then
            if matches(key, "name") then return nameKey end
            if matches(key, "desc") or matches(key, "description") then return descriptionKey end
        end
        return bundle[key]
    end })
    proxies[bundle], isProxy[view] = view, true
    return view
end

local function wrapRef(original)
    return function(...)
        local first, second = ...
        if active() and (darkFlare(first) or darkFlare(second)) then
            return present(original(...))
        end
        return original(...)
    end
end

local readingIndex = false
local function matchesIndex(index)
    if type(index) ~= "number" or index < 0 or readingIndex then return false end
    local lookup = read(rawget(_G, "SUPER"), "getindexforref")
    if type(lookup) ~= "function" then return false end
    readingIndex = true
    local found = false
    for _, ref in ipairs(refs) do
        if indexes[ref] == nil then
            local ok, value = pcall(lookup, ref)
            if ok and type(value) == "number" and value > 0 then indexes[ref] = value end
        end
        if indexes[ref] == index then found = true; break end
    end
    readingIndex = false
    return found
end

local function wrapIndex(original)
    return function(...)
        local first, second = ...
        local index = type(first) == "number" and first or second
        if active() and index == 0 then
            -- A missing ref can return zero. Only decorate a positively identified bundle.
            local bundle = original(...)
            if bundle and (listBundles[bundle] or darkFlare(read(bundle, "ref"))) then return present(bundle) end
            return bundle
        end
        if active() and matchesIndex(index) then return present(original(...)) end
        return original(...)
    end
end

local function copyTable(source)
    local result = {}
    for k, v in pairs(source) do result[k] = v end
    local meta = getmetatable(source)
    if type(meta) == "table" then setmetatable(result, meta) end
    return result
end

local function projectRows(rows)
    if type(rows) ~= "table" then return rows end
    local copy
    for i, row in ipairs(rows) do
        if type(row) == "table" and darkFlare(read(row, "ref")) then
            if copy == nil then copy = copyTable(rows) end
            local out = copyTable(row)
            local bundle = read(row, "superBundle")
            if bundle == nil then
                local lookup = read(rawget(_G, "SUPER"), "GetBundleByRef")
                if type(lookup) == "function" then
                    local ok, value = pcall(lookup, read(row, "ref"))
                    if ok then bundle = value end
                end
            end
            if bundle ~= nil then listBundles[bundle] = true end
            out.superBundle = present(bundle)
            out.isUnlocked, out.unlockRank, out.isRestrictedFieldUpgradeEquipped = true, 0, false
            copy[i] = out
        end
    end
    return copy or rows
end

local function wrapList(original)
    return function(...)
        if not active() then return original(...) end
        local rows = original(...)
        local ok, projected = pcall(projectRows, rows)
        return ok and projected or rows
    end
end

local findingLoot = false
local function targetArg(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if darkFlare(value) then return true end
    end
    if findingLoot then return false end
    local lookup = read(rawget(_G, "LOOT"), "getitemid")
    if type(lookup) ~= "function" then return false end
    findingLoot = true
    for _, ref in ipairs(refs) do
        if lootIds[ref] == nil then
            local ok, id = pcall(lookup, ref)
            if ok and id ~= nil and id ~= false and tostring(id) ~= "0" and tostring(id) ~= "-1" then
                lootIds[ref] = id
            end
        end
    end
    findingLoot = false
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value ~= nil then
            for _, id in pairs(lootIds) do
                if value == id or value == tostring(id) then return true end
            end
        end
    end
    return false
end

local function allow(value)
    return function(original)
        return function(...)
            if active() and targetArg(...) then return value end
            return original(...)
        end
    end
end

local function textFor(key)
    if type(key) ~= "string" then return nil end
    key = key:lower()
    if key == nameKey then return title end
    if key == descriptionKey then return description end
end

local function wrapLocalize(upper)
    return function(original)
        return function(key, ...)
            local text = active() and textFor(key)
            if text then return upper and text:upper() or text end
            return original(key, ...)
        end
    end
end

local function wrapSetText(original)
    return function(element, key, ...)
        local text = active() and textFor(key)
        return original(element, text or key, ...)
    end
end

local function install()
    local super, loot = rawget(_G, "SUPER"), rawget(_G, "LOOT")
    hook(super, "GetBundleByRef", wrapRef)
    hook(super, "getbundlebyindex", wrapIndex)
    hook(super, "getallfieldupgrades", wrapList)
    hook(loot, "getscriptbundleforref", wrapRef)
    for _, key in ipairs({"IsUnlocked", "isunlockedwithid"}) do
        hook(loot, key, allow(true))
        hook(rawget(_G, "PROGRESSION"), key, allow(true))
    end
    for _, key in ipairs({"isitembanned", "isitembannedbyref"}) do hook(loot, key, allow(false)) end
    hook(rawget(_G, "Restrictions"), "IsSuperRestricted", allow(false))
    local engine, lui = rawget(_G, "Engine"), rawget(_G, "LUI")
    for _, key in ipairs({"Localize", "LocalizeString"}) do hook(engine, key, wrapLocalize(false)) end
    for _, key in ipairs({"LocalizeToUpper", "LocalizeToUpperString"}) do hook(engine, key, wrapLocalize(true)) end
    for _, class in ipairs({"UIText", "UIElement", "UIStyledText"}) do
        local element = read(lui, class)
        hook(element, "setText", wrapSetText)
        hook(element, "SetText", wrapSetText)
    end
end

local function root()
    local lui = rawget(_G, "LUI")
    local getRoot = read(lui, "GetRoot")
    if type(getRoot) == "function" then
        local ok, value = pcall(getRoot)
        if ok and value then return value end
    end
    return read(lui, "primaryRoot")
end

local function schedule()
    local current = root()
    if current == nil then state.timerRoot, state.timer = nil, nil; return end
    if current == state.timerRoot and state.timer ~= nil then return end
    local wait = read(current, "Wait")
    if type(wait) ~= "function" then return end
    local ok, timer = pcall(wait, current, 2000)
    if not ok or not timer then return end
    state.timerRoot, state.timer = current, timer
    timer.onComplete = function()
        if state.timer ~= timer then return end
        state.timerRoot, state.timer = nil, nil
        state.refresh()
    end
end

local function pack(...) return { n = select("#", ...), ... } end
local unpackValues = unpack or table.unpack
local function wrapMenu(original)
    return function(...)
        state.refresh()
        local result = pack(original(...))
        state.refresh()
        return unpackValues(result, 1, result.n)
    end
end

function state.refresh()
    if state.busy or not state.enabled then return end
    state.busy = true
    -- A menu can create the first root or replace it. Retry even outside Zombies.
    hook(rawget(_G, "MenuBuilder"), "BuildRegisteredType", wrapMenu)
    hook(read(rawget(_G, "LUI"), "FlowManager"), "RequestAddMenu", wrapMenu)
    pcall(install)
    pcall(schedule)
    state.busy = false
end

state.refresh()
