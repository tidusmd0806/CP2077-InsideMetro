local Player = {}
Player.__index = Player

function Player:New()
    -- instance --
    local obj = {}
    -- dynamic --
    obj.player = nil
    obj.position = nil
    obj.forward = nil
    obj.angle = nil
    return setmetatable(obj, self)
end

function Player:Update()
    self.player = Game.GetPlayer()
    self.position = self.player:GetWorldPosition()
    self.forward = self.player:GetWorldForward()
    self.angle = self.player:GetWorldOrientation():ToEulerAngles()
end

function Player:GetPuppet()
    return self.player
end

function Player:GetPosition()
    return self.position
end

function Player:GetForward()
    return self.forward
end

function Player:GetAngle()
    return self.angle
end

return Player