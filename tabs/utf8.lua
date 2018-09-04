-- UTF8 functions
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 http://wiki.creativecommons.org/CC0

--[[
This file provides some basic functionality for dealing with utf8
strings.  The basic lua string operations act on a byte-by-byte basis
and these have to be modified to work on a utf8-character basis.
--]]

UTF8 = class()
utf8 = UTF8

function UTF8:init(c,l)
    if type(c) == "table" then
        self.uchars = c or {}
        if not l then
            l = 0
            for k,v in ipairs(c) do
                l = k
            end
        end
        self.length = l
    elseif type(c) == "string" then
        self:process(c)
    elseif type(c) == "number" then
        self.uchars = {c}
        self.length = 1
    else
        self.uchars = {}
        self.length = 0
    end
end

function UTF8:process(s)
    local t = {}
    local l
    local n = 0
    for c in s:gmatch"." do
        a = string.byte(c)
        if a < 127 then
            table.insert(t,a)
            n = n + 1
        elseif a > 191 then
            -- first byte
            l = 1
            a = a - 192
            if a > 31 then
                l = l + 1
                a = a - 32
                if a > 15 then
                    l = l + 1
                    a = a - 16
                end
            end
            d = a
        else
            l = l - 1
            d = d * 64 + (a - 128)
            if l == 0 then
                table.insert(t,d)
                n = n + 1
            end
        end
    end
    self.uchars = t
    self.length = n
end

--[[
Concatenate two UTF8 objects
--]]

function UTF8:append(u)
    for k,v in ipairs(u.uchars) do
        table.insert(self.uchars,v)
    end
    self.length = self.length + u.length
end

function UTF8:prepend(u)
    local c = {}
    for k,v in ipairs(u.uchars) do
        table.insert(c,v)
    end
    for k,v in ipairs(self.uchars) do
        table.insert(c,v)
    end
    self.uchars = c
    self.length = self.length + u.length
end

--[[
Returns the length of a utf8 string.
--]]

function UTF8:length()
    return self.length
end

--[[
Returns the substring from i to j of the utf8 string s.  The arguments
behave in the same fashion as string.sub with regard to negatives.
--]]

function UTF8:sub(i,j)
    local ln = self.length
    if i < 0 then
        i = i + ln + 1
    end
    if j < 0 then
        j = j + ln + 1
    end
    if i < 1 or i > ln or j < 1 or j > ln or i > j then
        return false
    end
    local c = {}
    local l = j - i + 1
    local lc = self.uchars
    for k = i,j do
        table.insert(c,lc[k])
    end
    return UTF8(c,l)
end

--[[
This splits a utf8 string at the specified spot.
--]]

function UTF8:split(i)
    local ln = self.length
    if i < 0 then
        i = i + ln + 1
    end
    if i < 1 then
        return self,UTF8({},0)
    end
    if i > ln then
        return UTF8({},0),self
    end
    local sc = {}
    local sl = i - 1
    local ec = {}
    local el = ln - i + 1
    local lc = self.uchars
    for k = 1,i-1 do
        table.insert(sc,lc[k])
    end
    for k = i,ln do
        table.insert(ec,lc[k])
    end
    return UTF8(sc,sl),UTF8(ec,el)
end

--[[
This takes in a hexadecimal number and converts it to a utf8 character.
--]]

function utf8hex(s)
    return UTF8(tonumber(Hex2Dec(s)))
end

--[[
This takes in a decimal number and converts it to a utf8 character.
--]]

utf8dec = string.char

function UTF8:tostring()
    local t = {}
    for k,a in ipairs(self.uchars) do
    if a < 128 then
        table.insert(t,a)
    elseif a < 2048 then
        local b,c
        b = a%64 + 128
        c = math.floor(a/64) + 192
        table.insert(t,c)
        table.insert(t,b)
    elseif a < 65536 then
        local b,c,d
        b = a%64 + 128
        c = math.floor(a/64)%64 + 128
        d = math.floor(a/4096) + 224
        table.insert(t,d)
        table.insert(t,c)
        table.insert(t,b)
    elseif a < 1114112 then
        local b,c,d,e
        b = a%64 + 128
        c = math.floor(a/64)%64 + 128
        d = math.floor(a/4096)%64 + 128
        e = math.floor(a/262144) + 240
        table.insert(t,e)
        table.insert(t,d)
        table.insert(t,c)
        table.insert(t,b)
    end
    end
    return string.char(unpack(t))
end

function UTF8:__tostring()
    return self:tostring()
end

--[[
This uses the utf8_upper array to convert a character to its
corresponding uppercase variant, if such exists.
--]]

function UTF8:toupper()
    for k,c in ipairs(self.uchars) do
        if utf8_upper[c] then
            self.chars[k] = utf8_upper[c]
        end
    end
end

--[[
This uses the utf8_lower array to convert a character to its
corresponding lowercase variant, if such exists.
--]]

function UTF8:tolower()
    for k,c in ipairs(self.uchars) do
        if utf8_lower[c] then
            self.chars[k] = utf8_lower[c]
        end
    end
end

--[[
This function splits the UTF8 "string" at the whitespace at or before
the given number


--]]

function UTF8:splitBy(n)
    local l = self.length
    local i = 0
    local c = self.uchars
    return function()
    if i > l then
        return nil
    end
    local t = {}
    local m
    if i + n > l then
        for k = i,l do
            table.insert(t,c[k])
        end
        m = l - i + 1
        i = l + 1
    else
        local p,q
        for k=i + n,i,-1 do
            if not q and c[k] == 32 then
                q = k + 1
            end
            if q and c[k] ~= 32 then
                p = k
                break
            end
        end
        p = p or i + n
        q = q or i + n
        for k=i,p do
            table.insert(t,c[k])
        end
        m = p - i + 1
        i = q
    end
    return UTF8(t,m)
    end
end

function UTF8:chars()
    local i = 0
    local n = self.length
    local c = self.uchars
    return function()
        if i == n then
            return nil
        end
        i = i + 1
        return c[i]
    end
end
    





