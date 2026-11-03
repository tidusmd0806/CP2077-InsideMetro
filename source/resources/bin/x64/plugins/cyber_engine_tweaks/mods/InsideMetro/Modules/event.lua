local HUD = require("Modules/hud.lua")

local Event = {}
Event.__index = Event

function Event:New(metro_obj)
    -- instance --
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "Event")
    obj.hud_obj = HUD:New(metro_obj)
    obj.metro_obj = metro_obj
    -- static --
    -- dynamic --
    obj.current_status = Def.State.OutsideMetro
    obj.prev_player_local_pos = metro_obj.default_position
    obj.is_on_ground = false
    obj.is_initial = false
    obj.is_in_menu = false
    obj.is_in_popup = false
    obj.is_in_photo = false
    obj.walk_outside_time = 0
    obj.prev_in_workspot = nil
    obj.is_stand_choice_dismissed = false
    return setmetatable(obj, self)
end

function Event:Initialize()
    self:SetTouchGroundObserver()
    self:SetInteractionUIObserver()
    self:SetGameUIObserver()
    self.hud_obj:Initialize()
end

function Event:Uninitialize()

    self.prev_player_local_pos = self.metro_obj.default_position
    self.is_on_ground = false
    self.is_initial = false
    self.current_status = Def.State.OutsideMetro
    self.is_in_menu = false
    self.is_in_popup = false
    self.is_in_photo = false
    self.prev_in_workspot = nil
    self.is_stand_choice_dismissed = false
end

function Event:SetGameUIObserver()

    GameUI.Observe("SessionStart", function()
        self.log_obj:Record(LogLevel.Info, "Session start detected")
    end)

    GameUI.Observe("SessionEnd", function()
        self.log_obj:Record(LogLevel.Info, "Session end detected")
        self:Uninitialize()
    end)

    GameUI.Observe("MenuOpen", function()
        self.is_in_menu = true
    end)

    GameUI.Observe("MenuClose", function()
        self.is_in_menu = false
    end)

    GameUI.Observe("PopupOpen", function()
        self.is_in_popup = true
    end)

    GameUI.Observe("PopupClose", function()
        self.is_in_popup = false
    end)

    GameUI.Observe("PhotoModeOpen", function()
        self.is_in_photo = true
    end)

    GameUI.Observe("PhotoModeClose", function()
        self.is_in_photo = false
    end)

end

function Event:SetTouchGroundObserver()

    Override("LocomotionTransition", "IsTouchingGround", function(this, script_interface, wrapped_method)
        self.is_on_ground = wrapped_method(script_interface)
        return self.is_on_ground
    end)

end

function Event:SetInteractionUIObserver()

    -- Override choice UI (ref: nexusmods.com/cyberpunk2077/mods/7299)
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
        self.metro_obj:SetLineInfo()
        self.current_status = Def.State.SitInsideMetro
        return true
    elseif self.current_status == Def.State.SitInsideMetro and status == Def.State.EnableStand then
        self.log_obj:Record(LogLevel.Info, "Change Status from SitInsideMetro to EnableStand")
        self.current_status = Def.State.EnableStand
        self.hud_obj:HideChoice()
        if not self.metro_obj:IsCurrentInvalidStation() then
            self.hud_obj:ShowChoice(Def.ChoiceVariation.Stand)
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
        self.hud_obj:ShowChoice(Def.ChoiceVariation.Sit)
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
    elseif self.current_status == Def.State.EnableSit and status == Def.State.OutsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status from EnableSit to OutsideMetro")
        self.current_status = Def.State.OutsideMetro
        self.hud_obj:HideChoice()
        self:Uninitialize()
        return true
    elseif self.current_status == Def.State.WalkInsideMetro and status == Def.State.OutsideMetro then
        self.log_obj:Record(LogLevel.Info, "Change Status from WalkInsideMetro to OutsideMetro")
        self.current_status = Def.State.OutsideMetro
        self.hud_obj:HideChoice()
        self:Uninitialize()
        return true
    else
        return false
    end
end

function Event:GetStatus()
    return self.current_status
end

function Event:CheckAllEvents()

    if self.current_status == Def.State.OutsideMetro then
        self:CheckInsideMetro()
        return
    end

    -- seated + unmounted: reset status for re-boarding
    if (self.current_status == Def.State.SitInsideMetro
            or self.current_status == Def.State.EnableStand)
            and not self.metro_obj:IsMountedPlayer()
            and not InsideMetro.core_obj.is_switching_pose then
        self.log_obj:Record(LogLevel.Info, "Detect Outside Metro (general reset)")
        local changed = self:SetStatus(Def.State.OutsideMetro)
        if not changed then
            self.current_status = Def.State.OutsideMetro
            self:Uninitialize()
        end
        self.metro_obj:Uninitialize()
        return
    end

    if self.current_status == Def.State.SitInsideMetro then
        self:CheckEnableStand()
        self:CheckOutsideMetro()
        self:CheckNextStation()
    elseif self.current_status == Def.State.EnableStand then
        self:CheckEnableStand()
        self:CheckNextStation()
    elseif self.current_status == Def.State.EnableSit then
        self:CheckEnableSit()
        self:CheckInvalidPosition()
        self:CheckRestrictedArea()
        self:CheckNextStation()
    elseif self.current_status == Def.State.WalkInsideMetro then
        self:CheckEnableSit()
        self:CheckInvalidPosition()
        self:CheckRestrictedArea()
        self:CheckNextStation()
        -- walking players reset only when actually outside the metro domain
        if not InsideMetro.core_obj.is_switching_pose then
            local player_local_pos = self.metro_obj:GetAccurateLocalPosition(Game.GetPlayer():GetWorldPosition())
            if player_local_pos == nil or not self.metro_obj:IsInMetro(player_local_pos) then
                -- grace period: absorb failsafe teleport-back
                self.walk_outside_time = self.walk_outside_time + InsideMetro.core_obj.event_check_interval
                if self.walk_outside_time >= InsideMetro.core_obj.config_obj.walk_reset_grace then
                    self.log_obj:Record(LogLevel.Info, "Detect Outside Metro (walk reset)")
                    self.walk_outside_time = 0
                    self:SetStatus(Def.State.OutsideMetro)
                    self.metro_obj:Uninitialize()
                end
            else
                self.walk_outside_time = 0
            end
        end
    end

end

function Event:IsInPouse()
    if self.is_in_menu or self.is_in_popup or self.is_in_photo then
        return true
    else
        return false
    end
end

function Event:IsInMetro()
    return self.current_status ~= Def.State.OutsideMetro
end

function Event:CheckInsideMetro()
    if self.metro_obj:IsMountedPlayer() and not self.is_initial then
        self.is_initial = true
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
    if not self.metro_obj:IsMountedPlayer() and not InsideMetro.core_obj.is_switching_pose then
        self.log_obj:Record(LogLevel.Info, "Detect Outside Metro")
        self:SetStatus(Def.State.OutsideMetro)
        self.metro_obj:Uninitialize()
    end

end

function Event:CheckEnableStand()
    if InsideMetro.core_obj.is_switching_pose then
        return
    end
    local in_workspot = Game.GetWorkspotSystem():IsActorInWorkspot(Game.GetPlayer())
    local stand_fact = Game.GetQuestsSystem():GetFactStr("ue_metro_player_stand_door")
    -- fact reset releases the dismissal latch
    if stand_fact == 0 then
        self.is_stand_choice_dismissed = false
    end
    local can_stand = in_workspot and stand_fact == 1 and not self.metro_obj:IsCurrentInvalidStation()
    if self.current_status == Def.State.EnableStand and not can_stand then
        -- choice just disappeared: latch until the fact resets (fact update lags workspot)
        self.is_stand_choice_dismissed = true
    end
    if can_stand and not self.is_stand_choice_dismissed then
        self:SetStatus(Def.State.EnableStand)
    else
        self:SetStatus(Def.State.SitInsideMetro)
    end
end

function Event:CheckNextStation()
    local quest_system = Game.GetQuestsSystem()
    local next_station_num = quest_system:GetFact("ue_metro_next_station")
    local active_station_num = quest_system:GetFact("ue_metro_active_station")
    if next_station_num == 0 then
        self.log_obj:Record(LogLevel.Info, "Detect Invalid Next Station")
        quest_system:SetFact("ue_metro_next_station", self.metro_obj.next_station_num)
    elseif next_station_num == 1 and self.metro_obj.next_station_num >= 20 then
        self.log_obj:Record(LogLevel.Info, "Detect Invalid Next Station in moddfy line reversed")
        quest_system:SetFact("ue_metro_next_station", self.metro_obj.next_station_num)
    elseif next_station_num == 1 and self.metro_obj.next_station_num == 2 and active_station_num == 20 then
        self.log_obj:Record(LogLevel.Info, "Detect Invalid Next Station in moddfy line")
        quest_system:SetFact("ue_metro_next_station", self.metro_obj.next_station_num)
    else
        self.metro_obj.next_station_num = next_station_num
    end
end

function Event:CheckEnableSit()
    local player_local_pos = self.metro_obj:GetAccurateLocalPosition(Game.GetPlayer():GetWorldPosition())
    if player_local_pos == nil then
        self:SetStatus(Def.State.WalkInsideMetro)
        return
    end
    if self:IsAtStation() then
        self.log_obj:Record(LogLevel.Debug, "Metro is at station. Sit command is blocked")
        self:SetStatus(Def.State.WalkInsideMetro)
        return
    end
    if self.metro_obj:IsInSeatArea(player_local_pos) and self.metro_obj:GetSpeed() >= 1 then
        self.log_obj:Record(LogLevel.Debug, "Player is in Seat Area")
        self:SetStatus(Def.State.EnableSit)
    else
        self.log_obj:Record(LogLevel.Debug, "Player is not in Seat Area")
        self:SetStatus(Def.State.WalkInsideMetro)
    end
end

function Event:IsAtStation()
    local quest_system = Game.GetQuestsSystem()
    local active_station_num = quest_system:GetFact("ue_metro_active_station")
    local next_station_num = quest_system:GetFact("ue_metro_next_station")
    return active_station_num == next_station_num
end

function Event:CheckInvalidPosition()
    local player_local_pos = self.metro_obj:GetAccurateLocalPosition(Game.GetPlayer():GetWorldPosition())
    if player_local_pos == nil then
        return
    end
    if not self.metro_obj:IsInMetro(player_local_pos) then
        self.log_obj:Record(LogLevel.Warning, "Player is not in Metro")
        self.metro_obj:TeleportToSafePosition()
    end
end

function Event:CheckRestrictedArea()
    if self.metro_obj:IsNextFinalStation() and self.metro_obj:IsInStation() then
        self.log_obj:Record(LogLevel.Info, "Player is in Final Station")
        InsideMetro.core_obj:DisableWalkingMetro()
        return
    end
end

return Event
