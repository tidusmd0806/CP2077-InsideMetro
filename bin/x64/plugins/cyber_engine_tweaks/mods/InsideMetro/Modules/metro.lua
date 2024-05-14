local Metro = {}
Metro.__index = Metro

function Metro:New()
    -- instance --
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "Metro")
    -- dynamic --
    obj.entity = nil
    obj.entity_id = nil
    obj.is_mounted_player = true
    obj.player_seat_position = nil
    return setmetatable(obj, self)
end

function Metro:Init()
    self:SetMetroEntity()
    self:SetPlayerSeatPosition()
end

function Metro:SetMetroEntity()
    self.entity = GetMountedVehicle(Game.GetPlayer())
    if self.entity == nil then
        return false
    else
        return true
    end
end

function Metro:IsMountedPlayer()
    return self.is_mounted_player
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

function Metro:GetLocalPosition(pos)
    local origin = self:GetWorldPosition()
    local right = self:GetWorldRight()
    local forward = self:GetWorldForward()
    local up = self:GetWorldUp()
    local relative = Vector4.new(pos.x - origin.x, pos.y - origin.y, pos.z - origin.z, 1)
    local x = Vector4.Dot(relative, right)
    local y = Vector4.Dot(relative, forward)
    local z = Vector4.Dot(relative, up)
    return Vector4.new(x, y, z, 1)
end

function Metro:SetPlayerSeatPosition()
    self.player_seat_position = self:GetLocalPosition(Game.GetPlayer():GetWorldPosition())
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

return Metro