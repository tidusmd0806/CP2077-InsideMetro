local Metro = {}
Metro.__index = Metro

function Metro:New()
    -- instance --
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "Metro")
    -- static --
    obj.domain = {x_max = 10.0, x_min = -10.0, y_max = 17.0, y_min = -17.0, z_max = 8.6, z_min = -8.2}
    obj.default_position = Vector4.new(0, 0, 0.8, 1)
    obj.seat_area_radius = 1.0
    obj.speed_check_interval = 0.01
    obj.speed_smoothing = 0.3
    -- Lead time (s) to extrapolate workspot position forward on a moving train.
    obj.workspot_lead_time = 0.03
    obj.lag_check_interval = 0.1
    obj.lag_stutter_ratio_low = 0.3
    obj.lag_stutter_ratio_high = 1.7
    obj.lag_recent_ticks = 0
    -- dynamic --
    obj.entity = nil
    obj.entity_id = nil
    obj.player_seat_position = nil
    obj.is_player_seat_right_side = true
    obj.last_metro_position = nil
    obj.current_speed = 0
    obj.is_lag_monitor = false
    obj.lag_stall_ticks = 0
    obj.prev_metro_pos = nil
    obj.next_station_num = 1
    obj.selected_track_index = 1
    obj.is_speed_observer = false
    return setmetatable(obj, self)
end

function Metro:Initialize()
    self:SetEntity()
    self:SetSpeedObserver()
    self:SetTransformLagMonitor()
end

function Metro:Uninitialize()
    self.entity = nil
    self.entity_id = nil
    self.player_seat_position = nil
    self.is_player_seat_right_side = true
    self.last_metro_position = nil
    self.current_speed = 0
    self.next_station_num = 1
    self.selected_track_index = 1
end

function Metro:SetEntity()
    local entity = GetMountedVehicle(Game.GetPlayer())
    if entity == nil then
        if self.entity ~= nil then
            self.log_obj:Record(LogLevel.Info, "SetEntity: mounted vehicle is nil, entity cleared")
        end
        self.entity = nil
        self.entity_id = nil
        return false
    elseif self.entity == entity and self.entity_id == entity:GetEntityID() then
        return true
    elseif entity:GetClassName().value == "ncartMetroObject" then
        if self.entity ~= entity then
            self.log_obj:Record(LogLevel.Info, string.format("SetEntity: entity refreshed to id %s", tostring(entity:GetEntityID())))
        end
        self.entity = entity
        self.entity_id = self.entity:GetEntityID()
        return true
    else
        return false
    end
end

function Metro:IsMountedPlayer()
    local entity = GetMountedVehicle(Game.GetPlayer())
    if entity == nil then
        return false
    elseif self.entity == entity and self.entity_id == entity:GetEntityID() then
        return true
    elseif entity:GetClassName().value == "ncartMetroObject" then
        return true
    else
        return false
    end
end

-- Safely calls an entity method; stale handles return nil.
function Metro:SafeEntityCall(method_name)
    if self.entity == nil then
        return nil
    end
    local ok, result = pcall(function(entity)
        return entity[method_name](entity)
    end, self.entity)
    if not ok or result == nil then
        self.entity = nil
        self.entity_id = nil
        return nil
    end
    return result
end

function Metro:GetWorldPosition()
    local vec4 = self:SafeEntityCall("GetWorldPosition")
    if vec4 == nil then
        return nil
    end
    return Vector4.new(vec4.x, vec4.y, vec4.z, vec4.w)
end

function Metro:GetWorldOrientation()
    local quat = self:SafeEntityCall("GetWorldOrientation")
    if quat == nil then
        return nil
    end
    return Quaternion.new(quat.i, quat.j, quat.k, quat.r)
end

function Metro:GetWorldRight()
    local vec4 = self:SafeEntityCall("GetWorldRight")
    if vec4 == nil then
        return nil
    end
    return Vector4.new(vec4.x, vec4.y, vec4.z, vec4.w)
end

function Metro:GetWorldForward()
    local vec4 = self:SafeEntityCall("GetWorldForward")
    if vec4 == nil then
        return nil
    end
    return Vector4.new(vec4.x, vec4.y, vec4.z, vec4.w)
end

function Metro:GetWorldUp()
    local vec4 = self:SafeEntityCall("GetWorldUp")
    if vec4 == nil then
        return nil
    end
    return Vector4.new(vec4.x, vec4.y, vec4.z, vec4.w)
end

function Metro:ChangeWorldPosToLocal(world_pos)

    if self.entity == nil then
        self.log_obj:Record(LogLevel.Error, "ChangeWorldPosToLocal: entity is nil")
        return nil
    end
    local origin = self:GetWorldPosition()
    local right = self:GetWorldRight()
    local forward = self:GetWorldForward()
    local up = self:GetWorldUp()
    if origin == nil or right == nil or forward == nil or up == nil then
        return nil
    end
    local relative = Vector4.new(world_pos.x - origin.x, world_pos.y - origin.y, world_pos.z - origin.z, 1)
    local x = Vector4.Dot(relative, right)
    local y = Vector4.Dot(relative, forward)
    local z = Vector4.Dot(relative, up)
    return Vector4.new(x, y, z, 1)

end

function Metro:ChangeLocalPosToWorld(local_pos)

    if self.entity == nil then
        self.log_obj:Record(LogLevel.Error, "ChangeLocalPosToWorld: entity is nil")
        return nil
    end
    local origin = self:GetWorldPosition()
    local right = self:GetWorldRight()
    local forward = self:GetWorldForward()
    local up = self:GetWorldUp()
    if origin == nil or right == nil or forward == nil or up == nil then
        return nil
    end
    local x = Vector4.new(right.x * local_pos.x, right.y * local_pos.x, right.z * local_pos.x, 0)
    local y = Vector4.new(forward.x * local_pos.y, forward.y * local_pos.y, forward.z * local_pos.y, 0)
    local z = Vector4.new(up.x * local_pos.z, up.y * local_pos.z, up.z * local_pos.z, 0)
    return Vector4.new(x.x + y.x + z.x + origin.x, x.y + y.y + z.y + origin.y, x.z + y.z + z.z + origin.z, 1)
end

function Metro:IsInMetro(local_pos)

    if local_pos == nil then
        return false
    end
    if local_pos.x > self.domain.x_max or local_pos.x < self.domain.x_min then
        return false
    end
    if local_pos.y > self.domain.y_max or local_pos.y < self.domain.y_min then
        return false
    end
    if local_pos.z > self.domain.z_max or local_pos.z < self.domain.z_min then
        return false
    end
    return true

end

function Metro:IsInSeatArea(local_pos)

    if local_pos == nil or self.player_seat_position == nil then
        return false
    end
    local distance = Vector4.Distance(local_pos, self.player_seat_position)
    if distance < self.seat_area_radius then
        return true
    end
    return false
end

function Metro:SetPlayerSeatPosition()

    self.log_obj:Record(LogLevel.Trace, "SetPlayerSeatPosition")
    self.player_seat_position = self:ChangeWorldPosToLocal(Game.GetPlayer():GetWorldPosition())
    if self.player_seat_position.x > 0 then
        self.is_player_seat_right_side = true
    else
        self.is_player_seat_right_side = false
    end

end

function Metro:IsPlayerSeatRightSide()
    return self.is_player_seat_right_side
end

-- NOTE: NPC anchor based correction was removed.
-- The metro entity transform is the source of truth.
function Metro:GetAccurateLocalPosition(world_pos)
    return self:ChangeWorldPosToLocal(world_pos)
end

function Metro:GetAccurateWorldPosition(local_pos)
    return self:ChangeLocalPosToWorld(local_pos)
end

-- Extrapolate position to compensate placement delay.
-- forward along the metro direction by speed * workspot_lead_time.
function Metro:ExtrapolateWorldPosition(world_pos)

    if world_pos == nil then
        return nil
    end
    if self.workspot_lead_time == nil or self.workspot_lead_time <= 0 then
        return world_pos
    end
    local speed = self:GetSpeed()
    if speed <= 0.1 then
        return world_pos
    end
    local forward = self:GetWorldForward()
    if forward == nil then
        return world_pos
    end
    local lead = speed * self.workspot_lead_time
    return Vector4.new(world_pos.x + forward.x * lead, world_pos.y + forward.y * lead, world_pos.z + forward.z * lead, 1)
end

function Metro:SetSpeedObserver()

    if self.is_speed_observer then
        self.log_obj:Record(LogLevel.Warning, "SpeedObserver is already running")
        return
    end
    self.is_speed_observer = true
    self.last_metro_position = nil
    Cron.Every(self.speed_check_interval, {tick = 1}, function(timer)
        if self.entity == nil then
            self.current_speed = 0
            self.last_metro_position = nil
            self.is_speed_observer = false
            Cron.Halt(timer)
            return
        end
        local current_pos = self:GetWorldPosition()
        if current_pos == nil then
            return
        end
        if self.last_metro_position ~= nil then
            local distance = Vector4.Distance(current_pos, self.last_metro_position)
            -- Cron.Every fires at most once per frame, so the real elapsed time
            -- is the frame delta, not the configured interval.
            local dt = InsideMetro.last_delta or self.speed_check_interval
            if dt <= 0 then
                dt = self.speed_check_interval
            end
            local raw_speed = distance / dt
            self.current_speed = self.current_speed * (1 - self.speed_smoothing) + raw_speed * self.speed_smoothing
        end
        self.last_metro_position = current_pos
    end)

end

function Metro:GetSpeed()
    return self.current_speed
end

-- Monitor whether the metro transform lags behind the train.
-- forward (typical right after departure).
function Metro:SetTransformLagMonitor()

    if self.is_lag_monitor then
        self.log_obj:Record(LogLevel.Warning, "TransformLagMonitor is already running")
        return
    end
    self.is_lag_monitor = true
    self.lag_stall_ticks = 0
    self.prev_metro_pos = nil
    Cron.Every(self.lag_check_interval, {tick = 1}, function(timer)
        if self.entity == nil then
            self.is_lag_monitor = false
            self.prev_metro_pos = nil
            self.lag_recent_ticks = 0
            Cron.Halt(timer)
            return
        end
        if self.lag_recent_ticks > 0 then
            self.lag_recent_ticks = self.lag_recent_ticks - 1
        end
        local metro_pos = self:GetWorldPosition()
        if metro_pos == nil then
            return
        end

        if self.prev_metro_pos ~= nil and self.current_speed > 1 then
            local metro_delta = Vector4.Distance(metro_pos, self.prev_metro_pos)
            local expected = self.current_speed * self.lag_check_interval

            -- stutter detection: stall then jump
            if metro_delta < expected * self.lag_stutter_ratio_low then
                self.lag_stall_ticks = self.lag_stall_ticks + 1
            elseif self.lag_stall_ticks > 0 then
                if metro_delta > expected * self.lag_stutter_ratio_high then
                    self.log_obj:Record(LogLevel.Warning, string.format(
                        "TransformLag(stutter): metro transform stalled %d ticks then jumped %.3fm (expected %.3fm / %.2fs)",
                        self.lag_stall_ticks, metro_delta, expected, self.lag_check_interval))
                    self.lag_recent_ticks = 10
                end
                self.lag_stall_ticks = 0
            end
        end

        self.prev_metro_pos = metro_pos
    end)
end

function Metro:Unmount()

    local player = Game.GetPlayer()
    -- The player may already be unmounted; bail out cleanly.
    local mounted = GetMountedVehicle(player)
    if mounted == nil then
        self.log_obj:Record(LogLevel.Warning, "Unmount: player not mounted, nothing to unmount")
            return
    end
    self.entity = mounted
    self.entity_id = self.entity:GetEntityID()
    local seat = "Passengers"

    local data = NewObject('handle:gameMountEventData')
    data.isInstant = true
    data.slotName = seat
    data.mountParentEntityId = self.entity_id
    data.allowFailsafeTeleport = true

    local slotID = NewObject('gamemountingMountingSlotId')
    slotID.id = seat

    local mounting_info = NewObject('gamemountingMountingInfo')
    mounting_info.childId = player:GetEntityID()
    mounting_info.parentId = self.entity_id
    mounting_info.slotId = slotID

    local mount_event = NewObject('handle:gamemountingUnmountingRequest')
    mount_event.lowLevelMountingInfo = mounting_info
    mount_event.mountData = data

    Game.GetMountingFacility():Unmount(mount_event)


end

function Metro:Mount()

    local player = Game.GetPlayer()
    local ent_id = self.entity_id
    local seat = "Passengers"
    local data = NewObject('handle:gameMountEventData')
    data.isInstant = true
    data.slotName = seat
    data.mountParentEntityId = ent_id
    data.allowFailsafeTeleport = true

    local slot_id = NewObject('gamemountingMountingSlotId')
    slot_id.id = seat

    local mounting_info = NewObject('gamemountingMountingInfo')
    mounting_info.childId = player:GetEntityID()
    mounting_info.parentId = ent_id
    mounting_info.slotId = slot_id

    local mounting_request = NewObject('handle:gamemountingMountingRequest')
    mounting_request.lowLevelMountingInfo = mounting_info
    mounting_request.mountData = data

    Game.GetMountingFacility():Mount(mounting_request)


end

-- Stand-hold spot: metro center line (x=0) at the seat row, facing forward.
function Metro:GetStandHoldWorldPosition()
    if self.player_seat_position == nil then
        return nil
    end
    local local_pos = Vector4.new(0, self.player_seat_position.y, self.player_seat_position.z, 1)
    return self:ExtrapolateWorldPosition(self:GetAccurateWorldPosition(local_pos))
end

function Metro:TeleportToStandHold()
    local world_pos = self:GetStandHoldWorldPosition()
    if world_pos == nil then
        return false
    end
    local forward = self:GetWorldForward()
    if forward == nil then
        return false
    end
    local angle = Vector4.ToRotation(forward)
    Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), world_pos, angle)
    return true
end

function Metro:TeleportToSafePosition()

    local world_safe_pos = self:GetAccurateWorldPosition(self.default_position)
    if world_safe_pos == nil then
        self.log_obj:Record(LogLevel.Critical, "TeleportToSafePosition: safe_pos is nil")
        return
    end
    local player = Game.GetPlayer()
    local angle = Vector4.ToRotation(self:GetWorldForward())
    Game.GetTeleportationFacility():Teleport(player, world_safe_pos, angle)

end

function Metro:SetLineInfo()

    local quest_system = Game.GetQuestsSystem()
    local track_num = quest_system:GetFact(CName.new("ue_metro_track_selected"))
    local next_station_num = quest_system:GetFact(CName.new("ue_metro_next_station"))
    self.selected_track_index = track_num
    if next_station_num ~= 0 then
        self.next_station_num = next_station_num
    end

end

function Metro:GetTrackList(station_num)
    return Data.Station[station_num].track_info
end

function Metro:IsCurrentInvalidStation()

    local track_list = self:GetTrackList(self:GetActiveStation())
    for _, track_info in pairs(track_list) do
        if track_info.track == self.selected_track_index then
            return track_info.is_invalid
        end
    end
    return true

end

function Metro:IsNextInvalidStation()

    local track_list = self:GetTrackList(self.next_station_num)
    for _, track_info in pairs(track_list) do
        if track_info.track == self.selected_track_index then
            return track_info.is_invalid
        end
    end
    return true

end

function Metro:IsNextFinalStation()

    local track_list = self:GetTrackList(self.next_station_num)
    for _, track_info in pairs(track_list) do
        if track_info.track == self.selected_track_index then
            return track_info.is_final
        end
    end
    return true

end

function Metro:IsInStation()

    if self.next_station_num == self:GetActiveStation() then
        return true
    else
        return false
    end

end

function Metro:GetActiveStation()
    return Game.GetQuestsSystem():GetFact(CName.new("ue_metro_active_station"))
end

return Metro
