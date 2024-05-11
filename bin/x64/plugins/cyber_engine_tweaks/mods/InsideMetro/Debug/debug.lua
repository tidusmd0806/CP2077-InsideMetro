local Utils = require("Tools/utils.lua")
local Debug = {}
Debug.__index = Debug

function Debug:New(core_obj)
    local obj = {}
    obj.core_obj = core_obj

    -- set parameters
    obj.is_im_gui_rw_count = false
    obj.is_im_gui_situation = false
    obj.is_set_observer = false
    return setmetatable(obj, self)
end

function Debug:ImGuiMain()

    ImGui.Begin("ITM DEBUG WINDOW")
    ImGui.Text("Debug Mode : On")

    self:SetObserver()
    self:SetLogLevel()
    self:SelectPrintDebug()
    self:ImGuiShowRWCount()
    -- self:ImGuiSituation()
    self:ImGuiExcuteFunction()

    ImGui.End()

end

function Debug:SetObserver()

    if not self.is_set_observer then
        -- reserved
    end
    self.is_set_observer = true

    if self.is_set_observer then
        ImGui.SameLine()
        ImGui.Text("Observer : On")
    end

end

function Debug:SetLogLevel()
    local selected = false
    if ImGui.BeginCombo("LogLevel", Utils:GetKeyFromValue(LogLevel, MasterLogLevel)) then
		for _, key in ipairs(Utils:GetKeys(LogLevel)) do
			if Utils:GetKeyFromValue(LogLevel, MasterLogLevel) == key then
				selected = true
			else
				selected = false
			end
			if(ImGui.Selectable(key, selected)) then
				MasterLogLevel = LogLevel[key]
			end
		end
		ImGui.EndCombo()
	end
end

function Debug:SelectPrintDebug()
    PrintDebugMode = ImGui.Checkbox("Print Debug Mode", PrintDebugMode)
end

function Debug:ImGuiShowRWCount()
    self.is_im_gui_rw_count = ImGui.Checkbox("[ImGui] R/W Count", self.is_im_gui_rw_count)
    if self.is_im_gui_rw_count then
        ImGui.Text("Read : " .. READ_COUNT .. ", Write : " .. WRITE_COUNT)
    end
end

function Debug:ImGuiSituation()
    self.is_im_gui_situation = ImGui.Checkbox("[ImGui] Current Situation", self.is_im_gui_situation)
    if self.is_im_gui_situation then
        ImGui.Text("Current Situation : " .. self.core_obj.event_obj.current_situation)
    end
end

function Debug:ImGuiExcuteFunction()
    if ImGui.Button("TF1") then
        self.core_obj.metro_obj:ActiveFreeWalking()
        print("Excute Test Function 1")
    end
    ImGui.SameLine()
    if ImGui.Button("TF2") then
        self.core_obj.metro_obj:DeactiveFreeWalking()
        print("Excute Test Function 2")
    end
    ImGui.SameLine()
    if ImGui.Button("TF3") then
        local player = Game.GetPlayer()
        local pos = player:GetWorldPosition()
        print("Player Position : " .. pos.x .. ", " .. pos.y .. ", " .. pos.z)
        local next_pos = Vector4.new(pos.x + 1, pos.y, pos.z - 50, pos.w)
        local filter = "Static"
        local res, trace = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(pos, next_pos, filter, false, false)
        print("Trace Result : " .. trace.position.x .. ", " .. trace.position.y .. ", " .. trace.position.z)
        print("Excute Test Function 3")
    end
    ImGui.SameLine()
    if ImGui.Button("TF4") then
        local player = Game.GetPlayer()
        local ent_id = self.metro_entity:GetEntityID()
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
        print("Excute Test Function 4")
    end
    ImGui.SameLine()
    if ImGui.Button("TF5") then
        local player = Game.GetPlayer()
        self.metro_entity = GetMountedVehicle(player)
        Game.GetWorkspotSystem():UnmountFromVehicle(self.metro_entity, player, false, Vector4.new(0, 0, 0, 1), Quaternion.new(0, 0, 0, 1), "Passengers")
        print("Excute Test Function 5")
    end
    ImGui.SameLine()
    if ImGui.Button("TF6") then
        local player = Game.GetPlayer()
        Game.GetWorkspotSystem():StopInDevice(player)
        print("Excute Test Function 6")
    end
    if ImGui.Button("TF7") then
        local player = Game.GetPlayer()
        self.metro_entity = GetMountedVehicle(player)
        local ent_id = self.metro_entity:GetEntityID()
        local seat = "Passengers"

        local data = NewObject('handle:gameMountEventData')
        data.isInstant = true
        data.slotName = seat
        data.mountParentEntityId = ent_id
        data.entryAnimName = "forcedTransition"

        local slotID = NewObject('gamemountingMountingSlotId')
        slotID.id = seat

        local mounting_info = NewObject('gamemountingMountingInfo')
        mounting_info.childId = player:GetEntityID()
        mounting_info.parentId = ent_id
        mounting_info.slotId = slotID

        local mount_event = NewObject('handle:gamemountingUnmountingRequest')
        mount_event.lowLevelMountingInfo = mounting_info
        mount_event.mountData = data

		Game.GetMountingFacility():Unmount(mount_event)
        print("Excute Test Function 7")
    end
    ImGui.SameLine()
    if ImGui.Button("TF8") then
        local name = CName.new("ue_metro_next_station")
        Game.GetQuestsSystem():SetFact(name, 1)
        print("Excute Test Function 8")
    end
    ImGui.SameLine()
    if ImGui.Button("TF9") then
        Cron.Every(0.01, {tick = 1}, function(timer)
            timer.tick = timer.tick + 1
            local player = Game.GetPlayer()
            local pos = player:GetWorldPosition()
            local angle = player:GetWorldOrientation():ToEulerAngles()
            local forward = player:GetWorldForward()
            local length = 0.1
            local new_pos = Vector4.new(pos.x + forward.x * length, pos.y + forward.y * length, pos.z + forward.z * length, pos.w)
            Game.GetTeleportationFacility():Teleport(player, new_pos, angle)
            if timer.tick > 1000 then
                Cron.Halt(timer)
            end
        end)
        print("Excute Test Function 9")
    end
    ImGui.SameLine()
    if ImGui.Button("TF10") then
        local spawnTransform = WorldTransform.new()
        local entityID = exEntitySpawner.Spawn("base\\entities\\cameras\\photo_mode_camera.ent", spawnTransform, '')
        Cron.Every(0.1, {tick = 1}, function(timer)
            local entity = Game.FindEntityByID(entityID)
            timer.tick = timer.tick + 1
            if entity then
                self.handle = entity
                self.hash = tostring(entity:GetEntityID().hash)
                print("Spawned camera entity: " .. self.hash)
                self.component = entity:FindComponentByName("FreeCamera2447")

                Cron.Halt(timer)
            elseif timer.tick > 20 then
                print("Failed to spawn camera")
                Cron.Halt(timer)
            end
        end)
        print("Excute Test Function 10")
    end
end

return Debug
