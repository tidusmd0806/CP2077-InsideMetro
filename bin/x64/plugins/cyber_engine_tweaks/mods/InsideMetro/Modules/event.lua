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
    obj.is_in_fast_tracel = false
    return setmetatable(obj, self)
end

function Event:SetObserverGameUI()

    GameUI.Observe("FastTravelStart", function()
        self.is_in_fast_tracel = true
    end)

    GameUI.Observe("FastTravelFinish", function()
        self.is_in_fast_tracel = false
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

function Event:CheckAllEvents()

    if self.current_status == Def.State.OutsideMetro then
        self:CheckInsideMetro()
    elseif self.current_status == Def.State.SitInsideMetro then
        self:CheckOutsideMetro()
    elseif self.current_status == Def.State.StandInsideMetro then
        self:CheckInvalidPosition()
        self:CheckSeatArea()
    elseif self.current_status == Def.State.WalkInsideMetro then
        self:CheckInvalidPosition()
        self:CheckSeatArea()
    end

end

function Event:CheckInsideMetro()

    if self.metro_obj:SetEntity() then
        self.log_obj:Record(LogLevel.Info, "Detect Inside Metro")
        self:SetStatus(Def.State.SitInsideMetro)
        Cron.Every(0.1, {tick = 1}, function(timer)
            timer.tick = timer.tick + 1
            if self.is_in_fast_tracel and timer.tick < 100 then
                return
            end
            Cron.After(5.0, function()
                self.metro_obj:Init()
            end)
            Cron.Halt(timer)
        end)
    end

end

function Event:CheckOutsideMetro()

    if not self.metro_obj:SetEntity() then
        self.log_obj:Record(LogLevel.Info, "Detect Outside Metro")
        self:SetStatus(Def.State.OutsideMetro)
    end

end

function Event:CheckSeatArea()
  
    local player_local_pos = self.metro_obj:GetPlayerLocalPosition()
    if self.metro_obj:IsInSeatArea(player_local_pos) then
        self.log_obj:Record(LogLevel.Trace, "Player is in Seat Area")
        self:SetStatus(Def.State.StandInsideMetro)
    else
        self.log_obj:Record(LogLevel.Trace, "Player is not in Seat Area")
        self:SetStatus(Def.State.WalkInsideMetro)
    end
end

function Event:CheckInvalidPosition()
    local player_local_pos = self.metro_obj:GetPlayerLocalPosition()
    if not self.metro_obj:IsInMetro(player_local_pos) then
        self.log_obj:Record(LogLevel.Warning, "Player is not in Metro")
        self.metro_obj:TeleportToDefaultPosition()
    end
end

return Event