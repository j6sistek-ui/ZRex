-- Fengari cannot execute Kronos LuaJIT bytecode. Honor only the known exact
-- literal-return chunks used by the shipped Game/Enum and native UI codec, and return
-- opaque interned identities that cannot equal a name, hex string or xhash(name).
return function(currentMode)
    local oldLoad = load
    local marker = string.char(27) .. "LJ"
    local prefix = marker .. string.char(0x84, 0x1a, 25, 0, 0, 2, 0, 1, 0, 2,
                                         0x28, 0, 0, 0, 0x4d, 0, 2, 0, 4, 0)
    local keys = {
        [string.char(0xdb,0xd8,0xf0,0xf4,0xca,0xe3,0x36,0xfd)] = {},
        [string.char(0x9f,0x9a,0x7d,0x06,0xce,0xe3,0xc7,0xaa)] = {},
        [string.char(0x00,0x2e,0x92,0xb5,0x07,0x37,0xf7,0x08)] = {}
    }
    local function key(hex)
        local bytes={}
        for i=8,1,-1 do bytes[#bytes+1]=string.char(tonumber(hex:sub(i*2-1,i*2),16)) end
        local raw=table.concat(bytes)
        if not keys[raw] then keys[raw]={} end
        return keys[raw]
    end
    for _,hex in ipairs({"fbce0c66654fcbd1","76055c55456f05df","42b31d442266478c",
        "75992a095c731b0c","dc04126761bb7455","08c43a07b566d980",
        "3246871af1e086b7","39f7fcec8fcb623d","e7eefe998522ec88"}) do key(hex) end
    local seen = {}
    load = function(chunk, ...)
        if type(chunk) ~= "string" or chunk:sub(1, 3) ~= marker then return oldLoad(chunk, ...) end
        local bytes = chunk:sub(#prefix + 1, #prefix + 8)
        assert(keys[bytes] and chunk == prefix .. bytes .. string.char(0), "invalid raw-hash bytecode")
        seen[bytes] = true
        return function() return keys[bytes] end
    end
    local gameKey = keys[string.char(0xdb,0xd8,0xf0,0xf4,0xca,0xe3,0x36,0xfd)]
    local enumKey = keys[string.char(0x9f,0x9a,0x7d,0x06,0xce,0xe3,0xc7,0xaa)]
    local zombiesKey = keys[string.char(0x00,0x2e,0x92,0xb5,0x07,0x37,0xf7,0x08)]
    Game = {[gameKey] = currentMode}
    Enum = {[enumKey] = {[zombiesKey] = 2}}
    return function()
        return seen[string.char(0xdb,0xd8,0xf0,0xf4,0xca,0xe3,0x36,0xfd)] and
            seen[string.char(0x9f,0x9a,0x7d,0x06,0xce,0xe3,0xc7,0xaa)] and
            seen[string.char(0x00,0x2e,0x92,0xb5,0x07,0x37,0xf7,0x08)]
    end,key
end
