Anagram = class()

function Anagram:init(f,lf)
    math.randomseed(os.time())
    self.timer = 0
    self.fpm = 70
    self.font = f
    self.lfont = lf
    self.lh = f:lineheight()
    self.llh = lf:lineheight()
    self.colour = Colour.svg.White
    self.highlight = Colour.svg.Red
    self.rightcol = Colour.svg.HotPink
    self.wlist = {}
    self.words = {}
    local s
    self.ww = 0
    self.mwords = math.floor(HEIGHT/self.llh)
    self.nwords = 0
    local n = 0
    local words = Words
    for k,v in ipairs(words) do
        print(k,v)
        n = n + 1
    end
    --self.mwords = math.min(self.mwords,n)
    self.mwords = n
    for i = 1,n do
        j = math.random(i,n)
        words[i],words[j] = words[j],words[i]
    end
    local st
    if n <= self.mwords then
        st = 1
    else
        st = math.random(1,n - self.mwords + 1)
    end
    local abc = 0
    for i = st,st + self.mwords-1 do
        s = Sentence(lfont,words[i])
        s:prepare()
        s:setColour(Colour.svg.White)
        self.ww = math.max(self.ww,s.width)
        self.nwords = self.nwords + 1
        table.insert(self.wlist,s) 
        table.insert(self.words,words[i])
        abc = abc + 1
    end
    self.ww = WIDTH - self.ww - 10
    self:newword()
end

function Anagram:newword()
    print(self.word)
    local nword = self.word
    while nword == self.word do
        nword = self.words[math.random(1,self.mwords)]
    end
    self.word = nword
    local s = Sentence(self.font,self.word)
    s:prepare()
    self.cw = s.width
    self.l = 0
    self.chars = {}
    local uword = UTF8(self.word)
    for c in uword:chars() do
        self.l = self.l + 1
        local l = self.l
        table.insert(self.chars,{c,l})
    end
    local j,wd,ch,l
    --wd = self.word
    --print("word: " .. self.word)
    --while (wd == self.word) do
    --for i = 1,self.l do
    --    j = math.random(i,self.l)
    --    self.chars[i],self.chars[j] = self.chars[j],self.chars[i]
    --end
    wd = ""
    for k,c in ipairs(self.chars) do
        ch,l = unpack(c)
        wd = wd .. string.char(ch)
    end
    --print("wd: " .. wd)
    --end
    self.lh = self.font:lineheight()
    
    self.x = 0
    self.y = 0
    self.xx = {}
    self.guessed = false
end

function Anagram:draw(x,y)
    self.timer = self.timer + DeltaTime
    if self.timer > (60 / self.fpm) then
        self.timer = 0
        self:newword()
    end
    local st = 0
    local h = HEIGHT
    fill(255, 0, 0, 255)
    --[[
    for k,v in ipairs(self.wlist) do
        h = h - self.llh
        v:draw(self.ww,h)
    end
    --]]
    x = x - self.cw/2
    local col = self.colour
    local letcol
    self.x = x
    self.y = y
    self.xx = {}
    self.fx = {}
    local ch
    local l
    local right = false
    local s = {}
    for k,c in ipairs(self.chars) do
        ch,l = unpack(c)
        table.insert(s,ch)
    end
    s = string.char(unpack(s))
    if s == self.word and not self.intouch then
        right = true
    end
    if right then
        col = self.rightcol
    end
    local ox
    local lh = self.lh/2
    for k,c in ipairs(self.chars) do
        ch,l = unpack(c)
        if k <= st then
            letcol = color(0,0,0,0)
        elseif self.letter == k then
            letcol = self.highlight
        else
            letcol = col
        end
        ox = x
        x,y = self.font:write_utf8(ch,x,y,letcol)
        table.insert(self.xx,x)
        table.insert(self.fx,{(x + ox)/2,y + lh})
    end
end
