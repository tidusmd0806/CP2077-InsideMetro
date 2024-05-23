local Metro = {}
Metro.__index = Metro

function Metro:New()
    -- instance --
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "Metro")
    -- static --
    obj.domain = {x_max = 2.0, x_min = -2.0, y_max = 8.5, y_min = -8.5, z_max = 2.0, z_min = -0.2}
    obj.default_position = Vector4.new(0, -6, 1.5, 1)
    obj.seat_area_radius = 1.5
    -- dynamic --
    obj.entity = nil
    obj.entity_id = nil
    obj.is_mounted_player = true
    obj.player_seat_position = nil
    obj.is_player_seat_right_side = true
    obj.measurement_npc_position = nil
    obj.world_npc_position = nil
    obj.current_speed = 0
    return setmetatable(obj, self)
end

function Metro:Initialize()
    self:SetEntity()
    self:SetNPCForMeasurement()
    self:SetSpeedObserver()
end

function Metro:Uninitialize()
    self.entity = nil
    self.entity_id = nil
end

function Metro:SetEntity()
    local entity = GetMountedVehicle(Game.GetPlayer())
    if entity == nil then
        self.entity = nil
        self.entity_id = nil
        return false
    elseif self.entity == entity and self.entity_id == entity:GetEntityID() then
        return true
    elseif entity:GetClassName().value == "ncartMetroObject" then
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

function Metro:GetWorldPosition()
    return self.entity:GetWorldPosition()
end

function Metro:GetWorldOrientation()
    return self.entity:GetWorldOrientation()
end

function Metro:GetWorldRight()
    return self.entity:GetWorldRight()
end

function Metro:GetWorldForward()
    return self.entity:GetWorldForward()
end

function Metro:GetWorldUp()
    return self.entity:GetWorldUp()
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
    local x = Vector4.new(right.x * local_pos.x, right.y * local_pos.x, right.z * local_pos.x, 0)
    local y = Vector4.new(forward.x * local_pos.y, forward.y * local_pos.y, forward.z * local_pos.y, 0)
    local z = Vector4.new(up.x * local_pos.z, up.y * local_pos.z, up.z * local_pos.z, 0)
    local world_pos = Vector4.new(x.x + y.x + z.x + origin.x, x.y + y.y + z.y + origin.y, x.z + y.z + z.z + origin.z, 1)
    return world_pos

end

function Metro:IsInMetro(local_pos)

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

    local distance = Vector4.Distance(local_pos, self.player_seat_position)
    if distance < self.seat_area_radius then
        return true
    end
    return false
end

function Metro:SetNPCForMeasurement()

    local min_distance = 100
    local min_index = 0
    local player_pos = Game.GetPlayer():GetWorldPosition()
    local npcs = Game.GetPlayer():GetNPCsAroundObject()
    for index, npc in ipairs(npcs) do
        local npc_pos = npc:GetWorldPosition()
        local distnce = Vector4.Distance(player_pos, npc_pos)
        if distnce < min_distance and self:IsInMetro(self:ChangeWorldPosToLocal(npc_pos)) then
            min_distance = distnce
            min_index = index
        end
    end
    self.measurement_npc_position = self:ChangeWorldPosToLocal(npcs[min_index]:GetWorldPosition())
    self.measurement_npc_entity = npcs[min_index]

end

function Metro:GetPlayerSeatPosition()
    return self.player_seat_position
end

function Metro:SetPlayerSeatPosition()

    self.log_obj:Record(LogLevel.Trace, "SetPlayerSeatPosition")
    self.player_seat_position = self:GetAccurateLocalPosition(Game.GetPlayer():GetWorldPosition())
    if self.player_seat_position.x > 0 then
        self.is_player_seat_right_side = true
        -- self.player_seat_position.x = self.player_seat_position.x - 1
    else
        self.is_player_seat_right_side = false
        -- self.player_seat_position.x = self.player_seat_position.x + 1
    end

end

function Metro:IsPlayerSeatRightSide()
    return self.is_player_seat_right_side
end

function Metro:GetAccurateLocalPosition(world_pos)

    if self.measurement_npc_entity == nil then
        return nil
    end
    local world_npc_pos = self.measurement_npc_entity:GetWorldPosition()
    local world_metro_pos = self:GetWorldPosition()
    local vector_from_p_to_n = Vector4.new(world_pos.x - world_npc_pos.x, world_pos.y - world_npc_pos.y, world_pos.z - world_npc_pos.z, 1)
    local world_direction = Vector4.new(world_metro_pos.x + vector_from_p_to_n.x, world_metro_pos.y + vector_from_p_to_n.y, world_metro_pos.z + vector_from_p_to_n.z, 1)
    local vector_form_p_to_n_local = self:ChangeWorldPosToLocal(world_direction)
    if vector_form_p_to_n_local == nil then
        return nil
    end
    return Vector4.new(self.measurement_npc_position.x + vector_form_p_to_n_local.x, self.measurement_npc_position.y + vector_form_p_to_n_local.y, self.measurement_npc_position.z + vector_form_p_to_n_local.z, 1)

end

function Metro:GetAccurateWorldPosition(local_pos)

    if self.measurement_npc_entity == nil then
        return nil
    end
    local world_npc_pos = self:ChangeLocalPosToWorld(self.measurement_npc_position)
    local world_pos = self:ChangeLocalPosToWorld(local_pos)
    local vector_from_p_to_n = Vector4.new(world_pos.x - world_npc_pos.x, world_pos.y - world_npc_pos.y, world_pos.z - world_npc_pos.z, 1)
    local actual_npc_pos = self.measurement_npc_entity:GetWorldPosition()

    return Vector4.new(actual_npc_pos.x + vector_from_p_to_n.x, actual_npc_pos.y + vector_from_p_to_n.y, actual_npc_pos.z + vector_from_p_to_n.z, 1)

end

function Metro:SetSpeedObserver()

    Cron.Every(0.01, {tick = 1}, function(timer)
        timer.tick = timer.tick + 1
        if self.entity == nil then
            return
        end
        Cron.Every(0.01, {tick = 1}, function(timer_)
            timer_.tick = timer_.tick + 1
            if self.entity == nil then
                Cron.Halt(timer_)
                return
            elseif self.measurement_npc_entity == nil then
                return
            elseif self.world_npc_position == nil then
                self.world_npc_position = self.measurement_npc_entity:GetWorldPosition()
                return
            end
            local current_pos = self.measurement_npc_entity:GetWorldPosition()
            local distance = Vector4.Distance(current_pos, self.world_npc_position)
            self.current_speed = distance / 0.01
            self.world_npc_position = current_pos
        end)
        Cron.Halt(timer)
    end)

end

function Metro:GetSpeed()
    return self.current_speed
end

function Metro:Unmount()

    local player = Game.GetPlayer()
    self.entity = GetMountedVehicle(player)
    self.entity_id = self.entity:GetEntityID()
    local seat = "Passengers"

    local data = NewObject('handle:gameMountEventData')
    data.isInstant = true
    data.slotName = seat
    data.mountParentEntityId = self.entity_id
    data.entryAnimName = "forcedTransition"
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

    self.is_mounted_player = false

end

function Metro:Mount()

    local player = Game.GetPlayer()
    local ent_id = self.entity_id
    local seat = "Passengers"
    local data = NewObject('handle:gameMountEventData')
    data.isInstant = false
    data.slotName = seat
    data.mountParentEntityId = ent_id
    data.entryAnimName = "forcedTransition"
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

    self.is_mounted_player = true

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

function Metro:TeleportLocalDownPos(base_pos, z)

    base_pos.z = base_pos.z + z
    local world_safe_pos = self:GetAccurateWorldPosition(base_pos)
    if world_safe_pos == nil then
        self.log_obj:Record(LogLevel.Critical, "TeleportLocalPosToSafePosition: safe_pos is nil")
        return false
    end
    local player = Game.GetPlayer()
    local angle = Vector4.ToRotation(self:GetWorldForward())
    Game.GetTeleportationFacility():Teleport(player, world_safe_pos, angle)
    return true

end

return Metro
