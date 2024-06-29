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
    obj.first_standing_time = 5
    -- dynamic --
    obj.current_status = Def.State.OutsideMetro
    obj.prev_player_local_pos = metro_obj.default_position
    obj.is_on_ground = false
    obj.is_initial = false
    obj.is_ready = false
    obj.is_invisible_collision = false
    obj.is_first_standing = false
    obj.standing_y_offset = 0
    obj.is_in_menu = false
    obj.is_in_popup = false
    obj.is_in_photo = false
    obj.next_station_num = 1
    obj.next_stock_station_num = 0
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
    self.is_ready = false
    self.is_invisible_collision = false
    self.is_first_standing = false
    self.standing_y_offset = 0
    self.player_obj:DeleteWorkspot()
    self.current_status = Def.State.OutsideMetro
    self.is_in_menu = false
    self.is_in_popup = false
    self.is_in_photo = false
    self.next_station_num = 1
    self.next_stock_station_num = 0

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
        self:CheckSkipStation()
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
    elseif self.current_status == Def.State.SitInsideMetro then
        self:CheckEnableStand()
        self:CheckOutsideMetro()
        self:CheckNextStation()
    elseif self.current_status == Def.State.EnableStand then
        self:CheckEnableStand()
        self:CheckNextStation()
    elseif self.current_status == Def.State.EnableSit then
        self:CheckEnableSit()
        self:CheckInvalidPosition()
        self:CheckTouchGround()
        self:CheckRestrictedArea()
        self:CheckNextStation()
    elseif self.current_status == Def.State.WalkInsideMetro then
        self:CheckEnableSit()
        self:CheckInvalidPosition()
        self:CheckTouchGround()
        self:CheckRestrictedArea()
        self:CheckNextStation()
    elseif self.current_status == Def.State.Invalid then
        self:CheckGetOff()
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

function Event:IsOnGround()
    return self.is_on_ground
end

function Event:IsPassedRestrictedBorder()

    local player_pos = Game.GetPlayer():GetWorldPosition()
    for _, point in ipairs(Data.Border) do
        local distance = Vector4.Distance(player_pos, Vector4.new(point.x, point.y, point.z, 1))
        if distance < point.r then
            return true
        end
    end
    return false

end

function Event:CheckGetOff()

    if not self.metro_obj:IsMountedPlayer() then
        self.log_obj:Record(LogLevel.Info, "Detect Get Off Metro")
        self.current_status = Def.State.OutsideMetro
        self.hud_obj:HideChoice()
        self:Uninitialize()
        self.metro_obj:Uninitialize()
        return
    end

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

    if not self.is_ready then
        if self.metro_obj:GetSpeed() >= 1 then
            self.is_ready = true
            local active_station = self.metro_obj:GetActiveStation()
            for _, track_info in ipairs(self.metro_obj:GetTrackList(active_station)) do
                if track_info.track == self.metro_obj.selected_track_index then
                    if not track_info.is_invalid then
                        self.is_first_standing = true
                        self:SetStatus(Def.State.EnableStand)
                        Cron.After(self.first_standing_time, function()
                            self.is_first_standing = false
                        end)
                    end
                end
            end
        end
    end

    if self.is_first_standing then
        self.standing_y_offset = 1.5 * self.metro_obj:GetSpeed() / 43
        return
    else
        self.standing_y_offset = 0
    end

    local is_invalid = false
    local is_final = false

    for _, track_info in ipairs(self.metro_obj:GetTrackList(self.metro_obj.next_station_num)) do
        if track_info.track == self.metro_obj.selected_track_index then
            is_invalid = track_info.is_invalid
            is_final = track_info.is_final
            break
        end
    end

    if self.metro_obj:GetSpeed() < 1 then
        if is_invalid then
            self.log_obj:Record(LogLevel.Debug, "Detect Invalid Station")
            self:SetStatus(Def.State.SitInsideMetro)
        elseif is_final then
            self.log_obj:Record(LogLevel.Debug, "Detect Final Station")
            self:SetStatus(Def.State.SitInsideMetro)
        else
            self.log_obj:Record(LogLevel.Debug, "Detect Enable Stand")
            if self.is_ready then
                self:SetStatus(Def.State.EnableStand)
            end
        end
    else
        self.log_obj:Record(LogLevel.Debug, "Detect Disable Stand")
        self:SetStatus(Def.State.SitInsideMetro)
    end

end

function Event:CheckNextStation()

    local quest_system = Game.GetQuestsSystem()
    local next_station_num = quest_system:GetFact("ue_metro_next_station")
    if next_station_num == 0 then
        self.log_obj:Record(LogLevel.Info, "Detect Invalid Next Station")
        quest_system:SetFact("ue_metro_next_station", self.metro_obj.next_station_num)
    else
        self.metro_obj.next_station_num = next_station_num
    end

end

function Event:CheckSkipStation()

    local quest_system = Game.GetQuestsSystem()
    local active_station_num = quest_system:GetFact("ue_metro_active_station")
    local next_station_num = quest_system:GetFact("ue_metro_next_station")

    if active_station_num == next_station_num then
        self.log_obj:Record(LogLevel.Info, "Detect Skip Station. set next station to " .. next_station_num)
        self.next_stock_station_num = next_station_num
    else
        self.next_stock_station_num = 0
    end

end

function Event:CheckEnableSit()

    local player_local_pos = self.metro_obj:GetAccurateLocalPosition(Game.GetPlayer():GetWorldPosition())
    if self.metro_obj:IsInSeatArea(player_local_pos) and self.metro_obj:GetSpeed() >= 1 and not InsideMetro.is_avoidance_mode then
        self.log_obj:Record(LogLevel.Debug, "Player is in Seat Area")
        self:SetStatus(Def.State.EnableSit)
    else
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

    if self.metro_obj:IsNextFinalStation() and self.metro_obj:IsInStation() then
        self.log_obj:Record(LogLevel.Info, "Player is in Final Station")
        InsideMetro.is_avoidance_mode = false
        InsideMetro.core_obj:DisableWalkingMetro()
        return
    end

end

function Event:CheckTouchGround()

    local player = Game.GetPlayer()
    local player_pos = player:GetWorldPosition()
    local local_player_pos = self.metro_obj:GetAccurateLocalPosition(player_pos)
    if not self.metro_obj:IsInMetro(local_player_pos) then
        return
    end
    local search_pos = self.metro_obj:GetAccurateWorldPosition(Vector4.new(local_player_pos.x, local_player_pos.y + 5.0, local_player_pos.z - 0.1, 1))
    local res, trace = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(player_pos, search_pos, "Static", false, false)
    if res then
        if not Game.GetWorkspotSystem():IsActorInWorkspot(player) then
            self.log_obj:Record(LogLevel.Trace, "Touch Concrete")
            InsideMetro.is_avoidance_mode = true
            return
        end
    end
    InsideMetro.is_avoidance_mode = false
    if self.is_on_ground then
        self.prev_player_local_pos = local_player_pos
        if self.prev_player_local_pos.y < -7 then
            self.log_obj:Record(LogLevel.Trace, "Is too back position")
            self.prev_player_local_pos.y = -6
            self.prev_player_local_pos.x = 0
        end
        return
    end
    self.log_obj:Record(LogLevel.Trace, "Is not touching ground")
    local prev_pos = Vector4.new(self.prev_player_local_pos.x, self.prev_player_local_pos.y, local_player_pos.z - 0.1, 1)
    local pos = self.metro_obj:GetAccurateWorldPosition(prev_pos)
    local angle = player:GetWorldOrientation():ToEulerAngles()
    Game.GetTeleportationFacility():Teleport(player, pos, angle)

end

return Event
