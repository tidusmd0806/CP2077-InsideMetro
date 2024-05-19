local Event = {}
Event.__index = Event

function Event:New(player_obj, metro_obj)
    -- instance --
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "Event")
    obj.player_obj = player_obj
    obj.metro_obj = metro_obj
    -- dynamic --
    obj.current_status = Def.State.OutsideMetro
    obj.is_in_fast_travel = false
    obj.prev_player_local_pos = nil
    obj.prev_npc_local_pos = nil
    obj.is_on_ground = false
    obj.is_touching_ground = false
    return setmetatable(obj, self)
end

function Event:SetObserverGameUI()

    GameUI.Observe("FastTravelStart", function()
        self.is_in_fast_travel = true
    end)

    GameUI.Observe("FastTravelFinish", function()
        self.is_in_fast_travel = false
    end)

end

function Event:SetTouchGroundObserver()

    Override("LocomotionTransition", "IsTouchingGround", function(this, script_interface, wrapped_method)
        self.is_on_ground = wrapped_method(script_interface)
        return self.is_on_ground
    end)

end

function Event:SetStatus(status)

    if self.current_status == Def.State.OutsideMetro and status == Def.State.SitInsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status to SitInsideMetro")
        self.current_status = Def.State.SitInsideMetro
        return true
    elseif self.current_status == Def.State.SitInsideMetro and status == Def.State.StandInsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status to StandInsideMetro")
        self.current_status = Def.State.StandInsideMetro
        return true
    elseif self.current_status == Def.State.StandInsideMetro and status == Def.State.WalkInsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status to WalkInsideMetro")
        self.current_status = Def.State.WalkInsideMetro
        return true
    elseif self.current_status == Def.State.WalkInsideMetro and status == Def.State.StandInsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status to StandInsideMetro")
        self.current_status = Def.State.StandInsideMetro
        return true
    elseif self.current_status == Def.State.StandInsideMetro and status == Def.State.SitInsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status to SitInsideMetro")
        self.current_status = Def.State.SitInsideMetro
        return true
    elseif self.current_status == Def.State.SitInsideMetro and status == Def.State.OutsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status to OutsideMetro")
        self.current_status = Def.State.OutsideMetro
    else
        self.log_obj:Record(LogLevel.Critical, "Change Status Failed")
        return false
    end
end

function Event:GetStatus()
    return self.current_status
end

function Event:CheckAllEvents()

    if self.current_status == Def.State.OutsideMetro then
        self:CheckInsideMetro()
    elseif self.current_status == Def.State.SitInsideMetro then
        self:CheckOutsideMetro()
        self:CheckSeatPosition()
    elseif self.current_status == Def.State.StandInsideMetro then
        self:CheckInvalidPosition()
        self:CheckSeatArea()
        self:CheckTouchGround()
    elseif self.current_status == Def.State.WalkInsideMetro then
        self:CheckInvalidPosition()
        self:CheckSeatArea()
        self:CheckTouchGround()
    end

end

function Event:CheckInsideMetro()

    if self.metro_obj:SetEntity() then
        self.log_obj:Record(LogLevel.Info, "Detect Inside Metro")
        self:SetStatus(Def.State.SitInsideMetro)
        Cron.Every(0.1, {tick = 1}, function(timer)
            timer.tick = timer.tick + 1
            if self.is_in_fast_travel and timer.tick < 100 then
                return
            end
            self.metro_obj:Initialize()
            self.player_obj:Initialize()
            Cron.Halt(timer)
        end)
    end

end

function Event:CheckOutsideMetro()

    if not self.metro_obj:SetEntity() then
        self.log_obj:Record(LogLevel.Info, "Detect Outside Metro")
        self:SetStatus(Def.State.OutsideMetro)
        self.metro_obj:Uninitialize()
        self.player_obj:Uninitialize()
    end

end

function Event:CheckSeatArea()

    local player_local_pos = self.metro_obj:GetAccurateLocalPosition(Game.GetPlayer():GetWorldPosition())
    if self.metro_obj:IsInSeatArea(player_local_pos) then
        self.log_obj:Record(LogLevel.Trace, "Player is in Seat Area")
        self:SetStatus(Def.State.StandInsideMetro)
    else
        self.log_obj:Record(LogLevel.Trace, "Player is not in Seat Area")
        self:SetStatus(Def.State.WalkInsideMetro)
    end

end

function Event:CheckInvalidPosition()

    local player_local_pos = self.metro_obj:GetAccurateLocalPosition(Game.GetPlayer():GetWorldPosition())
    if not self.metro_obj:IsInMetro(player_local_pos) then
        self.log_obj:Record(LogLevel.Warning, "Player is not in Metro")
        self.metro_obj:TeleportToDefaultPosition()
    end

end

function Event:CheckSeatPosition()

    if self.metro_obj:GetSpeed() < 0.001 then
        self.log_obj:Record(LogLevel.Debug, "Player is in Seat Area")
        self.metro_obj:SetPlayerSeatPosition()
    end

end

-- function Event:CheckInvalidMove()

--     local player_local_pos = self.metro_obj:GetAccurateLocalPosition(Game.GetPlayer():GetWorldPosition())
--     local noc_local_pos = self.metro_obj:GetAccurateLocalPosition(self.metro_obj.measurement_npc_entity:GetWorldPosition())
--     if self.prev_player_local_pos == nil then
--         self.prev_player_local_pos = player_local_pos
--         self.prev_npc_local_pos = noc_local_pos
--         return
--     end
--     local prev_distance = Vector4.Distance(self.prev_player_local_pos, self.prev_npc_local_pos)
--     local current_distance = Vector4.Distance(player_local_pos, noc_local_pos)
--     local speed = (current_distance - prev_distance) / 0.01
--     -- if math.abs(speed) > 15 then
--     --     self.log_obj:Record(LogLevel.Warning, "Invalid Move")
--     --     local angle = Game.GetPlayer():GetWorldOrientation():ToEulerAngles()
--     --     Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), self.metro_obj:GetAccurateWorldPosition(self.prev_player_local_pos), angle)
--     -- end
--     self.prev_player_local_pos = player_local_pos
--     self.prev_npc_local_pos = noc_local_pos

-- end

function Event:CheckTouchGround()

    if self.is_touching_ground then
        return
    end
    if self.is_on_ground then
        return
    end
    self.is_touching_ground = true
    Cron.Every(0.001, {tick = 1}, function(timer)
        local player = Game.GetPlayer()
        local pos = player:GetWorldPosition()
        pos.z = pos.z - 0.2
        local angle = player:GetWorldOrientation():ToEulerAngles()
        Game.GetTeleportationFacility():Teleport(player, pos, angle)
        if self.is_on_ground then
            self.is_touching_ground = false
            Cron.Halt(timer)
        end
    end)
end

return Event