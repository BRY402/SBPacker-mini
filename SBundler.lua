local f = string.format

local SBundler = {
    init = "",
    modules = {}
}


function SBundler:onStart(code)
    if type(code) ~= "string" then
        error("Invalid initialization source, expected string", 2)
    end
    
    SBundler.init = code
end


function SBundler:clear()
    self.modules = {}
end

function SBundler:generate()
    local src = {
        "local package = package or {preload = {}, loaded = {}}",
        "local unpack = unpack or table.unpack",
        [[
if not table.copy then
    table = setmetatable({
        copy = function(table)
            local out = {}
            for k, v in next, table do
                out[k] = v
            end

            return out
        end
    }, {__index = table})
end
]],
        "local _ENV = _ENV or getfenv()",
        [[

local loadmod = require
local function require(modname, args)
    local value = package.loaded[modname]
    if value then
        return value
    end

    local mod = package.preload[modname]
    if mod then
        local args = type(args) == "table" and args or {}
        package.loaded[modname] = mod(modname, unpack(args))
    else
        package.loaded[modname] = loadmod(modname)
    end

    return package.loaded[modname]
end
]],
    }
    
    for modname, modsrc in next, SBundler.modules do
        src[#src + 1] = f([[
package.preload[%q] = function(...)
    local _ENV = table.copy(_ENV)
    local function mod(_ENV, ...)
%s
    end
    if setfenv then
        setfenv(mod, _ENV)
    end

    return mod(_ENV, ...)
end]], modname, modsrc)
    end
    
    src[#src + 1] = SBundler.init
    
    return table.concat(src, "\n")
end


function SBundler:addMod(modname, Source)
    if type(Source) ~= "string" then
        error("Invalid module source, expected string", 2)
    end
    
    self.modules[tostring(modname)] = Source
end

function SBundler:removeMod(modname)
    self.modules[tostring(modname)] = nil
end

function SBundler:hasMod(modname)
    return self.modules[tostring(modname)] ~= nil
end


return SBundler