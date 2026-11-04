-- Native-contract boundaries transcribed from the installed PurchaseMenuUtils
-- and ZMAmmoModWidget bytecode. The game UI/runtime itself is not emulated.
local count=0
local function check(v,msg)assert(v,msg);count=count+1;print("PASS "..msg)end
local expectedPrice=tonumber(arg[2])or 500
local mode=2
xhash=function(s)return "#"..s end
local usedRawKeys,K=dofile(assert(arg[3]))(function()return mode end)
local logs,sent={},{}
DebugPrint=function(s)assert(s:sub(1,3)=="k1 ","native persistent sink requires k1 prefix");logs[#logs+1]=s end
local function clone(t)local r={};for k,v in pairs(t)do r[k]=v end;return r end
local nativeCost,nativeCan,nativePurchase=0,0,0
local function item(name)
    return {[K("455f116bf695c8f6")]=name,[K("0bef0691197c9f78")]=500,
        [K("8ff238f7dff1082f")]="arsenal_ammomod_purchase",[K("30ba635b40657d07")]=7,
        [K("5eec7203abc832d3")]="arsenal",[K("5d3bf36cd0208187")]=name,
        [K("c7679b40127480c8")]=true,[K("bad3f6f2a679497d")]="native_stat",
        [K("b1e5e28e4479a274")]=9,[K("de604bfe9c3ff46f")]="ammo_mod",
        [K("b7f04639fd95bc39")]=0,untouchedFalse=false,currencyHandle={native=true}}
end
local stockA,stockB=item("native_A"),item("native_B")
local nativeItems={stockA,stockB}
local ammo={[K("3e7884bf4f412c6f")]=nativeItems,[K("8ff238f7dff1082f")]="arsenal_ammomod_purchase",
    [K("8fe80fc822cdee86")]=K("ddb4172a367ec31e"),[K("13528bf3e26ae1eb")]={1},otherField="keep"}
local other={[K("3e7884bf4f412c6f")]={item("rarity")},[K("8ff238f7dff1082f")]="arsenal_tierupgrade_purchase"}
other[K("3e7884bf4f412c6f")][1][K("8ff238f7dff1082f")]="arsenal_tierupgrade_purchase"
local source={other,ammo}
local returnCatalog=source
local P={}
P[K("249daa49174b1bec")]=function(ref)return returnCatalog,nil,39 end
P[K("8078fb920684cad8")]=function(controller,category)
    -- Native8078 writes a one-based filtered index list, separate from items.
    category[K("13528bf3e26ae1eb")]={1}
    return nil,"filtered"
end
P[K("c3f6ab291a0bd165")]=function(row,currency,controller)nativeCost=nativeCost+1;return row[K("0bef0691197c9f78")]*0.9 end
P[K("4191c1637a229078")]=function(controller,row)nativeCan=nativeCan+1;return false,"native locked" end
Engine={
    [K("aed84c33ec5f01ea")]=function(key)return "native:"..tostring(key),nil,11 end,
    [K("76055c55456f05df")]=function(...)sent[#sent+1]={n=select("#",...),...};return "sent",nil,23 end
}
P[K("94a2c81e7746b4ec")]=function(element,controller)
    nativePurchase=nativePurchase+1
    local row=element[K("fc0eb675a00a84ef")](element)
    if P[K("4191c1637a229078")](controller,row)then
        Engine[K("76055c55456f05df")](row[K("8ff238f7dff1082f")],row[K("30ba635b40657d07")])
    end
    return "native result",nil,51
end
local lazy=true
PurchaseMenuUtils=nil
require=function(name)if name=="native purchase module"then PurchaseMenuUtils=P end;return "required",nil,17 end
requirexhash=require;requireUnlessHotload=require
local nativeRoot={addElement=function()error("standalone sidebox must never be created")end}
MenuBuilder={BuildRegisteredType=function(name,options)
    if lazy then require("native purchase module");lazy=false end
    local categories=PurchaseMenuUtils[K("249daa49174b1bec")]("arsenal")
    nativeRoot.catalog=categories
    return nativeRoot,nil,37
end}
dofile(assert(arg[1]))
check(#logs>0 and logs[#logs]:find("standalone side button removed",1,true),"loaded message uses proven native persistent k1 sink")
local root,b,c=MenuBuilder.BuildRegisteredType(K("fbce0c66654fcbd1"),{controllerIndex=2})
check(root==nativeRoot and b==nil and c==37,"lazy native module loads before first Arsenal catalog and builder tuple is preserved")
check(usedRawKeys(),"raw Game/Enum identities are decoded")
local categories,mid,last=P[K("249daa49174b1bec")]("arsenal")
check(mid==nil and last==39,"catalog tuple including nil middle return is preserved")
check(categories~=source and categories[1]==other and categories[2]~=ammo,"only matched native Ammo Mods category is cloned")
local entries=categories[2][K("3e7884bf4f412c6f")]
local twins=entries[3]
check(#entries==3 and entries[1]==stockA and entries[2]==stockB,"one native catalog record follows every original Ammo Mod")
check(#nativeItems==2 and ammo[K("13528bf3e26ae1eb")][1]==1 and stockA[K("455f116bf695c8f6")]=="native_A",
    "source collection and original card data remain unchanged")
check(twins~=stockA and twins.currencyHandle==stockA.currencyHandle and twins.untouchedFalse==false,"native presentation schema and opaque currency handle are retained")
check(twins[K("b7f04639fd95bc39")]==2 and twins[K("30ba635b40657d07")]==0 and
    twins[K("8ff238f7dff1082f")] =="owner_twins_armory_purchase","new card has distinct native index and custom event/value")
check(twins[K("5d3bf36cd0208187")]=="zmloot_scarab_twins_ee_mask" and twins[K("b1e5e28e4479a274")]==0 and
    twins[K("bad3f6f2a679497d")]==nil and twins[K("de604bfe9c3ff46f")]==nil,"custom record does not inherit weapon ownership or visibility locks")
local name=Engine[K("aed84c33ec5f01ea")](twins[K("455f116bf695c8f6")])
local desc=Engine[K("aed84c33ec5f01ea")](twins[K("0cc44970c8397929")])
check(name=="Twins Mask" and desc:find(tostring(expectedPrice),1,true) and desc:find("Rex Infernus only",1,true),"native card localization shows correct identity price and map restriction")
local localText,localNil,localLast=Engine[K("aed84c33ec5f01ea")]("stock_text")
check(localText=="native:stock_text" and localNil==nil and localLast==11,"unrelated localization and tuple remain native")
local filterNil,filterText=P[K("8078fb920684cad8")](2,categories[2])
local indices=categories[2][K("13528bf3e26ae1eb")]
check(filterNil==nil and filterText=="filtered" and #indices==2 and indices[1]==1 and indices[2]==3,"lazy grid's final native index list includes custom card without restoring filtered stock entries")
local gridItems={}
for _,index in ipairs(indices)do gridItems[#gridItems+1]=entries[index] end
check(#gridItems==2 and gridItems[2]==twins,"native count/index mapping resolves Twins as a grid-owned card")
check(P[K("c3f6ab291a0bd165")](twins,{},2)==expectedPrice and nativeCost==0,"custom native cost remains fixed despite ordinary ammo discounts")
check(P[K("c3f6ab291a0bd165")](stockA,{},2)==450 and nativeCost==1,"ordinary native cost calculation is preserved")
check(P[K("4191c1637a229078")](2,twins)==true and nativeCan==0,"custom mask bypasses weapon-ammo unlock gate")
local locked,reason=P[K("4191c1637a229078")](2,stockA)
check(locked==false and reason=="native locked" and nativeCan==1,"normal native progression result and tuple remain intact")
local current=twins
local timers={}
local methods={[K("fc0eb675a00a84ef")]=function()return current end,
    Wait=function(self,ms)local t={ms=ms};timers[#timers+1]=t;return t end}
local element=setmetatable({},{__index=methods})
local result,nilResult,resultTail=P[K("94a2c81e7746b4ec")](element,2)
check(result=="native result" and nilResult==nil and resultTail==51,"grid activation invokes actual native purchase helper contract")
check(#sent==1 and sent[1].n==2 and sent[1][1]=="owner_twins_armory_purchase" and sent[1][2]==0,"native helper sends exact event/value without price or controller")
P[K("94a2c81e7746b4ec")](element,2)
check(#sent==1,"duplicate grid activation is debounced")
timers[1].onComplete()
P[K("94a2c81e7746b4ec")](element,2)
check(#sent==2,"native card can request again after debounce expires")
current=stockA
local before=nativePurchase
P[K("94a2c81e7746b4ec")](element,2)
check(nativePurchase==before+1 and #sent==2,"normal native card purchase path is preserved")
local userdata=io and io.stdout
if type(userdata)=="userdata"then
    local oldMeta=debug.getmetatable(userdata)
    debug.setmetatable(userdata,{__index=methods})
    current=twins
    P[K("94a2c81e7746b4ec")](userdata,2)
    debug.setmetatable(userdata,oldMeta)
    check(#sent==3,"native card getter supports userdata elements")
else error("userdata contract test requires a real Lua userdata")end
returnCatalog=nil
local nilA,nilB,nilC=P[K("249daa49174b1bec")]("arsenal")
check(nilA==nil and nilB==nil and nilC==39,"missing catalog preserves nil result and arity")
returnCatalog=io.stdout
check(P[K("249daa49174b1bec")]("arsenal")==io.stdout,"unexpected userdata collection is not enumerated or changed")
returnCatalog={keyed=ammo}
check(P[K("249daa49174b1bec")]("arsenal")==returnCatalog,"unexpected keyed collection fails closed instead of assuming array indices")
returnCatalog=source
check(P[K("249daa49174b1bec")]("crafting")==source,"other purchase menus retain their original catalog")
mode=1
check(P[K("249daa49174b1bec")]("arsenal")==source,"catalog is unchanged outside Zombies")
mode=nil
local beforeSent=#sent
current=twins
P[K("94a2c81e7746b4ec")](element,2)
check(#sent==beforeSent,"unknown game mode cannot activate the custom purchase")
mode=2
returnCatalog=categories
check(P[K("249daa49174b1bec")]("arsenal")==categories and #entries==3,"already extended catalog is not duplicated")
returnCatalog=source
local rawRef=K("1ab0119734c3d7c1")
local rawCategories=P[K("249daa49174b1bec")](rawRef)
check(rawCategories[2][K("3e7884bf4f412c6f")][3][K("5eec7203abc832d3")]==rawRef,"native opaque menuRef representation is preserved")
local oldCatalog,oldPurchase=P[K("249daa49174b1bec")],P[K("94a2c81e7746b4ec")]
for i=1,20 do OwnerTwinsArmory.refresh()end
dofile(assert(arg[1]))
check(P[K("249daa49174b1bec")]==oldCatalog and P[K("94a2c81e7746b4ec")]==oldPurchase,"refresh and same-version reload do not stack wrappers")
local reqA,reqB,reqC=require("unrelated")
check(reqA=="required" and reqB==nil and reqC==17,"late-load hook preserves require tuple")
local log=table.concat(logs,"\n")
check(log:find("native Ammo Mods catalog appended",1,true) and log:find("native grid index adapter active",1,true) and
    log:find("native card activated",1,true) and log:find("native NotifyServer",1,true),"durable telemetry covers catalog grid native activation and send")
check(#OwnerTwinsArmory.diagnostics<=24,"runtime diagnostics stay bounded")
print("ALL TWINS MENU CHECKS PASSED "..count)
