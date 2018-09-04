displayMode(FULLSCREEN)
hideKeyboard()
supportedOrientations(LANDSCAPE_ANY)

function setup()
    --mfont = Font({name = "Futura-Medium",size = 160})
    mfont = Font({name = "Helvetica",size = 160})
    lfont = Font({name = "Futura-Medium",size = 24})
    anagram = Anagram(mfont,lfont)
end

-- This function gets called once every frame
function draw()
    -- process touches and taps
    background(0,0,0)
    
    --pushStyle()
    --fill(255)
    --textMode(CORNER)
    --text("Drag letters to form words!", 20, HEIGHT - 50)
    --popStyle()
    
    -- draw elements
    anagram:draw(WIDTH/2,HEIGHT/2)
end


