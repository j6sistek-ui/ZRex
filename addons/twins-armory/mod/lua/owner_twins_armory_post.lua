-- Original local prototype: one supplemental native button inside the Arsenal.
-- Observe and extend the native focus graph; never replace the menu's default focus.
local previous=rawget(_G,"OwnerTwinsArmory")
if type(previous)=="table" and type(previous.refresh)=="function" then previous.refresh(); return end
local S={enabled=true,attached=setmetatable({},{__mode="kv"}),seenNames={},diagnostics={}}
rawset(_G,"OwnerTwinsArmory",S)
local hooks=setmetatable({},{__mode="k"})
local hashes={}
local rawHashes={}

-- Shipped HKS codec: a literal 64-bit key is not xhash(the hex text).
local function uleb(n)
    local bytes={}
    repeat
        local b=n%128; n=math.floor(n/128)
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
    if worked and value~=nil then rawHashes[hex]=value; return value end
end

local function hash(name,dvar)
    local cacheKey=(dvar and "d:" or "n:")..name
    if hashes[cacheKey]~=nil then return hashes[cacheKey] end
    local C=rawget(_G,"CLUA")
    local fn
    if dvar then fn=rawget(_G,"xhashdvar") or rawget(_G,"PushXHashDvar") or (C and C.PushXHashDvar)
    else fn=rawget(_G,"xhash") or rawget(_G,"PushXHash") or (C and C.PushXHash) end
    if type(fn)~="function" then return nil end
    local ok,value=pcall(fn,name)
    if ok and value~=nil then hashes[cacheKey]=value; return value end
end

local function get(object,key)
    if object==nil then return nil end
    if #key==16 and key:match("^%x+$") then
        local h=rawHash(key)
        if h==nil then return nil end
        local ok,value=pcall(function() return object[h] end)
        if ok then return value end
        return nil
    end
    local ok,value=pcall(function() return object[key] end)
    if ok and value~=nil then return value end
    local h=hash(key)
    if h~=nil then ok,value=pcall(function() return object[h] end); if ok then return value end end
end
local function invoke(object,key,...)
    local fn=get(object,key)
    if type(fn)=="function" then return fn(...) end
end
local function call(object,key,...)
    local fn=get(object,key)
    if type(fn)=="function" then return fn(object,...) end
end
local function log(text)
    S.diagnostics[#S.diagnostics+1]=text
    if #S.diagnostics>24 then table.remove(S.diagnostics,1) end
    -- print is the Lua base logger; DebugPrint is optional in this game VM.
    local fn=rawget(_G,"print") or rawget(_G,"DebugPrint")
    if type(fn)=="function" then pcall(fn,"[Owner Twins Arsenal] "..text) end
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
local function arsenalName(name)
    if name==rawHash("fbce0c66654fcbd1") then return true end
    for _,candidate in ipairs({"ZMArsenalMenu","zmarsenalmenu"}) do
        if name==candidate or name==hash(candidate) then return true end
    end
    return false
end
local function sender()
    local E=rawget(_G,"Engine")
    return get(E,"76055c55456f05df") or get(E,"NotifyServer")
end

local function topology(root)
    local rows={}
    local function visit(el,depth)
        if not el or #rows>=24 or depth>4 then return end
        rows[#rows+1]=tostring(get(el,"id")).."/"..type(get(el,"addEventHandler"))
        local ok,child=pcall(call,el,"getFirstChild")
        while ok and child and #rows<24 do
            visit(child,depth+1)
            ok,child=pcall(call,child,"getNextSibling")
        end
    end
    visit(root,0)
    log("native tree "..table.concat(rows,","))
end

local function integrateNavigation(button,graph)
    local E=rawget(_G,"ElementAndButtonUtils")
    local link=get(E,"42b31d442266478c")
    local dirs=get(E,"75992a095c731b0c")
    local down=get(dirs,"dc04126761bb7455")
    local up=get(dirs,"08c43a07b566d980")
    if type(link)~="function" or down==nil or up==nil then return false,"native link API unavailable" end
    -- Extend an observed reciprocal edge, preserving every other native edge.
    local links=graph and graph.links or {}
    local final={}
    for _,edge in ipairs(links) do
        if edge.from~=nil and edge.direction~=nil then
            local row=final[edge.from]
            if not row then row={}; final[edge.from]=row end
            row[edge.direction]=edge.to or false
        end
    end
    for i=#links,1,-1 do
        local edge=links[i]
        if edge.direction==down and edge.to~=nil and edge.from~=edge.to and
            edge.from~=button and edge.to~=button and final[edge.from][down]==edge.to and
            final[edge.to] and final[edge.to][up]==edge.from then
                    local ok,err=pcall(function()
                        link(edge.from,button,down)
                        link(button,edge.from,up)
                        link(button,edge.to,down)
                        link(edge.to,button,up)
                    end)
                    if not ok then
                        local a=pcall(link,edge.from,edge.to,down)
                        local b=pcall(link,edge.to,edge.from,up)
                        return false,"native link rejected; original pair restored="..tostring(a and b)..": "..tostring(err)
                    end
                    return true,"extended native Down/Up edge"
        end
    end
    return false,"no reciprocal native Down/Up edge observed ("..#links.." links)"
end

local function attach(root,options,graph)
    if not zombies() or root==nil then return end
    if S.attached[root] then
        -- Some builders reuse their root but rebuild its native navigation links.
        if graph and #graph.links>0 then pcall(integrateNavigation,S.attached[root],graph) end
        return
    end
    local controller=(type(options)=="table" and (options.controllerIndex or options.controller)) or 0
    -- This same shipped widget is used by Kronos' existing styled menu buttons.
    local ok,button=pcall(invoke,rawget(_G,"MenuBuilder"),"BuildRegisteredType",
        rawHash("3246871af1e086b7"),{controllerIndex=controller})
    if not ok or not button then log("native button builder unavailable: "..tostring(button)); return end
    local label=get(button,"39f7fcec8fcb623d")
    local setText=get(label,"setText")
    if not label or type(setText)~="function" then
        pcall(call,button,"closeTree"); log("native button label unavailable"); return
    end
    if type(get(root,"addElement"))~="function" or type(get(button,"addElement"))~="function" or
        type(get(button,"addEventHandler"))~="function" then
        pcall(call,button,"closeTree"); log("Arsenal element API unavailable; no button added"); return
    end
    local ok=pcall(function()
        call(button,"SetAnchorsAndPosition",0,1,1,0,50,470,-150,-88)
        call(button,"SetHandleMouse",true)
        call(label,"SetFontSize",22)
        call(root,"addElement",button)
        -- Native data-source refreshes must not replace this button's custom label.
        label.setText=function() end
    end)
    if not ok then pcall(call,button,"closeTree"); log("native button layout failed"); return end
    S.attached[root]=button
    local pending=false
    local function update()
        if not S.enabled then return end
        local active=zombies()
        pcall(call,button,"SetAlpha",active and 1 or 0)
        pcall(call,button,"SetHandleMouse",active)
        local notify=sender()
        local text
        if type(notify)=="function" then text="Twins Mask — "..price().." Salvage | Rex Infernus"
        else text="Twins Mask purchase unavailable" end
        pcall(setText,label,text)
    end
    local function purchase(element,event)
        if pending or not zombies() then return end
        local notify=sender()
        if type(notify)~="function" then log("NotifyServer unavailable; no purchase sent"); return end
        pending=true
        -- Installed native callsites use NotifyServer(eventName,value), without controller.
        local sent,err=pcall(notify,"owner_twins_armory_purchase",0)
        log("purchase request "..(sent and "sent" or ("failed: "..tostring(err))))
        if not sent then log("Purchase request failed: "..tostring(err)) end
        local wait=get(button,"Wait")
        if type(wait)=="function" then
            local worked,timer=pcall(wait,button,600)
            if worked and timer then timer.onComplete=function() pending=false end; return end
        end
        pending=false
    end
    -- Native UIButton translates mouse/controller activation into this raw event identity.
    local actionOk=pcall(call,button,"addEventHandler",rawHash("e7eefe998522ec88"),purchase)
    if not actionOk then
        S.attached[root]=nil; pcall(call,button,"closeTree"); log("No supported purchase input handler"); return
    end
    local navOk,linked,detail=pcall(integrateNavigation,button,graph)
    log("navigation "..tostring(navOk and linked)..": "..tostring(navOk and detail or linked))
    if not navOk or not linked then topology(root) end
    update()
    local function pulse()
        if not S.enabled or S.attached[root]~=button then return end
        if type(get(button,"getParent"))=="function" then
            local ok,parent=pcall(call,button,"getParent")
            if ok and parent==nil then S.attached[root]=nil; return end
        end
        update()
        local ok,timer=pcall(call,button,"Wait",1000)
        if ok and timer then timer.onComplete=pulse end
    end
    pulse()
    log("native button attached; sender="..type(sender()))
end

local unpackValues=unpack or table.unpack
local function pack(...) return {n=select("#",...),...} end
local function hook(object,key,factory)
    if type(object)~="table" then return end
    local seen=hooks[object]
    if not seen then seen={}; hooks[object]=seen end
    for _,candidate in ipairs({key,hash(key)}) do
        if not seen[candidate] then
            local fn=object[candidate]
            if type(fn)=="function" then object[candidate]=factory(fn); seen[candidate]=true end
        end
    end
end
local function hookNavigation()
    local object=rawget(_G,"ElementAndButtonUtils")
    local key=rawHash("42b31d442266478c")
    if type(object)~="table" or key==nil then return end
    local seen=hooks[object]
    if not seen then seen={}; hooks[object]=seen end
    local original=object[key]
    if type(original)~="function" or seen[key] then return end
    object[key]=function(from,to,direction,...)
        local result=pack(original(from,to,direction,...))
        local graph=S.building
        if graph and #graph.links<256 then graph.links[#graph.links+1]={from=from,to=to,direction=direction} end
        return unpackValues(result,1,result.n)
    end
    seen[key]=true
end
local function builder(original)
    return function(name,options,...)
        local graph,parent
        if arsenalName(name) then
            hookNavigation()
            graph,parent={links={}},S.building
            S.building=graph
        end
        local result=pack(pcall(original,name,options,...))
        if graph then S.building=parent end
        if not result[1] then error(result[2],0) end
        if type(name)=="string" and name:lower():find("arsenal",1,true) and not S.seenNames[name] then
            S.seenNames[name]=true; log("Builder observed: "..name)
        end
        if graph then
            -- A recognized nested/alias builder may already have a parent capture.
            -- Synthetic attachment links must never become its observed native graph.
            local active=S.building
            S.building=nil
            local ok,err=pcall(attach,result[2],options,graph)
            S.building=active
            if not ok then log("attach failed: "..tostring(err)) end
        end
        return unpackValues(result,2,result.n)
    end
end
function S.refresh()
    if S.refreshing or not S.enabled then return end
    S.refreshing=true
    hookNavigation()
    hook(rawget(_G,"MenuBuilder"),"BuildRegisteredType",builder)
    hook(get(rawget(_G,"LUI"),"FlowManager"),"RequestAddMenu",function(original)
        return function(...)
            local result=pack(original(...))
            S.refresh()
            return unpackValues(result,1,result.n)
        end
    end)
    local root
    local ok,current=pcall(invoke,rawget(_G,"LUI"),"GetRoot")
    if ok then root=current end
    if root and (S.timerRoot~=root or not S.timer) then
        local worked,timer=pcall(call,root,"Wait",2000)
        if worked and timer then
            S.timerRoot,S.timer=root,timer
            timer.onComplete=function()
                if S.timer~=timer then return end
                S.timerRoot,S.timer=nil,nil
                S.refresh()
            end
        end
    end
    S.refreshing=false
end
S.refresh()
log("loaded")
