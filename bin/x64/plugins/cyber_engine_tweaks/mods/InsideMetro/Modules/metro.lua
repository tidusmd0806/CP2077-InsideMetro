local Metro = {}
Metro.__index = Metro

function Metro:New()
    -- instance --
    local obj = {}
    -- static --
    obj.workspot_entity_path = "base\\itm\\metro_workspot.ent"
    obj.workspot_name = "metro_workspot"
    obj.wait_time_after_standup = 2.0
    obj.despawn_count_after_standup = 250
    obj.sit_down_anim = "player__sit_chair_lean180__2h_on_lap__01__to__stand__2h_on_sides__01__turn0__01"
    -- dynamic --
    obj.entity_metro = nil
    obj.entity_metro_id = nil
    obj.workspot_entity = nil
    obj.workspot_entity_id = nil
    return setmetatable(obj, self)
end

function Metro:ActiveFreeWalking()
    self:Unmount()
end

function Metro:DeactiveFreeWalking()
    self:Mount()
end

function Metro:SetMetroEntity()
    self.entity_metro = GetMountedVehicle(Game.GetPlayer())
    if self.entity_metro == nil then
        return false
    else
        return true
    end
end

function Metro:StandUp()

    self:SetMetroEntity()
    local player = Game.GetPlayer()
    local transform = player:GetWorldTransform()
    transform:SetPosition(player:GetWorldPosition())
    local angles = player:GetWorldOrientation():ToEulerAngles()
    transform:SetOrientationEuler(EulerAngles.new(0, 0, angles.yaw))

    self.workspot_entity_id = exEntitySpawner.Spawn(self.workspot_entity_path, transform, '')

    Cron.Every(0.01, {tick = 1}, function(timer)
        self.workspot_entity = Game.FindEntityByID(self.workspot_entity_id)
        if self.workspot_entity ~= nil then
            Game.GetWorkspotSystem():StopInDevice(player)
            Cron.After(0.1, function()
                Game.GetWorkspotSystem():PlayInDeviceSimple(self.workspot_entity, player, true, self.workspot_name, nil, nil, 0, 1, nil)
                Game.GetWorkspotSystem():SendJumpToAnimEnt(player, "sit_chair_lean180__2h_on_lap__01", true)
            end)
            Cron.Every(0.01, {tick = 1}, function(timer)
                timer.tick = timer.tick + 1
                local pos = self.entity_metro:GetWorldPosition()
                local angle = self.entity_metro:GetWorldOrientation():ToEulerAngles()
                Game.GetTeleportationFacility():Teleport(self.workspot_entity, pos, angle)
                if timer.tick > self.despawn_count_after_standup then
                    exEntitySpawner.Despawn(self.workspot_entity)
                    Cron.Halt(timer)
                end
            end)
            Cron.Halt(timer)
        end
    end)
end

function Metro:Unmount()

    self:StandUp()

    Cron.After(self.wait_time_after_standup , function()

        local player = Game.GetPlayer()
        self.entity_metro = GetMountedVehicle(player)
        self.entity_metro_id = self.entity_metro:GetEntityID()
        local seat = "Passengers"

        local data = NewObject('handle:gameMountEventData')
        data.isInstant = true
        data.slotName = seat
        data.mountParentEntityId = self.entity_metro_id
        data.entryAnimName = "forcedTransition"

        local slotID = NewObject('gamemountingMountingSlotId')
        slotID.id = seat

        local mounting_info = NewObject('gamemountingMountingInfo')
        mounting_info.childId = player:GetEntityID()
        mounting_info.parentId = self.entity_metro_id
        mounting_info.slotId = slotID

        local mount_event = NewObject('handle:gamemountingUnmountingRequest')
        mount_event.lowLevelMountingInfo = mounting_info
        mount_event.mountData = data

        Game.GetMountingFacility():Unmount(mount_event)
    end)

end

function Metro:Mount()

    local player = Game.GetPlayer()
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

    self:StandUp()

end

return Metro