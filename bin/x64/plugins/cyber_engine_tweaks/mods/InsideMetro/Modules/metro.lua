local Metro = {}
Metro.__index = Metro

function Metro:New(player_obj)
    -- instance --
    local obj = {}
    obj.player_obj = player_obj
    -- static --
    obj.distance_front = 1
    -- dynamic --
    obj.entity_metro = nil
    obj.entity_vehicle = nil
    obj.entity_vehicle_id = nil
    return setmetatable(obj, self)
end

function Metro:GetPosition()
    return self.entity_metro:GetWorldPosition()
end

function Metro:ActiveFreeWalking()
    self.player_obj:Update()
    self:Unmount()
end

function Metro:DeactiveFreeWalking()
    self.player_obj:Update()
    self:Mount()
end

function Metro:Unmount()
    local player = self.player_obj:GetPuppet()
    self.entity_metro = GetMountedVehicle(player)
    local player_pos = self.player_obj:GetPosition()
    local player_forward = self.player_obj:GetForward()
    local player_new_pos = Vector4.new(player_pos.x + player_forward.x * self.distance_front, player_pos.y + player_forward.y * self.distance_front, player_pos.z + player_forward.z * self.distance_front, player_pos.w)
    Game.GetWorkspotSystem():UnmountFromVehicle(self.entity, player, false, Vector4.new(0, 0, 0, 1), Quaternion.new(0, 0, 0, 1), "Passengers")

    local angle = player:GetWorldOrientation():ToEulerAngles()
    local metro_pos = self:GetPosition()
    local pos = Vector4.new(metro_pos.x, metro_pos.y, metro_pos.z + 1, metro_pos.w)
    Game.GetTeleportationFacility():Teleport(player, self:GetPosition(), angle)
    -- Cron.Every(0.01, {tick = 1}, function(timer)
    --     timer.tick = timer.tick + 1
    --     Game.GetTeleportationFacility():Teleport(player, self:GetPosition(), angle)
    --     if timer.tick >= 500 then
    --         timer:Halt(timer)
    --     end
    -- end)

    Cron.After(1 , function()

        self.entity_vehicle = GetMountedVehicle(player)
        self.entity_vehicle_id = self.entity_vehicle:GetEntityID()
        local seat = "Passengers"

        local data = NewObject('handle:gameMountEventData')
        data.isInstant = true
        data.slotName = seat
        data.mountParentEntityId = self.entity_vehicle_id
        data.entryAnimName = "forcedTransition"

        local slotID = NewObject('gamemountingMountingSlotId')
        slotID.id = seat

        local mounting_info = NewObject('gamemountingMountingInfo')
        mounting_info.childId = player:GetEntityID()
        mounting_info.parentId = self.entity_vehicle_id
        mounting_info.slotId = slotID

        local mount_event = NewObject('handle:gamemountingUnmountingRequest')
        mount_event.lowLevelMountingInfo = mounting_info
        mount_event.mountData = data

        Game.GetMountingFacility():Unmount(mount_event)
        Cron.After(1 , function()
            self:StickPlayerToFloor()
        end)
    end)

end

function Metro:Mount()
    local player = self.player_obj:GetPuppet()
    local ent_id = self.entity_metro:GetEntityID()
    local seat = "Passengers"
    local data = NewObject('handle:gameMountEventData')
    data.isInstant = false
    data.slotName = seat
    data.mountParentEntityId = ent_id

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

function Metro:StickPlayerToFloor()
    Cron.Every(0.1, {tick = 1}, function(timer)
        self.player_obj:Update()
        local player = self.player_obj:GetPuppet()
        local player_pos = self.player_obj:GetPosition()
        local raycast_end_pos = Vector4.new(player_pos.x, player_pos.y, player_pos.z - 10, player_pos.w)
        local res, trace_result = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(player_pos, raycast_end_pos, "Static", false, false)
        if trace_result ~= nil then
            local pos = Vector4.new(trace_result.position.x, trace_result.position.y, trace_result.position.z, player_pos.w)
            Game.GetTeleportationFacility():Teleport(player, pos, self.player_obj:GetAngle())
        end
    end)
end

return Metro