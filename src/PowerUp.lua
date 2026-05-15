--[[
    CS50 2D
    Breakout Remake

    -- Power Up Class --

    Author: Santiago Russo

    Represents a power-up item that will fall from bricks and affect the player's paddle when collected.
    the paddle.
]]

PowerUp = Class{}

--[[
    Expects a skin to be passed in, which will determine the type of power-up and its appearance.
    x y are the starting coordinates of the power-up.
]]
function PowerUp:init(skin, x, y)
    -- simple positional and dimensional variables
    self.width = 16
    self.height = 16
    self.x = x
    self.y = y

    -- gravity fall velocity
    self.dy = 60

    -- this will affect skin and type
    self.type = skin
    self.inPlay = true
end

--[[
    Expects an argument with the paddle, and returns true if the bounding boxes of this and the argument overlap.
]]
function PowerUp:collides(paddle)
    return Collides(self, paddle)
end

function PowerUp:update(dt)
    self.y = self.y + self.dy * dt
    if self.y > VIRTUAL_HEIGHT then
        self.inPlay = false
    end
end

function PowerUp:render()
    -- gTexture is our global texture for all blocks
    -- gPowerUpFrames is a table of quads mapping to each individual power-up skin in the texture
    love.graphics.draw(gTextures['main'], gFrames['powers'][self.type],
        self.x, self.y)
end
