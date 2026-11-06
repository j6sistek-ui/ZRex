-- Original local extension of the native Arsenal Ammo Mods catalog.
-- Native ZMAmmoModWidget owns card construction, scrolling, focus and activation.
local VERSION="native-grid-1"
local previous=rawget(_G,"OwnerTwinsArmory")
if type(previous)=="table" and previous.version==VERSION then previous.refresh(); return end
if type(previous)=="table" then previous.enabled=false end
local S={version=VERSION,enabled=true,diagnostics={},pending=setmetatable({},{__mode="k"})}
rawset(_G,"OwnerTwinsArmory",S)
local hooks=setmetatable({},{__mode="k"})
local rawHashes,hashes={},{}
local unpackValues=unpack or table.unpack
local function pack(...)return {n=select("#",...),...} end

-- Shipped BO7 raw xhash literal codec; hex text is never hashed as a name.
local function uleb(n)
    local bytes={}
    repeat
        local b=n%128;n=math.floor(n/128)
        if n>0 then b=b+128 end
        bytes[#bytes+1]=string.char(b)
    until n==0
    return table.concat(bytes)
end
local function rawHash(hex)
    if rawHashes[hex]~=nil then return rawHashes[hex] end
    if type(load)~="function" then return nil end
    local bytes={}
    for i=8,1,-1 do bytes[#bytes+1]=string.char(tonumber(hex:sub(i*2-1,i*2),16)) end
    local kgc=string.char(4,0)..table.concat(bytes)
    local bc=string.char(0x28,0,0,0)..string.char(0x4d,0,2,0)
    local body=string.char(0,0,2,0)..uleb(1)..uleb(0)..uleb(2)..bc..kgc
    local chunk=string.char(27).."LJ"..string.char(0x84)..uleb(0x1a)..uleb(#body)..body..string.char(0)
    local ok,fn=pcall(load,chunk)
    if not ok or type(fn)~="function" then return nil end
    local worked,value=pcall(fn)
    if worked and value~=nil then rawHashes[hex]=value;return value end
end
local function hash(name)
    if hashes[name]~=nil then return hashes[name] end
    local C=rawget(_G,"CLUA")
    local fn=rawget(_G,"xhash") or rawget(_G,"PushXHash") or (C and C.PushXHash)
    if type(fn)~="function" then return nil end
    local ok,value=pcall(fn,name)
    if ok and value~=nil then hashes[name]=value;return value end
end
local function get(object,key)
    if object==nil then return nil end
    if #key==16 and key:match("^%x+$") then
        local h=rawHash(key)
        if h==nil then return nil end
        local ok,value=pcall(function()return object[h] end)
        if ok then return value end
        return nil
    end
    local ok,value=pcall(function()return object[key] end)
    if ok and value~=nil then return value end
    local h=hash(key)
    if h~=nil then ok,value=pcall(function()return object[h] end);if ok then return value end end
end
local function call(object,key,...)
    local fn=get(object,key)
    if type(fn)=="function" then return fn(object,...) end
end
local function set(object,key,value)
    local h=rawHash(key)
    if h~=nil then object[h]=value end
end
local function log(message)
    S.diagnostics[#S.diagnostics+1]=message
    if #S.diagnostics>24 then table.remove(S.diagnostics,1) end
    -- The installed native logger persists its special k1 prefix even when
    -- generic luiDebugPrint is disabled. Base print does not reach poi_reg.log.
    local fn=rawget(_G,"DebugPrint")
    if type(fn)=="function" then pcall(fn,"k1 owner twins: "..message) end
end
local function once(key,message)
    S.logged=S.logged or {}
    if not S.logged[key] then S.logged[key]=true;log(message) end
end
local function zombies()
    if not S.enabled then return false end
    local fn=get(rawget(_G,"Game"),"fd36e3caf4f0d8db")
    local value=get(get(rawget(_G,"Enum"),"aac7e3ce067d9a9f"),"08f73707b5922e00")
    if type(fn)~="function" or value==nil then return false end
    local ok,mode=pcall(fn)
    return ok and mode~=nil and mode==value
end
local function price()
    -- Fixed shared prototype price. Never quote a client-local dvar to the player.
    return 500
end
local EVENT="owner_twins_armory_purchase"
local NAME_KEY="OWNER_TWINS_ARMORY_NAME"
local DESC_KEY="OWNER_TWINS_ARMORY_DESC"
local function arsenal(ref)
    return ref=="arsenal" or ref==rawHash("1ab0119734c3d7c1") or ref==hash("arsenal")
end
local function own(item)
    return get(item,"8ff238f7dff1082f")==EVENT and arsenal(get(item,"5eec7203abc832d3"))
end
local function shallow(source)
    if type(source)~="table" then return nil end
    local copy={}
    for key,value in pairs(source) do copy[key]=value end
    return copy
end
local function augment(ref,groups)
    if not zombies() or not arsenal(ref) or type(groups)~="table" then return groups end
    for index,group in ipairs(groups) do
        local items=get(group,"3e7884bf4f412c6f")
        local matches=get(group,"8ff238f7dff1082f")=="arsenal_ammomod_purchase" or
            get(group,"8fe80fc822cdee86")==rawHash("ddb4172a367ec31e")
        if type(items)=="table" then
            for _,item in ipairs(items) do
                if own(item) then return groups end
                if get(item,"8ff238f7dff1082f")=="arsenal_ammomod_purchase" then matches=true end
            end
        end
        if matches and type(items)=="table" and type(items[1])=="table" then
            local result,category,entries,item=shallow(groups),shallow(group),shallow(items),shallow(items[1])
            -- Keep the real card's presentation/currency schema. Every write below
            -- targets our new record; no native item or collection is edited.
            set(item,"455f116bf695c8f6",NAME_KEY) -- displayName
            set(item,"c4bcadba8e631b86",NAME_KEY) -- name
            set(item,"7c45caed6dd53bd7",NAME_KEY) -- nameString
            set(item,"0cc44970c8397929",DESC_KEY) -- description
            set(item,"5d3bf36cd0208187","zmloot_scarab_twins_ee_mask") -- itemRef
            set(item,"5eec7203abc832d3",ref) -- preserve the native menuRef representation
            set(item,"8ff238f7dff1082f",EVENT) -- purchaseNotify
            set(item,"30ba635b40657d07",0) -- native notification value
            set(item,"0bef0691197c9f78",price()) -- cost
            set(item,"c89a43c726284aaf",price()) -- computed native cost
            set(item,"b7f04639fd95bc39",#entries) -- zero-based index in category
            set(item,"b1e5e28e4479a274",0) -- count
            set(item,"c7679b40127480c8",false) -- inherited progression requirement
            set(item,"09805182fb33868b",nil) -- inherited required unlock/dvar
            set(item,"bad3f6f2a679497d",nil) -- inherited visibility omnvar
            set(item,"de604bfe9c3ff46f",nil) -- inherited weapon loot type
            entries[#entries+1]=item
            set(category,"3e7884bf4f412c6f",entries)
            local filtered=get(group,"13528bf3e26ae1eb")
            if type(filtered)=="table" then set(category,"13528bf3e26ae1eb",shallow(filtered)) end
            category.__ownerTwinsCatalog=true
            result[index]=category
            once("catalog","native Ammo Mods catalog appended: "..#items.." -> "..#entries.."; Rex-only backend")
            return result
        end
    end
    once("missing-category","native Arsenal catalog observed; Ammo Mods schema not matched")
    return groups
end
local function hook(object,key,factory,literal)
    if type(object)~="table" then return false end
    local keys=literal and {rawHash(key)} or {key,hash(key)}
    local seen=hooks[object]
    if not seen then seen=setmetatable({},{__mode="k"});hooks[object]=seen end
    local installed=false
    for _,candidate in ipairs(keys) do
        local original=object[candidate]
        if type(original)=="function" and not seen[original] then
            local wrapper=factory(original)
            object[candidate]=wrapper;seen[wrapper]=true;installed=true
        elseif type(original)=="function" then installed=true end
    end
    return installed
end
local function install()
    local P=rawget(_G,"PurchaseMenuUtils")
    local ready=hook(P,"249daa49174b1bec",function(original)
        return function(ref,...)
            local values=pack(original(ref,...))
            local ok,result=pcall(augment,ref,values[1])
            if ok then values[1]=result else once("catalog-error","catalog adapter failed: "..tostring(result)) end
            return unpackValues(values,1,values.n)
        end
    end,true)
    hook(P,"8078fb920684cad8",function(original)
        return function(controller,category,...)
            local values=pack(original(controller,category,...))
            if zombies() and type(category)=="table" and category.__ownerTwinsCatalog then
                local entries=get(category,"3e7884bf4f412c6f")
                local filtered=get(category,"13528bf3e26ae1eb")
                if type(entries)=="table" and type(filtered)=="table" then
                    for index,item in ipairs(entries) do
                        if own(item) then
                            local present=false
                            for _,value in ipairs(filtered) do if value==index then present=true end end
                            if not present then filtered[#filtered+1]=index end
                        end
                    end
                    once("grid","native grid index adapter active; visible entries="..#filtered)
                end
            end
            return unpackValues(values,1,values.n)
        end
    end,true)
    hook(P,"c3f6ab291a0bd165",function(original)
        return function(item,...)
            if zombies() and own(item) then return price() end
            return original(item,...)
        end
    end,true)
    hook(P,"4191c1637a229078",function(original)
        return function(controller,item,...)
            -- The custom mask has no weapon-ammo-mod unlock requirement.
            -- Native currency rendering still checks 500 salvage; GSC owns grant/debit.
            if zombies() and own(item) then return true end
            return original(controller,item,...)
        end
    end,true)
    hook(P,"94a2c81e7746b4ec",function(original)
        return function(element,controller,...)
            local ok,item=pcall(call,element,"fc0eb675a00a84ef")
            if not ok or not own(item) then return original(element,controller,...) end
            if not zombies() or S.pending[element] then return end
            S.pending[element]=true
            log("native card activated; calling native purchase helper")
            local values=pack(pcall(original,element,controller,...))
            local worked,timer=pcall(call,element,"Wait",600)
            if worked and timer then timer.onComplete=function()S.pending[element]=nil end
            else S.pending[element]=nil end
            if not values[1] then error(values[2],0) end
            return unpackValues(values,2,values.n)
        end
    end,true)
    hook(rawget(_G,"Engine"),"aed84c33ec5f01ea",function(original)
        return function(key,...)
            if key==NAME_KEY then return "Twins Mask" end
            if key==DESC_KEY then return "Native Twins Mask lightning. "..price().." salvage. Rex Infernus only." end
            return original(key,...)
        end
    end,true)
    hook(rawget(_G,"Engine"),"76055c55456f05df",function(original)
        return function(event,value,...)
            if event==EVENT then log("native NotifyServer: event + value="..tostring(value)) end
            return original(event,value,...)
        end
    end,true)
    if ready then once("installed","native catalog source adapter installed ("..VERSION..")") end
    return ready
end
function S.refresh()
    if S.refreshing or not S.enabled then return end
    S.refreshing=true
    install()
    hook(rawget(_G,"MenuBuilder"),"BuildRegisteredType",function(original)
        return function(name,...)
            install()
            local values=pack(original(name,...))
            if name=="ZMArsenalMenu" or name==rawHash("fbce0c66654fcbd1") then log("native Arsenal built; catalog path only") end
            install()
            return unpackValues(values,1,values.n)
        end
    end)
    for _,name in ipairs({"require","requirexhash","requireUnlessHotload"}) do
        hook(_G,name,function(original)
            return function(...)
                local values=pack(original(...))
                install()
                return unpackValues(values,1,values.n)
            end
        end)
    end
    S.refreshing=false
end
S.refresh()
log("loaded "..VERSION.."; standalone side button removed")
