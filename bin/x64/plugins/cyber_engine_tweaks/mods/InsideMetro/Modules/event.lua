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
    -- static --
    obj.stand_rock_time = 3
    obj.invisible_collision_count_max = 10
    -- dynamic --
    obj.current_status = Def.State.OutsideMetro
    obj.prev_player_local_pos = metro_obj.default_position
    obj.is_on_ground = false
    obj.is_sitting = false
    obj.invisible_collision_count = 0
    obj.is_ready = false
    obj.is_invisible_collision = false
    return setmetatable(obj, self)
end

function Event:Initialize()
    -- self:SetRestrictions()
    self:SetTouchGroundObserver()
    self:SetInteractionUIObserver()
    self:SetGameUIObserver()
    self.hud_obj:Initialize()
end

function Event:Uninitialize()

    self.prev_player_local_pos = self.metro_obj.default_position
    self.is_on_ground = false
    self.is_sitting = false
    self.is_ready = false
    self.is_invisible_collision = false
    self.player_obj:DeleteWorkspot()
    self.current_status = Def.State.OutsideMetro
    -- self:RemoveRestrictions()

end

function Event:SetGameUIObserver()

    GameUI.Observe("SessionStart", function()
        self.log_obj:Record(LogLevel.Info, "Session start detected")
    end)

    GameUI.Observe("SessionEnd", function()
        self.log_obj:Record(LogLevel.Info, "Session end detected")
        self:Uninitialize()
    end)

end

function Event:SetTouchGroundObserver()

    Override("LocomotionTransition", "IsTouchingGround", function(this, script_interface, wrapped_method)
        self.is_on_ground = wrapped_method(script_interface)
        return self.is_on_ground
    end)

end

function Event:SetInteractionUIObserver()

    -- Overside choice ui (refer to https://www.nexusmods.com/cyberpunk2077/mods/7299)
    Observe("InteractionUIBase", "OnInitialize", function(this)
        self.hud_obj.interaction_ui_base = this
    end)

    Observe("InteractionUIBase", "OnDialogsData", function(this)
        self.hud_obj.interaction_ui_base = this
    end)

    Override("InteractionUIBase", "OnDialogsData", function(_, value, wrapped_method)
        if self:IsInMetro() then
            local data = FromVariant(value)
            local hubs = data.choiceHubs
            table.insert(hubs, self.hud_obj.interaction_hub)
            data.choiceHubs = hubs
            wrapped_method(ToVariant(data))
        else
            wrapped_method(value)
        end
    end)

    Override("InteractionUIBase", "OnDialogsSelectIndex", function(_, index, wrapped_method)
        if self:IsInMetro() then
            wrapped_method(self.hud_obj.selected_choice_index - 1)
        else
            self.hud_obj.selected_choice_index = index + 1
            wrapped_method(index)
        end
    end)

    Override("dialogWidgetGameController", "OnDialogsActivateHub", function(_, id, wrapped_metthod) -- Avoid interaction getting overriden by game
        if self:IsInMetro() then
            local id_
            if self.hud_obj.interaction_hub == nil then
                id_ = id
            else
                id_ = self.hud_obj.interaction_hub.id
            end
            return wrapped_metthod(id_)
        else
            return wrapped_metthod(id)
        end
    end)

end

function Event:SetStatus(status)

    if self.current_status == Def.State.OutsideMetro and status == Def.State.SitInsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status from OutsideMetro to SitInsideMetro")
        self.metro_obj:SetPlayerSeatPosition()
        self.current_status = Def.State.SitInsideMetro
        return true
    elseif self.current_status == Def.State.SitInsideMetro and status == Def.State.EnableStand then
        self.log_obj:Record(LogLevel.Info, "Change Status from SitInsideMetro to EnableStand")
        self.current_status = Def.State.EnableStand
        self.hud_obj:HideChoice()
        if not InsideMetro.core_obj:IsInRestrictedArea() then
            self.hud_obj:ShowChoice(Def.ChoiceVariation.Stand, 1)
        end
        return true
    elseif self.current_status == Def.State.SitInsideMetro and status == Def.State.WalkInsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status from SitInsideMetro to WalkInsideMetro")
        self.current_status = Def.State.WalkInsideMetro
        self.hud_obj:HideChoice()
        return true
    elseif self.current_status == Def.State.EnableStand and status == Def.State.WalkInsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status from EnableStand to WalkInsideMetro")
        self.current_status = Def.State.WalkInsideMetro
        self.hud_obj:HideChoice()
        return true
    elseif self.current_status == Def.State.WalkInsideMetro and status == Def.State.EnableSit then
        self.log_obj:Record(LogLevel.Info, "Change Status from WalkInsideMetro to EnableSit")
        self.current_status = Def.State.EnableSit
        self.hud_obj:HideChoice()
        self.hud_obj:ShowChoice(Def.ChoiceVariation.Sit, 1)
        return true
    elseif self.current_status == Def.State.WalkInsideMetro and status == Def.State.SitInsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status from WalkInsideMetro to SitInsideMetro")
        self.current_status = Def.State.SitInsideMetro
        self.hud_obj:HideChoice()
        return true
    elseif self.current_status == Def.State.EnableSit and status == Def.State.WalkInsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status from EnableSit to WalkInsideMetro")
        self.current_status = Def.State.WalkInsideMetro
        self.hud_obj:HideChoice()
        return true
    elseif self.current_status == Def.State.EnableSit and status == Def.State.SitInsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status from EnableSit to SitInsideMetro")
        self.current_status = Def.State.SitInsideMetro
        self.hud_obj:HideChoice()
        return true
    elseif self.current_status == Def.State.EnableStand and status == Def.State.SitInsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status from EnableStand to SitInsideMetro")
        self.current_status = Def.State.SitInsideMetro
        self.hud_obj:HideChoice()
        return true
    elseif self.current_status == Def.State.SitInsideMetro and status == Def.State.OutsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status from SitInsideMetro to OutsideMetro")
        self.current_status = Def.State.OutsideMetro
        self.hud_obj:HideChoice()
        self:Uninitialize()
        return true
    elseif self.current_status == Def.State.EnableStand and status == Def.State.OutsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status from EnableStand to OutsideMetro")
        self.current_status = Def.State.OutsideMetro
        self.hud_obj:HideChoice()
        self:Uninitialize()
        return true
    else
        return false
    end
end

function Event:IsInMetro()
    return self.current_status ~= Def.State.OutsideMetro
end

function Event:IsOnGround()
    return self.is_on_ground
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
        self:CheckEnableStand()
        self:CheckOutsideMetro()
    elseif self.current_status == Def.State.EnableStand then
        self:CheckEnableStand()
    elseif self.current_status == Def.State.EnableSit then
        self:CheckEnableSit()
        self:CheckInvalidPosition()
        self:CheckTouchGround()
        self:CheckRestrictedArea()
    elseif self.current_status == Def.State.WalkInsideMetro then
        self:CheckEnableSit()
        self:CheckInvalidPosition()
        self:CheckTouchGround()
        self:CheckRestrictedArea()
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

function Event:CheckEnableStand()

    if self.invisible_collision_count >= self.invisible_collision_count_max then
        if self.metro_obj:GetSpeed() >= 0.001 then
            return
        else
            self.invisible_collision_count = 0
        end
    end

    if not self.is_ready then
        if self.metro_obj:GetSpeed() >= 0.001 then
            self.is_ready = true
        end
    end

    if self.metro_obj:GetSpeed() < 0.001 then
        self.log_obj:Record(LogLevel.Debug, "Detect Enable Stand")
        if self.is_ready then
            self:SetStatus(Def.State.EnableStand)
        end
    else
        self.log_obj:Record(LogLevel.Debug, "Detect Disable Stand")
        self:SetStatus(Def.State.SitInsideMetro)
    end

end

function Event:CheckEnableSit()

    local player_local_pos = self.metro_obj:GetAccurateLocalPosition(Game.GetPlayer():GetWorldPosition())
    if self.metro_obj:IsInSeatArea(player_local_pos) and self.metro_obj:GetSpeed() >= 0.001 and not InsideMetro.is_free_move then
        self.log_obj:Record(LogLevel.Debug, "Player is in Seat Area")
        self:SetStatus(Def.State.EnableSit)
    elseif self.metro_obj:GetSpeed() >= 0.001 then
        self.log_obj:Record(LogLevel.Debug, "Player is not in Seat Area")
        self:SetStatus(Def.State.WalkInsideMetro)
    end

end

function Event:CheckInvalidPosition()

    local player_local_pos = self.metro_obj:GetAccurateLocalPosition(Game.GetPlayer():GetWorldPosition())
    if not self.metro_obj:IsInMetro(player_local_pos) then
        self.log_obj:Record(LogLevel.Warning, "Player is not in Metro")
        self.metro_obj:TeleportToSafePosition()
    end

end

function Event:CheckRestrictedArea()

    if InsideMetro.core_obj:IsInRestrictedArea() then
        self.log_obj:Record(LogLevel.Info, "Player is in Restricted Area")
        InsideMetro.is_free_move = false
        InsideMetro.core_obj:DisableWalkingMetro()
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
    local search_pos_1 = self.metro_obj:GetAccurateWorldPosition(Vector4.new(0,8,0.5,1))
    local search_pos_2 = self.metro_obj:GetAccurateWorldPosition(Vector4.new(0,-8,1,1))
    -- local search_pos_3 = self.metro_obj:GetAccurateWorldPosition(Vector4.new(0,8,1.5,1))
    -- local search_pos_1 = Vector4.new(player_pos.x + metro_forward_2d.x, player_pos.y + metro_forward_2d.y, player_pos.z - 0.5, 1)
    -- local search_pos_2 = Vector4.new(player_pos.x + metro_forward_2d.x, player_pos.y + metro_forward_2d.y, player_pos.z, 1)
    -- local search_pos_3 = Vector4.new(player_pos.x - metro_forward_2d.x, player_pos.y - metro_forward_2d.y, player_pos.z - 1.5, 1)
    -- local search_pos_4 = Vector4.new(player_pos.x - metro_forward_2d.x, player_pos.y - metro_forward_2d.y, player_pos.z, 1)
    -- local search_list = {search_pos_1, search_pos_2}
    -- if not InsideMetro.is_free_move then
        -- for _, search_pos in ipairs(search_list) do
            local res, trace = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(search_pos_1, search_pos_2, "Static", false, false)
            if res then
                -- if trace.material.value == "concrete.physmat" and not Game.GetWorkspotSystem():IsActorInWorkspot(player) then
                if not Game.GetWorkspotSystem():IsActorInWorkspot(player) then
                    self.log_obj:Record(LogLevel.Trace, "Touch Concrete")
                    InsideMetro.is_free_move = true
                    -- Cron.After(5, function()
                    --     InsideMetro.is_free_move = false
                    -- end)
                    return
                end
            end
        -- end
    -- else
    --     return
    -- end
    InsideMetro.is_free_move = false
    if self.is_on_ground then
        self.prev_player_local_pos = local_player_pos
        return
    end
    self.log_obj:Record(LogLevel.Trace, "Is not touching ground")
    local prev_pos = Vector4.new(self.prev_player_local_pos.x, self.prev_player_local_pos.y, local_player_pos.z - 0.1, 1)
    local pos = self.metro_obj:GetAccurateWorldPosition(prev_pos)
    local angle = player:GetWorldOrientation():ToEulerAngles()
    Game.GetTeleportationFacility():Teleport(player, pos, angle)

end

return Event
