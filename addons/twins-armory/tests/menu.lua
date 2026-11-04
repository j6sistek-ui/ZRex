-- Actual staged Lua; isolate VM literal identities and native UI boundaries.
local count=0
local function check(v,msg) assert(v,msg); count=count+1; print("PASS "..msg) end
local expectedPrice=tonumber(arg[2]) or 500
local mode=1
xhash=function(s)return "#"..s end
local usedRawKeys,key=dofile(assert(arg[3]))(function()return mode end)
local sent,logLines={},{}
local nativePrint=print
print=function(v)logLines[#logLines+1]=v; nativePrint(v) end
DebugPrint=nil
Engine={[key("76055c55456f05df")]=function(...)sent[#sent+1]={n=select("#",...),...} end}
local function element(id)
    local el={id=id,children={},events={},timers={},links={}}
    function el:addElement(c)self.children[#self.children+1]=c;c.parent=self end
    function el:SetAnchorsAndPosition(...)self.anchors={...} end
    function el:SetHandleMouse(v)self.mouse=v end
    function el:SetFontSize(v)self.font=v end
    function el:SetAlpha(v)self.alpha=v end
    function el:setText(v)self.text=v end
    function el:addEventHandler(k,v)assert(type(k)=="table","native event requires opaque raw key");self.events[k]=v end
    function el:Wait(ms)local t={ms=ms};self.timers[#self.timers+1]=t;return t end
    function el:closeTree()self.closed=true end
    function el:getParent()if self.closed then return nil end;return self.parent end
    function el:SetDefaultFocusToElement()error("default native focus must be preserved") end
    function el:getFirstChild()return self.children[1] end
    function el:getNextSibling()
        if self.parent then for i,v in ipairs(self.parent.children)do if v==self then return self.parent.children[i+1] end end end
    end
    return el
end
local down,up,left=key("dc04126761bb7455"),key("08c43a07b566d980"),{}
local linkKey=key("42b31d442266478c")
ElementAndButtonUtils={[key("75992a095c731b0c")]={
    [key("dc04126761bb7455")]=down,[key("08c43a07b566d980")]=up}}
local nativeLinks=0
ElementAndButtonUtils[linkKey]=function(from,to,direction)
    nativeLinks=nativeLinks+1;from.links[direction]=to;return true,nil,19
end
local root,nativeA,nativeB=element("arsenal")
local uiRoot=element("uiRoot")
LUI={GetRoot=function()return uiRoot end,FlowManager={RequestAddMenu=function()return "flow",nil,19 end}}
local omitGraph,throwBuild=false,false
local nestedMode,insideNested,nestedChild,overwriteReverse=nil,false,nil,false
MenuBuilder={BuildRegisteredType=function(name,options)
    if throwBuild then error("native builder failure") end
    if name==key("3246871af1e086b7") then
        local b,text=element("native generic button"),element("native label")
        b:addElement(text);b[key("39f7fcec8fcb623d")]=text
        return b
    end
    if nestedMode and not insideNested then
        insideNested=true
        local outer,oldA,oldB=root,nativeA,nativeB
        if nestedMode=="distinct" then root=element("nested child") end
        MenuBuilder.BuildRegisteredType(key("fbce0c66654fcbd1"),options)
        nestedChild=root
        root,nativeA,nativeB=outer,oldA,oldB
        insideNested=false
        if nestedMode=="same" then nativeA,nativeB=root.children[1],root.children[2] end
    end
    if #root.children==0 then
        nativeA,nativeB=element("stock ammo A"),element("stock ammo B")
        root:addElement(nativeA);root:addElement(nativeB)
    end
    if not omitGraph then
        local a,b,c=ElementAndButtonUtils[linkKey](nativeA,nativeB,down)
        assert(a==true and b==nil and c==19,"native link return tuple changed")
        ElementAndButtonUtils[linkKey](nativeB,nativeA,up)
        ElementAndButtonUtils[linkKey](nativeA,nativeB,left)
        if overwriteReverse then ElementAndButtonUtils[linkKey](nativeB,root,up) end
    end
    return root,nil,37
end}
dofile(assert(arg[1]))
check(#logLines>0 and logLines[1]:find("loaded",1,true),"base print logs even when optional DebugPrint is absent")
local a,b,c=MenuBuilder.BuildRegisteredType("ZMArsenalMenu",{controllerIndex=2})
check(a==root and b==nil and c==37,"builder return tuple preserved")
check(#root.children==2,"no supplemental button outside Zombies")
mode=2
MenuBuilder.BuildRegisteredType("UnrelatedMenu",{})
check(#root.children==2,"unrelated menus are unchanged")
MenuBuilder.BuildRegisteredType(key("fbce0c66654fcbd1"),{controllerIndex=2})
check(usedRawKeys(),"raw Game/Enum identities are decoded")
check(#root.children==3 and root.children[1]==nativeA and root.children[2]==nativeB,"native Ammo Mod elements are preserved")
local button,label=root.children[3]
label=button.children[1]
check(label.text=="Twins Mask — "..expectedPrice.." Salvage | Rex Infernus","native styled label shows shared price")
check(nativeA.links[down]==button and button.links[down]==nativeB,"forward focus route visits Twins between native entries")
check(nativeB.links[up]==button and button.links[up]==nativeA,"reverse focus route visits Twins and returns to native entries")
check(nativeA.links[left]==nativeB,"unrelated native navigation is unchanged")
MenuBuilder.BuildRegisteredType("ZMArsenalMenu",{})
check(#root.children==3 and nativeA.links[down]==button and nativeB.links[up]==button,"reused root keeps one button and restores its focus route")
check(button.events.button_action==nil and type(button.events[key("e7eefe998522ec88")])=="function","native action is registered under its opaque event identity")
button.events[key("e7eefe998522ec88")](button,{controllerIndex=2})
check(#sent==1 and sent[1].n==2 and sent[1][1]=="owner_twins_armory_purchase" and sent[1][2]==0,"native sender receives event name and value only")
button.events[key("e7eefe998522ec88")](button,{controllerIndex=3})
check(#sent==1,"duplicate activations are debounced")
for _,t in ipairs(button.timers)do if t.ms==600 then t.onComplete() end end
button.events[key("e7eefe998522ec88")](button,{controllerIndex=3})
check(#sent==2 and sent[2].n==2,"controller metadata cannot corrupt native request argument order")
mode=nil
button.events[key("e7eefe998522ec88")](button,{})
check(#sent==2,"unknown game mode cannot purchase")
for _,t in ipairs(button.timers)do if t.ms==1000 then t.onComplete();break end end
check(button.alpha==0 and not button.mouse,"cached button hides outside Zombies")
mode=2
Engine[key("76055c55456f05df")]=nil
for _,t in ipairs(button.timers)do if t.ms==1000 then t.onComplete();break end end
check(label.text=="Twins Mask purchase unavailable","missing native sender is shown")
local previousBuild=MenuBuilder.BuildRegisteredType
local previousLink=ElementAndButtonUtils[linkKey]
for i=1,20 do OwnerTwinsArmory.refresh() end
check(MenuBuilder.BuildRegisteredType==previousBuild and ElementAndButtonUtils[linkKey]==previousLink,"refresh does not repeatedly wrap native APIs")
local x,y,z=LUI.FlowManager.RequestAddMenu()
check(x=="flow" and y==nil and z==19,"menu-flow tuple remains intact")
root=element("no graph");omitGraph=true
MenuBuilder.BuildRegisteredType("ZMArsenalMenu",{})
check(#root.children==3,"native mouse button can render when graph capture is unavailable")
local log=table.concat(OwnerTwinsArmory.diagnostics,"\n")
check(log:find("no reciprocal native Down/Up edge observed",1,true) and log:find("native tree",1,true),"missing graph emits explicit bounded evidence without claiming focus success")
check(OwnerTwinsArmory.building==nil,"builder capture scope is released")
root=element("nested same root");omitGraph=false;nestedMode="same"
MenuBuilder.BuildRegisteredType("ZMArsenalMenu",{})
local nestedButton=root.children[3]
check(#root.children==3 and nativeA.links[down]==nestedButton and nestedButton.links[up]==nativeA and
    nestedButton.links[down]==nativeB and nativeB.links[up]==nestedButton,
    "nested Arsenal aliases sharing a root preserve one valid focus insertion")
root=element("nested outer root");nestedMode="distinct"
MenuBuilder.BuildRegisteredType("ZMArsenalMenu",{})
local outerButton,childButton=root.children[3],nestedChild.children[3]
check(#root.children==3 and #nestedChild.children==3 and outerButton~=childButton and
    outerButton.links[up]==root.children[1] and outerButton.links[down]==root.children[2] and
    childButton.links[up]==nestedChild.children[1] and childButton.links[down]==nestedChild.children[2],
    "nested distinct Arsenal roots keep separate native focus graphs")
nestedMode=nil;overwriteReverse=true;root=element("overwritten native edge")
MenuBuilder.BuildRegisteredType("ZMArsenalMenu",{})
check(nativeA.links[down]==nativeB and nativeB.links[up]==root and root.children[3].links[up]==nil,
    "overwritten reverse edge is preserved and stale reciprocal history is rejected")
overwriteReverse=false
throwBuild=true
local built,err=pcall(MenuBuilder.BuildRegisteredType,"ZMArsenalMenu",{})
check(not built and tostring(err):find("native builder failure",1,true) and OwnerTwinsArmory.building==nil,"native builder errors propagate and release capture scope")
throwBuild=false
local noGraphButton=root.children[3]
noGraphButton:closeTree()
local timerCount=#noGraphButton.timers
for _,t in ipairs(noGraphButton.timers)do if t.ms==1000 then t.onComplete();break end end
check(OwnerTwinsArmory.attached[root]==nil and #noGraphButton.timers==timerCount,"detached menu button releases attachment and stops polling")
print("ALL TWINS MENU CHECKS PASSED "..count)
