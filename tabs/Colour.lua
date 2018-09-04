-- Colour manipulation
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 (http://wiki.creativecommons.org/CC0)

--[[
This provides some functions for basic colour manipulation such as
colour blending.  The functions act on "color" objects and also return
"color" objects.
--]]

--[[
Although we are not a class, we work in the "Colour" namespace to keep
ourselves from interfering with other classes.
--]]

Colour = {}

-- Should we modify the alpha of our colours?
Colour.ModifyAlpha = false

--[[
This blends the two specified colours according to the parameter given
as the middle argument (the syntax is based on that of the "xcolor"
LaTeX package) which is the percentage of the first colour.
--]]

function Colour.blend(cc,t,c)
    local s,r,g,b,a
   s = t / 100
   r = s * cc.r + (1 - s) * c.r
   g = s * cc.g + (1 - s) * c.g
   b = s * cc.b + (1 - s) * c.b
   if Colour.ModifyAlpha then
      a = s * cc.a + (1 - s) * c.a
   else
      a = cc.a
   end
   return color(r,g,b,a)
end

--[[
This "tints" the specified colour which means blending it with white.
The parameter is the percentage of the specified colour.
--]]

function Colour.tint(c,t)
   local s,r,g,b,a 
   s = t / 100
   r = s * c.r + (1 - s) * 255
   g = s * c.g + (1 - s) * 255
   b = s * c.b + (1 - s) * 255
   if Colour.ModifyAlpha then
      a = s * c.a + (1 - s) * 255
   else
      a = c.a
   end
   return color(r,g,b,a)
end

--[[
This "shades" the specified colour which means blending it with black.
The parameter is the percentage of the specified colour.
--]]

function Colour.shade(c,t)
   local s,r,g,b,a 
   s = t / 100
   r = s * c.r
   g = s * c.g
   b = s * c.b
   if Colour.ModifyAlpha then
      a = s * c.a
   else
      a = c.a
   end
   return color(r,g,b,a)
end

--[[
This "tones" the specified colour which means blending it with gray.
The parameter is the percentage of the specified colour.
--]]

function Colour.tone(c,t)
   local s,r,g,b,a 
   s = t / 100
   r = s * c.r + (1 - s) * 127
   g = s * c.g + (1 - s) * 127
   b = s * c.b + (1 - s) * 127
   if Colour.ModifyAlpha then
      a = s * c.a + (1 - s) * 127
   else
      a = c.a
   end
   return color(r,g,b,a)
end

--[[
This returns the complement of the given colour.
--]]

function Colour.complement(c)
    local r,g,b,a
   r = 255 - c.r
   g = 255 - c.g
   b = 255 - c.b
   if Colour.ModifyAlpha then
      a = 255 - c.a
   else
      a = c.a
   end
   return color(r,g,b,a)
end

--[[
This "pretty prints" the colour, converting it to a string.
--]]

function Colour.tostring(c)
    return "R:" .. c.r .. " G:" .. c.g .. " B:" .. c.b .. " A:" .. c.a
end

--[[
This searches for a colour by name from a specified list (such as
"svg" or "x11").  It looks for a match for the given string at the
start of the name of the colour, without regard for case.
--]]

function Colour.byName(t,n)
   local ln,k,v,s,lk
   ln = "^" .. string.lower(n)
   for k,v in pairs(Colour[t]) do
      lk = string.lower(k)
      s = string.find(lk,ln)
      if s then
         return v
      end
   end
   print("Colour Error: No colour of name " .. n .. " exists in type " .. t)
end

--[[
The "ColourPicker" class is a module for the "User Interface" class
(though it can be used independently).  It defines a grid of colours
(drawn from a list) which the user can select from.  When the user
selects a colour then a "call-back" function is called with the given
colour as its argument.
--]]

ColourPicker = class()

--[[
There is nothing to do on initialisation.
--]]

function ColourPicker:init()
end

--[[
This is the real initialisation code, but it can be called at any
time.  It sets up the list from which the colours will be displayed
for the user to select from.  At the moment, it can deal with the
"x11" and "svg" lists, though allowing more is simple enough: the main
issue is deciding how many rows and columns to use to display the grid
of colours.
--]]

function ColourPicker:setList(t)
    local c,m,n
    if t == "x11" then
        -- 317 colours
        c = Colour.x11
        n = 20
        m = 16
    else
        -- 151 colours
        c = Colour.svg
        n = 14
        m = 11
    end
    local l = {}
    for k,v in pairs(c) do
        table.insert(l,v)
    end
    table.sort(l,ColourSort)
    self.m = m
    self.n = n
    self.colours = l
end

--[[
This is a crude sort routine for the colours.  It is not a good one.
--]]

function ColourSort(a,b)
    local c,d
    c = 4 * a.r + 2 * a.g + a.b
    d = 4 * b.r + 2 * b.g + b.b
    return c < d
end

--[[
This draws a grid of rounded rectangles (see the "Font" class) of each
colour.
--]]

function ColourPicker:draw()
    if self.active then
    pushStyle()
    strokeWidth(-1)
    local w = WIDTH/self.n
    local h = HEIGHT/self.m
    local s = math.min(w/4,h/4,10)
    local c = self.colours
    w = w - s
    h = h - s
    local i = 0
    local j = 1
    for k,v in ipairs(c) do
        fill(v)
        RoundedRectangle(s/2 + i*(w+s),HEIGHT + s/2 - j*(h+s),w,h,s)
        i = i + 1
        if i == self.n then
            i = 0
            j = j + 1
        end
    end
    popStyle()
    end
end

--[[
If we are active, we claim all touches.
--]]

function ColourPicker:isTouchedBy(touch)
    if self.active then
        return true
    end
end

--[[
The touch information is used to select a colour.  We wait until the
gesture has ended and then look at the xy coordinates of the first
touch.  This tells us which colour was selected and this is passed to
the call-back function which is stored as the "action" attribute.

The action attribute should be an anonymous function which takes one
argument, which will be a "color" object.
--]]

function ColourPicker:processTouches(g)
    if g.updated then
        if g.type.ended then
            if self.action then
            local t = g.touchesArr[1]
            local w = WIDTH/self.n
            local h = HEIGHT/self.m
            local i = math.floor(t.touch.x/w) + 1
            local j = math.floor((HEIGHT - t.touch.y)/h)
            local n = i + j*self.n
            local a = self.action(self.colours[n])
            if a then
                self.active = false
            end
            g:reset()
            else
                g:noted()
            end
        end
    end
end

--[[
This activates the colour picker, making it active and setting the
call-back function to whatever was passed to the activation function.
--]]

function ColourPicker:activate(f)
    self.active = true
    self.action = f
end
