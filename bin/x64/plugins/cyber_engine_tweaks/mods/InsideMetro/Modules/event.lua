local HUD = require("Modules/hud.lua")

local Event = {}
Event.__index = Event

function Event:New(player_obj, metro_obj)
    -- instance --
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "Event")
    obj.hud_obj = HUD:New(metro_obj)
    obj.player_obj = player_obj
    obj.metro_obj = metro_obj
    -- dynamic --
    obj.current_status = Def.State.OutsideMetro
    obj.prev_player_local_pos = metro_obj.default_position
    obj.is_on_ground = false
    obj.is_touching_ground = false
    obj.is_sitting = false
    return setmetatable(obj, self)
end

function Event:Initialize()
    self:SetTouchGroundObserver()
    self.hud_obj:Initialize()
end

function Event:ResetParam()

    self.prev_player_local_pos = self.metro_obj.default_position
    self.is_on_ground = false
    self.is_touching_ground = false
    self.is_sitting = false

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
        self:SetRestrictions()
        self.hud_obj:ShowStandHint()
        return true
    elseif self.current_status == Def.State.SitInsideMetro and status == Def.State.StandInsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status to StandInsideMetro")
        self.current_status = Def.State.StandInsideMetro
        self.hud_obj:HideStandHint()
        self.hud_obj:ShowSitHint()
        return true
    elseif self.current_status == Def.State.StandInsideMetro and status == Def.State.WalkInsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status to WalkInsideMetro")
        self.current_status = Def.State.WalkInsideMetro
        self.hud_obj:HideSitHint()
        return true
    elseif self.current_status == Def.State.WalkInsideMetro and status == Def.State.StandInsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status to StandInsideMetro")
        self.current_status = Def.State.StandInsideMetro
        self.hud_obj:ShowSitHint()
        return true
    elseif self.current_status == Def.State.StandInsideMetro and status == Def.State.SitInsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status to SitInsideMetro")
        self.current_status = Def.State.SitInsideMetro
        self.hud_obj:ShowStandHint()
        self.hud_obj:HideSitHint()
        return true
    elseif self.current_status == Def.State.SitInsideMetro and status == Def.State.OutsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status to OutsideMetro")
        self.current_status = Def.State.OutsideMetro
        self.hud_obj:HideStandHint()
        self:RemoveRestrictions()
        self:ResetParam()
        return true
    else
        return false
    end
end

function Event:GetStatus()
    return self.current_status
end

function Event:SetRestrictions()
    local player = Game.GetPlayer()
    SaveLocksManager.RequestSaveLockAdd(CName.new("InsideTheMetro"))
    local no_jump = TweakDBID.new("GameplayRestriction.NoJump")
    local no_sprint = TweakDBID.new("GameplayRestriction.NoSprint")
    StatusEffectHelper.ApplyStatusEffect(player, no_jump)
    StatusEffectHelper.ApplyStatusEffect(player, no_sprint)
end

function Event:RemoveRestrictions()
    local player = Game.GetPlayer()
    local no_jump = TweakDBID.new("GameplayRestriction.NoJump")
    local no_sprint = TweakDBID.new("GameplayRestriction.NoSprint")
    local res_1 = StatusEffectHelper.RemoveStatusEffect(player, no_jump)
    local res_2 = StatusEffectHelper.RemoveStatusEffect(player, no_sprint)
    if not res_1 or not res_2 then
        self.log_obj:Record(LogLevel.Error, "Remove Restrictions Failed")
        return
    end
    SaveLocksManager.RequestSaveLockRemove(CName.new("InsideTheMetro"))
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

    if self.metro_obj:IsMountedPlayer() and not self.is_sitting then
        self.is_sitting = true
        Cron.Every(0.1, {tick = 1}, function(timer)
            timer.tick = timer.tick + 1
            -- For a moment, the workspace is unlocked.
            if Game.GetWorkspotSystem():IsActorInWorkspot(Game.GetPlayer()) and timer.tick < 100 then
                return
            end
            self.log_obj:Record(LogLevel.Info, "Detect Inside Metro")
            self.metro_obj:Initialize()
            self:SetStatus(Def.State.SitInsideMetro)
            Cron.Halt(timer)
        end)
    end

end

function Event:CheckOutsideMetro()
    -- need to add another check
    if not self.metro_obj:IsMountedPlayer() then
        self.log_obj:Record(LogLevel.Info, "Detect Outside Metro")
        self:SetStatus(Def.State.OutsideMetro)
        self.metro_obj:Uninitialize()
    end

end

function Event:CheckSeatArea()

    local player_local_pos = self.metro_obj:GetAccurateLocalPosition(Game.GetPlayer():GetWorldPosition())
    if self.metro_obj:IsInSeatArea(player_local_pos) then
        self.log_obj:Record(LogLevel.Debug, "Player is in Seat Area")
        self:SetStatus(Def.State.StandInsideMetro)
    else
        self.log_obj:Record(LogLevel.Debug, "Player is not in Seat Area")
        self:SetStatus(Def.State.WalkInsideMetro)
    end

end

function Event:CheckInvalidPosition()

    local player_local_pos = self.metro_obj:GetAccurateLocalPosition(Game.GetPlayer():GetWorldPosition())
    if not self.metro_obj:IsInMetro(player_local_pos) then
        self.log_obj:Record(LogLevel.Warning, "Player is not in Metro")
        self.metro_obj:TeleportToSafePosition(self.prev_player_local_pos)
    end

end

function Event:CheckSeatPosition()

    if self.metro_obj:GetSpeed() < 0.001 and self.current_status == Def.State.SitInsideMetro and not self.is_set_seat_pos then
        self.log_obj:Record(LogLevel.Debug, "Player is in Seat Area")
        self.metro_obj:SetPlayerSeatPosition()
    elseif self.metro_obj.entity == nil then
        self.is_set_seat_pos = false
    else
        self.is_set_seat_pos = true
    end

end

function Event:CheckTouchGround()

    local player = Game.GetPlayer()
    local player_pos = player:GetWorldPosition()
    local local_player_pos = self.metro_obj:GetAccurateLocalPosition(player_pos)
    if not self.metro_obj:IsInMetro(local_player_pos) then
        return
    end
    local metro_forward = self.metro_obj:GetWorldForward()
    local metro_forward_2d = Vector4.Normalize(Vector4.new(metro_forward.x, metro_forward.y, 0, 1))
    local search_pos_1 = Vector4.new(player_pos.x + metro_forward_2d.x, player_pos.y + metro_forward_2d.y, player_pos.z - 1.5, 1)
    local search_pos_2 = Vector4.new(player_pos.x + metro_forward_2d.x, player_pos.y + metro_forward_2d.y, player_pos.z, 1)
    local search_pos_3 = Vector4.new(player_pos.x - metro_forward_2d.x, player_pos.y - metro_forward_2d.y, player_pos.z - 1.5, 1)
    local search_pos_4 = Vector4.new(player_pos.x - metro_forward_2d.x, player_pos.y - metro_forward_2d.y, player_pos.z, 1)
    local search_list = {search_pos_1, search_pos_2, search_pos_3, search_pos_4}
    for _, search_pos in ipairs(search_list) do
        local res, trace = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(player_pos, search_pos, "Static", false, false)
        if res and self.metro_obj:IsInMetro(local_player_pos) then
            if trace.material.value == "concrete.physmat" and not Game.GetWorkspotSystem():IsActorInWorkspot(player) then
                self.log_obj:Record(LogLevel.Trace, "Touch Concrete")
                local pos = self.metro_obj:GetAccurateWorldPosition(self.prev_player_local_pos)
                local angle = player:GetWorldOrientation():ToEulerAngles()
                Game.GetTeleportationFacility():Teleport(player, pos, angle)
                return
            end
        end
    end
    -- if self.is_touching_ground then
        -- local_player_pos.z = local_player_pos.z - 0.03
        -- local pos = self.metro_obj:GetAccurateWorldPosition(local_player_pos)
        -- local angle = player:GetWorldOrientation():ToEulerAngles()
        -- Game.GetTeleportationFacility():Teleport(player, pos, angle)
    --     return
    -- end
    if self.is_on_ground then
        self.prev_player_local_pos = local_player_pos
        return
    end
    -- self.is_touching_ground = true
    -- Cron.Every(0.001, {tick = 1}, function(timer)
    self.log_obj:Record(LogLevel.Trace, "Is not touching ground")
    self.prev_player_local_pos.z = self.prev_player_local_pos.z - 0.1
    local pos = self.metro_obj:GetAccurateWorldPosition(self.prev_player_local_pos)
    local angle = player:GetWorldOrientation():ToEulerAngles()
    Game.GetTeleportationFacility():Teleport(player, pos, angle)
        -- if self.is_on_ground or not self.metro_obj:IsInMetro(self.prev_player_local_pos) then
        --     self.is_touching_ground = false
        --     Cron.Halt(timer)
        -- end
    -- end)

end

return Event
