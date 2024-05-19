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
    -- obj.stand_up_anim = "player__sit_chair_lean180__2h_on_lap__01__to__stand__2h_on_sides__01__turn0__01"
    -- dynamic --
    obj.is_ready = false
    obj.workspot_entity = nil
    obj.workspot_entity_id = nil
    obj.world_position = nil
    obj.current_speed = 0
    obj.is_fail_safe_mode = false
    return setmetatable(obj, self)
end

function Player:Initialize()
    self.is_ready = true
    self:SetSpeedObserver()
end

function Player:Uninitialize()
    self.is_ready = false
    self:DeleteWorkspot()
    self:SetFailSafeMode(false)
end

function Player:SetFailSafeMode(is_fail_safe_mode)
    self.is_fail_safe_mode = is_fail_safe_mode
end

function Player:SetSpeedObserver()

    Cron.Every(0.01, {tick = 1}, function(timer)
        timer.tick = timer.tick + 1
        local player = Game.GetPlayer()
        if self.world_position == nil then
            self.world_position = player:GetWorldPosition()
            return
        end
        local current_pos = player:GetWorldPosition()
        local distance = Vector4.Distance(current_pos, self.world_position)
        self.current_speed = distance / 0.01
        self.world_position = current_pos
        if not self.is_ready then
            Cron.Helt(timer)
        end
    end)

end

-- function Player:GetSpeed()
--     return self.current_speed
-- end

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

    self.log_obj:Record(LogLevel.Trace, "Spawn workspot")
    self.workspot_entity_id = exEntitySpawner.Spawn(self.workspot_entity_path, workspot_transform, '')
    Cron.Every(0.01, {tick = 1}, function(timer)
        self.workspot_entity = Game.FindEntityByID(self.workspot_entity_id)
        if self.workspot_entity ~= nil then
            Game.GetWorkspotSystem():StopInDevice(player)
            Cron.After(0.1, function()
                Game.GetWorkspotSystem():PlayInDeviceSimple(self.workspot_entity, player, true, self.workspot_name, nil, nil, 0, 1, nil)
                Game.GetWorkspotSystem():SendJumpToAnimEnt(player, pose_name, true)
            end)
            Cron.Halt(timer)
        end
    end)

end

return Player