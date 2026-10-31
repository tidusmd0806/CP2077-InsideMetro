local Player = {}
Player.__index = Player

function Player:New()
    -- instance --
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "Player")
    -- static --
    obj.workspot_entity_path = "base\\itm\\metro_workspot.ent"
    obj.workspot_name = "metro_workspot"
    -- dynamic --
    obj.is_ready = false
    obj.workspot_entity = nil
    obj.workspot_entity_id = nil
    return setmetatable(obj, self)
end

function Player:DeleteWorkspot()
    if self.workspot_entity ~= nil then
        exEntitySpawner.Despawn(self.workspot_entity)
        self.workspot_entity_id = nil
    end
end

function Player:GetWorkspotEntity()
    return self.workspot_entity
end

function Player:PlayPose(pose_name, workspot_pos, workspot_angle)

    local player = Game.GetPlayer()
    local workspot_transform = WorldTransform.new()
    workspot_transform:SetPosition(workspot_pos)
    workspot_transform:SetOrientationEuler(workspot_angle)

    if self.workspot_entity_id ~= nil then
        self.log_obj:Record(LogLevel.Trace, "Delete workspot")
        self:DeleteWorkspot()
    end

    self.log_obj:Record(LogLevel.Info, string.format("PlayPose[%s]: spawn requested at (%.2f,%.2f,%.2f)",
        pose_name, workspot_pos.x, workspot_pos.y, workspot_pos.z))
    self.workspot_entity_id = exEntitySpawner.Spawn(self.workspot_entity_path, workspot_transform, '')
    Cron.Every(0.01, {tick = 1}, function(timer)
        self.workspot_entity = Game.FindEntityByID(self.workspot_entity_id)
        if self.workspot_entity ~= nil then
            local found_pos = self.workspot_entity:GetWorldPosition()
            self.log_obj:Record(LogLevel.Info, string.format(
                "PlayPose: entity found at (%.2f,%.2f,%.2f) after %d ticks (requested %.2f,%.2f,%.2f)",
                found_pos.x, found_pos.y, found_pos.z, timer.tick,
                workspot_pos.x, workspot_pos.y, workspot_pos.z))
            Game.GetWorkspotSystem():StopInDevice(player)
            Cron.After(0.1, function()
                local play_pos = self.workspot_entity:GetWorldPosition()
                self.log_obj:Record(LogLevel.Info, string.format(
                    "PlayPose: playing anim at entity pos (%.2f,%.2f,%.2f)",
                    play_pos.x, play_pos.y, play_pos.z))
                Game.GetWorkspotSystem():PlayInDeviceSimple(self.workspot_entity, player, true, self.workspot_name, nil, nil, 0, 1, nil)
                Game.GetWorkspotSystem():SendJumpToAnimEnt(player, pose_name, true)
            end)
            Cron.Halt(timer)
        end
    end)

end

return Player