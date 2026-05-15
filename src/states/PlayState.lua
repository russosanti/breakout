--[[
    CS50 2D
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

local POWER_UPS = {
    HEALTH = 1,
    MULTI_BALL = 2,
    KEY = 3
}

local BALL_MIN_DY = -60
local BALL_MAX_DY = -50

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.lockCount = params.lockCount
    self.keyCount = params.keyCount
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = { params.ball }
    self.level = params.level
    self.powerUps = {}

    self.recoverPoints = params.recoverPoints

    -- give ball random starting velocity
    self.balls[1].dx = math.random(-200, 200)
    self.balls[1].dy = math.random(BALL_MIN_DY, BALL_MAX_DY)
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    
    for _, ball in ipairs(self.balls) do
        ball:update(dt)

        self:handlePaddleCollision(ball)

        -- detect collision across all bricks with the ball
        for k, brick in pairs(self.bricks) do

            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then
                self:handleBrickCollision(ball, brick)

                -- only allow colliding with one brick, for corners
                break
            end
        end

        -- if ball goes below bounds, mark it as not in play (effectively removing it from the game)
        if ball.y >= VIRTUAL_HEIGHT then
            ball.inPlay = false
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    -- for rendering power-ups
    for k, power in pairs(self.powerUps) do
        power:update(dt)
        if power:collides(self.paddle) then
            self:collectPowerUp(power)
        end
    end

    -- removes balls off play
    for i = #self.balls, 1, -1 do
        if not self.balls[i].inPlay then
            table.remove(self.balls, i)
        end
    end

    if #self.balls < 1 then
        self:loseLife()
    end

    -- removes power ups off play
    for i = #self.powerUps, 1, -1 do
        if not self.powerUps[i].inPlay then
            table.remove(self.powerUps, i)
        end
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:handlePaddleCollision(ball)
    if not ball:collides(self.paddle) then
        return
    end

    -- raise ball above paddle in case it goes below it, then reverse dy
    ball.y = self.paddle.y - ball.height
    ball.dy = -ball.dy

    local isPaddleMovingLeft = self.paddle.dx < 0
    local isPaddleMovingRight = self.paddle.dx > 0
    local paddleCenter = self.paddle.x + self.paddle.width / 2

    -- adjustable values for the feel of bounce speed/angle
    local startingBounceDX = 50
    local bounceAngleMultiplier = 8

    if ball.x < paddleCenter and isPaddleMovingLeft then
        local ballOffset = paddleCenter - ball.x
        ball.dx = -startingBounceDX - bounceAngleMultiplier * ballOffset
    elseif ball.x > paddleCenter and isPaddleMovingRight then
        local ballOffset = ball.x - paddleCenter
        ball.dx = startingBounceDX + bounceAngleMultiplier * ballOffset
    end

    gSounds['paddle-hit']:play()
end

function PlayState:handleBrickCollision(ball, brick)
    self:applyBrickHit(brick)
    self:spawnPowerUpFromBrick(brick)
    self:applyScoreRewards()
    self:checkVictoryTransition()
    self:resolveBrickCollision(ball, brick)
end

function PlayState:applyBrickHit(brick)
    if brick.isLock then
        if self.keyCount > 0 then
            self.score = self.score + 1000
            self.keyCount = self.keyCount - 1
            self.lockCount = self.lockCount - 1
            brick:unlock(self.level)
        else
            gSounds['wall-hit']:play()
        end
    else
        self.score = self.score + (brick.tier * 200 + brick.color * 25)
        brick:hit()
    end
end

function PlayState:spawnPowerUpFromBrick(brick)
    local pool = nil

    if brick.isLock then
        if self.keyCount < self.lockCount and math.random(4) == 1 then
            pool = {POWER_UPS.KEY}
        end
    elseif not brick.inPlay and math.random(4) == 1 then
        -- extra balls are the default power up
        pool = {POWER_UPS.MULTI_BALL, POWER_UPS.MULTI_BALL, POWER_UPS.MULTI_BALL}

        if self.health < 3 then
            table.insert(pool, POWER_UPS.HEALTH)
        end

        if self.keyCount < self.lockCount then
            table.insert(pool, POWER_UPS.KEY)
        end
    end

    if pool == nil then
        return
    end

    local type = pool[math.random(#pool)]
    table.insert(self.powerUps, PowerUp(type, brick.x + brick.width / 2 - 8, brick.y))
end

function PlayState:applyScoreRewards()
    if self.score > self.recoverPoints then
        self.health = math.min(3, self.health + 1)
        self.recoverPoints = math.min(100000, self.recoverPoints * 2)
        gSounds['recover']:play()
    end

    if self.score >= self.paddle.nextSizeScore then
        self.paddle:upgradeSize(self.score)
        gSounds['confirm']:play()
    end
end

function PlayState:checkVictoryTransition()
    if not self:checkVictory() then
        return
    end

    gSounds['victory']:play()

    gStateMachine:change('victory', {
        level = self.level,
        paddle = self.paddle,
        health = self.health,
        score = self.score,
        highScores = self.highScores,
        ball = self.balls[1],
        recoverPoints = self.recoverPoints
    })
end

function PlayState:resolveBrickCollision(ball, brick)
    local ballRadius = ball.width / 2
    local brickCenterX = brick.x + brick.width / 2
    local brickCenterY = brick.y + brick.height / 2
    local ballCenterX = ball.x + ballRadius
    local ballCenterY = ball.y + ballRadius

    local offsetX = brickCenterX - ballCenterX
    local offsetY = brickCenterY - ballCenterY

    local penetrationX = brick.width / 2 + ballRadius - math.abs(offsetX)
    local penetrationY = brick.height / 2 + ballRadius - math.abs(offsetY)

    if penetrationX < penetrationY then
        ball.dx = -ball.dx
        ball.x = ball.x + (offsetX > 0 and -penetrationX or penetrationX)
    else
        ball.dy = -ball.dy
        ball.y = ball.y + (offsetY > 0 and -penetrationY or penetrationY)
    end

    -- slightly scale the y velocity to speed up the game, capping at +- 150
    if math.abs(ball.dy) < 150 then
        ball.dy = ball.dy * 1.02
    end
end

function PlayState:collectPowerUp(power)
    power.inPlay = false

    if power.type == POWER_UPS.HEALTH then
        if self.health < 3 then
            self.health = self.health + 1
            gSounds['recover']:play()
        end
    elseif power.type == POWER_UPS.KEY then
        self.keyCount = self.keyCount + 1
    elseif power.type == POWER_UPS.MULTI_BALL then
        self:newBall()
        self:newBall()
    end
end

function PlayState:loseLife()
    self.health = self.health - 1
    gSounds['hurt']:play()

    if self.health == 0 then
        gStateMachine:change('game-over', {
            score = self.score,
            highScores = self.highScores
        })
    else
        self.paddle:downgradeSize(self.score)
        gStateMachine:change('serve', {
            paddle = self.paddle,
            bricks = self.bricks,
            lockCount = self.lockCount,
            health = self.health,
            score = self.score,
            highScores = self.highScores,
            level = self.level,
            recoverPoints = self.recoverPoints
        })
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    -- render all power ups
    for _, powers in pairs(self.powerUps) do
        powers:render()
    end

    self.paddle:render()
    
    -- render all balls
    for _, ball in pairs(self.balls) do
        ball:render()
    end

    renderKeyCount(self.keyCount)
    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end
    end

    return true
end

function PlayState:newBall()
    local newBall = Ball(math.random(7))
    newBall.x = self.paddle.x + (self.paddle.width / 2) - newBall.width / 2
    newBall.y = self.paddle.y - newBall.height
    -- give ball random starting velocity
    newBall.dx = math.random(-200, 200)
    newBall.dy = math.random(BALL_MIN_DY, BALL_MAX_DY)
    table.insert(self.balls, newBall)
end
