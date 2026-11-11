-- Original small fixture representing a second package on the same UI API.
-- The real installed Blood Burner menu is tested separately via BIKE_MENU_LUA.
local seen=setmetatable({}, {__mode="k"})
local function active()
    -- This small foreign-hook fixture reads the sole mocked mode getter.
    -- The real supplied bike integration separately exercises its raw-key codec.
    for _, getter in pairs(Game) do
        if type(getter)=="function" then return getter()==2 end
    end
    return false
end
local function refresh()
    if type(SUPER)~="table" or seen[SUPER] then return end
    if type(SUPER.GetBundleByRef)~="function" then return end
    seen[SUPER]=true
    local original=SUPER.GetBundleByRef
    SUPER.GetBundleByRef=function(ref,...)
        local bundle=original(ref,...)
        if active() and ref=="super_healing_aura" and bundle then
            return setmetatable({name="VEHICLES/BLOOD_BURNER"},{__index=bundle})
        end
        return bundle
    end
end
if type(MenuBuilder)=="table" and type(MenuBuilder.BuildRegisteredType)=="function" then
    local original=MenuBuilder.BuildRegisteredType
    MenuBuilder.BuildRegisteredType=function(...)
        refresh()
        local a,b,c=original(...)
        refresh()
        return a,b,c
    end
end
refresh()
