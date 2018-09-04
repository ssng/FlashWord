-- Bitmap font class
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 http://wiki.creativecommons.org/CC0

--[[
The "Font", "Sentence", "Char", and "Textarea" classes are all
designed to aid getting text onto the screen.  Their purposes are as
follows:

"Font": This contains a list of characters which make up a "font".
The methods are to do with rendering these characters on the screen in
a reasonable way (ensuring that characters line up correctly, for
example).

"Sentence": This class holds a single line of text to be drawn in a
given font.  Its purpose is that it be used when a string is to be
rendered several time (for example, over the course of many draw
iterations) as it saves various pieces of information needed to render
it to the screen to avoid computing them every time.

"Char": This class contains the information about a single character.
The initial information is based on the BDF font format; the first
time a Char object is drawn then this is converted to a sprite which
is then used on subsequent occasions.  In particular, sprites are only
created for those characters that are actually used.

"Textarea": This is a box containing lines which can be added to to
present messages to the user.  It handles line wrapping and scrolling,
and can be moved or hidden (except for the title).

Strings passed to the objects defined using these classes are assumed
to be in utf8 format (using the "utf8" functionality from the
corresponding file).  However, to get the full use of this one should
use a font supporting all the necessary characters.
--]]

Font = class()

--[[
The "Fonts" table contains functions that define the fonts used (we
use functions so that fonts are only processed if they are actually
used).
--]]

Fonts = {}

--[[
A "Font" is just a list of characters.
--]]

function Font:init(t)
    if t then
        self.name = t.name
        self.size = t.size
        self.isint = true
        font(t.name)
        fontSize(t.size)
        local fm = fontMetrics()
        local w,h = textSize("x")
        self.bbx = {w,h}
        self.descent = fm.descent
        for k,v in ipairs({
            "write", 
            "write_utf8", 
            "draw_char",
            "prepare_char",
            "colour",
            "render_char",
            "setstyle"
        }) do
            self[v] = self["int_" .. v]
        end
    else
        self.char = {}
    end
end

--[[
This returns the line height (bounding box height) of the font.
--]]

function Font:lineheight()
    return self.bbx[2]
end

--[[
This returns the default character width (individual characters may
override this).
--]]

function Font:charWidth()
    return self.bbx[1]
end

--[[
This sets the colour for the font.
--]]

function Font:setColour(c)
    self.tint = c
end

--[[
Builtin and rendered fonts have different methods of setting colours
--]]

function Font:colour(c)
    tint(c)
end

function Font:int_colour(c)
    fill(c)
end

--[[
and of how to put a character on the screen
--]]

function Font:render_char(c,x,y)
    sprite(c,x,y)
end

function Font:int_render_char(c,x,y)
    text(c,x,y)
end

--[[
and of what styles should apply
--]]

function Font:setstyle()
    noSmooth()
    spriteMode(CORNER)
end

function Font:int_setstyle()
    textMode(CORNER)
    font(self.name)
    fontSize(self.size)
end

--[[
This is the basic method for writing a string to the screen.  Its
inputs are a string (assumed to be utf8), the xy coordinates to start
at (being the start of the "writing line"), and the colour to use
(this is optional).

It parses the string, drawing each character in turn.  The "draw_char"
function returns the xy coordinate at which to position the next
characters.
--]]

function Font:write(s,x,y,col)
    x = math.floor(x + .5)
    y = math.floor(y + .5)
    s = tostring(s)
    local u = UTF8(s)
    pushStyle()
    self:setstyle()
    if col then
        tint(col)
    elseif self.tint then
        tint(self.tint)
    end
    for c in u:chars() do
        x,y = self:draw_char(c,x,y)
    end
    popStyle()
    return x,y
end

function Font:int_write(s,x,y,col)
    x = math.floor(x + .5)
    y = math.floor(y + .5)
    s = tostring(s)
    pushStyle()
    self:setstyle()
    if col then
        fill(col)
    elseif self.tint then
        fill(self.tint)
    end
    local w,_ = textSize(s)
    text(s,x,y - self.descent)
    popStyle()
    return x + w,y
end

--[[
This is the same as the "write" method except that we assume that the
input is a list of (decimal) numbers specifying characters via the
utf8 encoding.  The input can either be a single number or a table.
--]]

function Font:write_utf8(s,x,y,col)
    x = math.floor(x + .5)
    y = math.floor(y + .5)
    pushStyle()
    self:setstyle()
    if col then
        tint(col)
    elseif self.tint then
        tint(self.tint)
    end
    if type(s) == "table" then
        for k,c in ipairs(s) do
            x,y = self:draw_char(c,x,y)
        end
    else
        x,y = self:draw_char(s,x,y)
    end
    popStyle()
    return x,y
end

function Font:int_write_utf8(s,x,y,col)
    x = math.floor(x + .5)
    y = math.floor(y + .5)
    if type(s) == "table" then
        s = s:tostring()
    else
        s = utf8dec(s)
    end
    pushStyle()
    self:setstyle()
    if col then
        fill(col)
    elseif self.tint then
        fill(self.tint)
    end
    local w,_ = textSize(s)
    text(s,x,y - self.descent)
    popStyle()
    return x + w,y
end

--[[
This function calls the "draw" function of a character at the
specified xy coordinate and works out the place to put the next
character from the bounding box of the current one.
--]]

function Font:draw_char(c,x,y)
    x = math.floor(x + .5)
    y = math.floor(y + .5)
    c = tonumber(c)
    if self.char[c] then
        local ch,cx,cy
        ch = self.char[c]
        cx = x + ch.bbx[3]
        cy = y + ch.bbx[4]
        ch:draw(cx,cy)
        x = x + ch.dwidth[1]
        y = y + ch.dwidth[2]
    end
    return x,y
end

function Font:int_draw_char(c,x,y)
    x = math.floor(x + .5)
    y = math.floor(y + .5)
    c = tonumber(c)
    c = string.char(c)
    return self:write(c,x,y)
end

--[[
There are various places in the drawing method where information is
saved for use next time round.  This does all the processing involved
without actually drawing the characters.  It is useful for getting the
width of a string before rendering it to the screen.
--]]

function Font:prepare_char(c,x,y)
    x = math.floor(x + .5)
    y = math.floor(y + .5)
    c = tonumber(c)
    if self.char[c] then
        local ch,cx,cy,nx,ny
        ch = self.char[c]
        cx = ch.bbx[3]
        cy = ch.bbx[4]
        ch:prepare()
        nx = ch.dwidth[1]
        ny = ch.dwidth[2]
        return {ch.image,x,y,cx,cy,nx,ny},x + nx,y + ny
    else
        return {},x,y
    end
end

function Font:int_prepare_char(c,x,y)
    x = math.floor(x + .5)
    y = math.floor(y + .5)
    pushStyle()
    self:setstyle()
    c = tonumber(c)
    c = string.char(c)
    local w,h = textSize(c)
    return {c,x,y,0,- self.descent,w,0},x+w,y
end

--[[
A sentence is a string to be written to the screen in a specified
font.  The purpose of this class is to ensure that repeated
calculations are only carried out once and then their values saved.
--]]

Sentence = class()

--[[
A sentence consists of a UTF8 object, a font, the characters making
up the string (drawn from the font) and some information about how
much space the sentence takes up on the screen.
--]]

function Sentence:init(f,s)
    if type(s) == "string" then
        self.utf8 = UTF8(s)
    elseif type(s) == "table" and s:is_a(UTF8) then
        self.utf8 = s
    elseif type(s) == "number" then
        self.utf8 = UTF8(tostring(s))
    else
        self.utf8 = UTF8("")
    end
    self.font = f
    self.chars = {}
    self.width = 0
    self.lastx = 0
    self.lasty = 0
end

--[[
This sets our string.  As this is probably new, we will need to parse
it afresh so we unset the "prepared" flag.
--]]

function Sentence:setString(s)
    if type(s) == "string" then
        self.utf8 = UTF8(s)
    elseif type(s) == "table" and s:is_a(UTF8) then
        self.utf8 = s
    elseif type(s) == "number" then
        self.utf8 = UTF8(tostring(s))
    else
        self.utf8 = UTF8("")
    end
    self.prepared = false
    self.chars = {}
    self.width = 0
    self.lastx = 0
    self.lasty = 0
end

--[[
This returns our current string.
--]]

function Sentence:getString()
    return self.utf8:tostring()
end

--[[
This returns our current string as a UTF8 object.
--]]

function Sentence:getUTF8()
    return self.utf8
end

--[[
This appends the given string to our stored string.  If we have
already processed our stored string we process the new string as well
(thus ensuring that we only process the new information).
--]]

function Sentence:appendString(u)
    if type(u) == "string" then
        u = UTF8(u)
    end
    self.utf8:append(u)
    if self.prepared then
        local t,x,y
        x = self.lastx
        y = self.lasty
        for c in u:chars() do
            t,x,y = self.font:prepare_char(c,x,y)
            if t[1] then
                table.insert(self.chars,t)
            end
        end
        self.width = x
        self.lastx = x
        self.lasty = y
    end
end

--[[
This is the same as "appendString" except that it prepends the string.
--]]

function Sentence:prependString(u)
    if type(u) == "string" then
        u = UTF8(u)
    end
    self.utf8:prepend(u)
    if self.prepared then
        local t,x,y,l
        x = 0
        y = 0
        l = 0
        for c in u:chars() do
            t,x,y = self.font:prepare_char(c,x,y)
            if t[1] then
                table.insert(self.chars,t,1)
                l = l + 1
            end
        end
        for k,v in ipairs(self.chars) do
            if k > l then
                v[2] = v[2] + x
                v[3] = v[3] + y
            end
        end
        self.width = self.width + x
        self.lastx = self.lastx + x
        self.lasty = self.lasty + y
    end
end

--[[
In this case, the argument is another instance of the Sentence class
and the new one is appended to the current one.
--]]

function Sentence:append(s)
    if self.prepared and s.prepared then
        for k,v in ipairs(s.chars) do
            v[2] = v[2] + self.lastx
            v[3] = v[3] + self.lasty
            table.insert(self.chars,v)
        end
        self.utf8:append(s.utf8)
        self.width = self.width + s.width
        self.lastx = self.lastx + s.lastx
        self.lasty = self.lasty + s.lasty
        return
    elseif self.prepared then
        self:appendString(s.utf8)
        return
    else
        self.utf8:append(s.utf8)
    end
end

--[[
Same as "append" except with prepending.
--]]

function Sentence:prepend(s)
    if self.prepared and s.prepared then
        for k,v in ipairs(self.chars) do
            v[2] = v[2] + s.lastx
            v[3] = v[3] + s.lasty
        end
        for k,v in ipairs(s.chars) do
            table.insert(self.chars,k,v)
        end
        self.utf8:prepend(s.utf8)
        self.width = self.width + s.width
        self.lastx = self.lastx + s.lastx
        self.lasty = self.lasty + s.lasty
        return
    elseif self.prepared then
        self:prependString(s.utf8)
        return
    else
        self.utf8:prepend(s.utf8)
    end
end

--[[
The "push", "unshift", "pop", and "shift" functions are for removing
and inserting characters at the start and end of the Sentence.  The
input for "push" and "unshift" is precisely that returned by "pop" and
"shift".  If you need to know the exact make-up of this input then you
are probably using the wrong function and should use something like
"append" or "appendString" instead.  The idea is that if one Sentence
has worked out the information required for a particular character
then there is no need for the other Sentence to work it out for
itself, so all of that information is passed with the character.
--]]

function Sentence:push(t)
    if self.prepared then
        if t[2] then
            t[2][2] = t[2][2] + self.lastx
            t[2][3] = t[2][3] + self.lasty
            table.insert(self.chars,t[2])
            self.width = self.width + t[2][6]
            self.lastx = self.lastx + t[2][6]
            self.lasty = self.lasty + t[2][7]
        end
    end
    if t[1] then
        self.utf8:append(t[1])
    end
end

function Sentence:unshift(t)
    if self.prepared then
        if t[2] then
            if self.chars[1] then
                t[2][2] = self.chars[1][2] - t[2][6]
                t[2][3] = self.chars[1][3] - t[2][7]
            end
            table.insert(self.chars,1,t[2])
            self.width = self.width + t[2][6]
            self.lastx = self.lastx + t[2][6]
            self.lasty = self.lasty + t[2][7]
        end
    end
    if t[1] then
        self.utf8:prepend(t[1])
    end
end

--[[
This sets our colour.
--]]

function Sentence:setColour(c)
    self.colour = c
end

--[[
This prepares the Sentence for rendering, stepping along the sentence
and working out what characters will be required and their relative
positions.
--]]

function Sentence:prepare()
    if not self.prepared then
        local t,x,y
        x = 0
        y = 0
        self.chars = {}
        for c in self.utf8:chars() do
            t,x,y = self.font:prepare_char(c,x,y)
            if t[1] then
                table.insert(self.chars,t)
            end
        end
        self.prepared = true
        self.width = x
        self.lastx = x
        self.lasty = y
    end
end

--[[
This is the function that actually draws the Sentence (or rather,
which calls the "draw" function of each of the characters).  The
Sentence is meant to be anchored at (0,0) (so that when actually drawn
it is anchored at the given xy coordinate) but this might not be the
case due to some "shift" and "unshift" operations.  To avoid
recalculating the offset each time, we allow for it here and measure
the relative offset of the first character, adjusting all other
characters accordingly.
--]]

function Sentence:draw(x,y)
    local lx,ly
    lx = 0
    ly = 0
    pushStyle()
    self.font:setstyle()
    if self.colour then
        self.font:colour(self.colour)
    else
        print("no colour for " .. self:getString())
    end
    self:prepare()
    if self.chars[1] then
        lx = self.chars[1][2]
        ly = self.chars[1][3]
        --self.lastx = self.lastx - lx
        --self.lasty = self.lasty - ly
    end
    for k,v in ipairs(self.chars) do
        v[2] = v[2] - lx
        v[3] = v[3] - ly
        self.font:render_char(v[1],v[2] + v[4] + x,v[3] + v[5] + y)
    end
    popStyle()
    return self.lastx + x, self.lasty + y
end

--[[
This resets us to a "blank slate".
--]]

function Sentence:clear()
    self.utf8 = UTF8("")
    self.chars = {}
    self.width = 0
    self.lastx = 0
    self.lasty = 0
end

--[[
See the comments before the "push" and "unshift" functions.
--]]

function Sentence:pop()
    local a,b
    a = table.remove(self.chars)
    if a then
        self.width = self.width - a[6]
        self.lastx = self.lastx - a[6]
        self.lasty = self.lasty - a[7]
        b = self.utf8:sub(-1,-1)
        self.utf8 = self.utf8:sub(1,-2)
    else
        self.width = 0
        self.lastx = 0
        self.lasty = 0
        self.utf8 = UTF8("")
    end
    return {b,a}
end

function Sentence:shift()
    local a
    a = table.remove(self.chars,1)
    if a then
        self.width = self.width - a[6]
        self.lastx = self.lastx - a[6]
        self.lasty = self.lasty - a[7]
        b = self.utf8:sub(1,1)
        self.utf8 = self.utf8:sub(2,-1)
    else
        self.width = 0
        self.lastx = 0
        self.lasty = 0
        self.utf8 = UTF8("")
    end
    return {b,a}
end

--[[
A "Textarea" is a list of lines which are drawn on the screen in a box
with an optional title.  The lines are scrolled so that, by default,
the last lines are displayed.  The lines are wrapped to the width of
the area.  The Textarea reacts to touches in the following way.  It
can be moved by dragging the title, so long as the title stays on the
screen; a single tap moves it so that it is wholly on the screen; a
double tap either hides or shows the actual text (other than the
title); a moving touch in the main text area scrolls the text in the
opposite direction (this may change - I am not sure how intuitive this
is as yet).
--]]

Textarea = class()

--[[
Our initial information is a font, an xy coordinate, our width and
height in characters, an anchor, and a title.  The anchor and title
are optional, but if the title is given then the anchor must be (but
can be blank).

The anchor is used to interpret the xy coordinate as a position on the
boundary of the area so that it can be positioned without needing to
compute beforehand its actual height and width (particularly as these
will depend on the font).
--]]

function Textarea:init(f,x,y,w,h,a,t)
    self.font = f
    self.colour = Colour.svg.DarkSlateBlue
    self.textColour = Colour.svg.White
    self.cwidth = w
    self.totlines = h
    self.sep = 10
    self.active = false
    self.lh = self.font:lineheight() + self.sep
    self.height = h * self.lh + self.sep
    if t then
        self.title = Sentence(self.font,t)
        self.title:prepare()
        self.title:setColour(self.textColour)
        self.height = self.height + self.lh
        self.twidth = self.title.width + 2*self.sep
    end
    self.txtwidth = w * self.font:charWidth() + 2*self.sep
    self.width = self.txtwidth
    self.lines = {}
    self.numlines = 0
    if a then
        self.x, self.y = RectAnchorAt(x,y,self.width,self.height,a)
    else
        self.x = x
        self.y = y
    end
    self.offset = 0
end

--[[
This is our "draw" method which puts our information on the screen
assuming that we are "active".  Exactly what is drawn depends on
whether or not we have a title and whether or not the main area has
been "hidden" so that only the title shows.  If all is shown then we
figure out which lines to show and print only those.  This depends on
the total number of lines, the number of lines that we can show, and
the "offset", which is usually specified by a touch.
--]]

function Textarea:draw()
    if not self.active then
        return
    end
    pushStyle()
    local m,n,y,lh,x
    lh = self.lh
    x = self.x + self.sep
    y = self.y + self.sep
    n = self.numlines - self.offset
    if n < 0 then
        n = self.totlines
    end
    m = n - self.totlines + 1
    if m < 1 then
        if self.vfill then
            y = y - (m - 1) * lh
        end
        m = 1
    end
    
    fill(self.colour)
    if self.title and self.onlyTitle then
        RoundedRectangle(self.x,
        self.y + self.height - self.lh - self.sep,
        self.width,
        self.lh + self.sep,
        self.sep)
    else
        RoundedRectangle(self.x,self.y,self.width,self.height,self.sep)
        for k = n,m,-1 do
        if self.lines[k] then
            self.lines[k]:draw(x,y)
            y = y + lh
        end
        end
    end
    if self.title then
        y = self.y + self.height - self.lh
        self.title:draw(x,y)
    end
end

--[[
This adds a line or lines to the stack.  The lines are wrapped (using
code based on contributions to the lua-users wiki) to the Textarea
width with breaks inserted at spaces (if possible).
--]]

function Textarea:addLine(...)
    local s,w,u
    w = self.cwidth
    for k,v in ipairs(arg) do
        u = UTF8(v)
        for l in u:splitBy(w) do
            s = Sentence(self.font,l)
            s:setColour(self.textColour)
            table.insert(self.lines,s)
            self.numlines = self.numlines + 1
        end
    end
end

--[[
This figures out if the touch was inside our "bounding box" and claims
it if it was.
--]]

function Textarea:isTouchedBy(t)
    if not self.active then
        return false
    end
    if t.x < self.x then
        return false
    end
    if t.x > self.x + self.width then
        return false
    end
    if self.onlyTitle then
        if t.y < self.y + self.height - self.lh - self.sep then
            return false
        end
    else
    if t.y < self.y then
        return false
    end
    end
    if t.y > self.y + self.height then
        return false
    end
    return true
end

--[[
This is our touch processor that figures out what action to take
according to the touch information available.  The currently
understood gestures are:

Single tap: move so that the whole area is visible.

Double tap: toggle display of the main area (title is always shown).

Move on title: moves the text area around the screen, ensuring that
the title is always visible.

Move on main: scrolls the text.
--]]

function Textarea:processTouches(g)
    local t = g.touchesArr[1]
    local ty = t.touch.y
    local y = self.y
    local h = self.height
    local lh = self.lh
    if t.touch.state == BEGAN and self.title then
        if ty > y + h - lh then
            g.type.onTitle = true
        end
    end
    if g.type.tap then
        if g.type.finished then
        if g.num == 1 then
            self:makeVisible()
        elseif g.num == 2 then
            if self.onlyTitle then
                self.onlyTitle = false
                self.width = self.txtwidth
            else
                self.onlyTitle = true
                self.width = self.twidth
            end
        end
        end
    elseif g.updated then
                if g.type.onTitle then
                    local y = t.touch.deltaY
                    local x = t.touch.deltaX
                    self:ensureTitleVisible(x,y)
                else
                    local tfy = t.firsttouch.y
                    local o = math.floor((ty - tfy)/lh)
                    self.offset = math.max(0,math.min(self.totlines,o))
                end
                
    end
    g:noted()
    if g.type.finished then
        g:reset()
        self.offset = 0
    end
end

--[[
This function adjusts the xy coordinate to ensure that the whole
Textarea is visible.
--]]

function Textarea:makeVisible()
    local x = self.x
    local y = self.y
    local w = self.width
    local h = self.height
    x = math.max(0,math.min(WIDTH - w,x))
    y = math.max(0,math.min(HEIGHT - h,y))
    self.x = x
    self.y = y
end

--[[
This function adjusts the xy coordinate to ensure that the title
of the Textarea is visible.
--]]

function Textarea:ensureTitleVisible(x,y)
    local w = self.width
    local h = self.height
    local lh = self.lh + self.sep
    x = x + self.x
    y = y + self.y
    x = math.max(0,math.min(WIDTH - w,x))
    y = math.max(lh - h,math.min(HEIGHT - h,y))
    self.x = x
    self.y = y
end

--[[
This is a character in a font.  The information is to be initially
constructed from a BDF font file.  At present, this information is
specified by accessing the actual attributes.  Later versions may be
able to read this information directly from the font file; at present,
the conversion is carried out by a Perl scrip.

Characters are rendered as sprites so the first time that a character
is drawn (or otherwise processed) then it converts the raw information
into a sprite which is then used on subsequent calls.
--]]

Char = class()

function Char:init()
    self.bitmap = {}
    self.bbx = {}
    self.dwidth = {}
end

--[[
This is a wrapper around the preparation function for the character so
that we only call that once.
--]]

function Char:prepare()
    if not self.prepared then
        self:mkImage()
    end
    self.prepared = true
end

--[[
This is the function that renders the BDF information to a sprite.
--]]

function Char:mkImage()
    self.image = image(self.font.bbx[1], self.font.bbx[2])
    local i,j,b
    j = self.bbx[2]
    for k,v in pairs(self.bitmap) do
        i = 1
        b = Hex2Bin(v)
        for l in string.gfind(b, ".") do
            
            if l == "1" then
                self.image:set(i,j,255,255,255)
            end
            i = i + 1
        end
        j = j - 1
    end
end

--[[
This draws the character at the specified coordinate.
--]]

function Char:draw(x,y)
    self:prepare()
    sprite(self.image,x,y)
end

--[[
This is an auxilliary function used by the "Textarea" class which
works out the coordinate of a rectangle as specified by an "anchor"
(the notions used here are inspired by the "TikZ/PGF" LaTeX package.
--]]

function RectAnchorAt(x,y,w,h,a)
    -- (x,y) is south-west
    if a == "north" then
        return x - w/2, y - h
    end
    if a == "south" then
        return x - w/2, y
    end
    if a == "east" then
        return x - w, y - h/2
    end
    if a == "west" then
        return x, y - h/2
    end
    if a == "north west" then
        return x, y - h
    end
    if a == "south east" then
        return x - w, y
    end
    if a == "north east" then
        return x - w, y - h
    end
    if a == "south west" then
        return x, y
    end
    if a == "centre" then
        return x - w/2, y - h/2
    end
    if a == "center" then
        return x - w/2, y - h/2
    end
    return x,y
end
