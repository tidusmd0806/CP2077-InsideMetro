local Utils = require("Tools/utils.lua")
local Debug = {}
Debug.__index = Debug

function Debug:New(core_obj)
    local obj = {}
    obj.core_obj = core_obj

    -- set parameters
    obj.is_im_gui_rw_count = false
    obj.is_im_gui_check_anim = false
    obj.is_set_observer = false
    self.input_text_1 = ""
    return setmetatable(obj, self)
end

function Debug:ImGuiMain()

    ImGui.Begin("ITM DEBUG WINDOW")
    ImGui.Text("Debug Mode : On")

    self:SetObserver()
    self:SetLogLevel()
    self:SelectPrintDebug()
    self:ImGuiShowRWCount()
    self:ImGuiCheckAnim()
    self:ImGuiExcuteFunction()

    ImGui.End()

end

function Debug:SetObserver()

    if not self.is_set_observer then
        -- reserved
        Observe('gameWorkspotGameSystem', 'PlayInDevice', function(this)
            print('playindevice')
        end)
        Observe('gameWorkspotGameSystem', 'StopInDevice', function(this)
            print('stopindevice')
        end)
        Observe('gameWorkspotGameSystem', 'SendReactionSignal', function(this)
            print('SendReactionSignal')
        end)
        Observe('gameWorkspotGameSystem', 'IsReactionAvailable', function(this)
            print('IsReactionAvailable')
        end)
        -- Observe('gameWorkspotGameSystem', 'MountToVehicle', function(this, parent, child, slidetime, animDelay, workspotresourceContaior, slotname, syncronizedObjects, entrysolt, anuvari)
        --     print(slidetime)
        --     print(animDelay)
        --     print(workspotresourceContaior.value)
        --     print(slotname.value)
        --     print(entrysolt.value)
        --     print(anuvari[1].value)
        -- end)
        Observe('gameWorkspotGameSystem', 'UnmountFromVehicle', function(this, parent, child, instance, pos, ori, exit)
            print(exit.value)
        end)
        Observe('WorkspotEvents', 'SetWorkspotAnimFeature', function(this)
            print('SetWorkspotAnimFeature')
        end)
        Override('gameWorkspotGameSystem', 'MountToVehicle', function(this, event, wrappred_method)
            print('MountToVehicle')
        end)
        Override('LocomotionTransition', 'IsTouchingGround', function(this, script_interface, wrapped_method)
            local res = wrapped_method(script_interface)
            -- print(res)
            return res
        end)
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

function Debug:ImGuiCheckAnim()
    self.is_im_gui_check_anim = ImGui.Checkbox("[ImGui] check anim", self.is_im_gui_check_anim)
    if self.is_im_gui_check_anim then
        self.input_text_1 =  ImGui.InputText("##AnimName", self.input_text_1, 100)
        if ImGui.Button("PlayAnim") then
            local anim_name = CName.new(self.input_text_1)
            local player = Game.GetPlayer()
            local transform = player:GetWorldTransform()
            transform:SetPosition(player:GetWorldPosition())
            local angles = player:GetWorldOrientation():ToEulerAngles()
            transform:SetOrientationEuler(EulerAngles.new(0, 0, angles.yaw))
        
            local dummy_entity_id = exEntitySpawner.Spawn("base\\itm\\metro_workspot.ent", transform, '')
        
            Cron.Every(0.01, {tick = 1}, function(timer)
                local dummy_entity = Game.FindEntityByID(dummy_entity_id)
                if dummy_entity ~= nil then
                    Game.GetWorkspotSystem():StopInDevice(Game.GetPlayer())
                    Cron.After(0.1, function()
                        Game.GetWorkspotSystem():PlayInDeviceSimple(dummy_entity, player, true, "metro_workspot", nil, nil, 0, 1, nil)
                        Game.GetWorkspotSystem():SendJumpToAnimEnt(player, anim_name, true)
                    end)
                    Cron.Halt(timer)
                end
            end)
            print("Excute Test Function 1")
        end
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
        Game.GetWorkspotSystem():StopInDevice(Game.GetPlayer(), Vector4.new(0, 0, 100, 1), Quaternion.new(0, 0, 0, 1))
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
        local player = Game.GetPlayer()
        local dummy_entity = GetMountedVehicle(player)
        local workspot_resorce_component_name = "trunkBodyDisposalPlayer"
        local pose_name = "sit_metro_lean180__lh_window__01"
        -- Game.GetWorkspotSystem():PlayInDeviceSimple(dummy_entity, player, true, workspot_resorce_component_name, nil, nil, 0, 1, nil)
        -- Game.GetWorkspotSystem():PlayInDeviceSimple(dummy_entity, player, true)
        -- Game.GetWorkspotSystem():SendJumpToAnimEnt(player, pose_name, false)
        Game.GetWorkspotSystem():SendPlaySignal(player)
        print(Game.GetWorkspotSystem():IsActorInWorkspot(player))
        print(Game.GetWorkspotSystem():IsInVehicleWorkspot(dummy_entity, player, "Passengers"))
        print(Game.GetWorkspotSystem():IsWorkspotEnabled(player))

		local seID_1 = TweakDBID.new("GameplayRestriction.NoJump")
        local seID_2 = TweakDBID.new("GameplayRestriction.NoSprint")
		StatusEffectHelper.ApplyStatusEffect(player, seID_1)
        StatusEffectHelper.ApplyStatusEffect(player, seID_2)

        print("Excute Test Function 10")
    end
    ImGui.SameLine()
    if ImGui.Button("TF11") then
        local player = Game.GetPlayer()
        local metro = GetMountedVehicle(player)
        local workspot_name = CName.new("OccupantSlots")
        local slot_name= CName.new("Passengers2")
        Game.GetWorkspotSystem():MountToVehicle(metro ,player, 0, 0, workspot_name, slot_name)
        print("Excute Test Function 11")
    end
    ImGui.SameLine()
    if ImGui.Button("TF12") then
        local player = Game.GetPlayer()
        local metro = GetMountedVehicle(player)
        local workspot_name = CName.new("OccupantSlots")
        local slot_name= CName.new("Passengers")
        Game.GetWorkspotSystem():SwitchSeatVehicle(metro ,player, workspot_name, slot_name)
        print("Excute Test Function 12")
    end
    ImGui.SameLine()
    if ImGui.Button("TF13") then
        local player = Game.GetPlayer()
        local transform = player:GetWorldTransform()
        transform:SetPosition(player:GetWorldPosition())
        local angles = player:GetWorldOrientation():ToEulerAngles()
        transform:SetOrientationEuler(EulerAngles.new(0, 0, angles.yaw))
    
        self.dummy_entity_id = exEntitySpawner.Spawn("base\\dav\\dummy_seat.ent", transform, '')
    
        Cron.Every(0.01, {tick = 1}, function(timer)
            local dummy_entity = Game.FindEntityByID(self.dummy_entity_id)
            if dummy_entity ~= nil then
                Game.GetWorkspotSystem():StopInDevice(Game.GetPlayer())
                Cron.After(0.1, function()
                    Game.GetWorkspotSystem():PlayInDeviceSimple(dummy_entity, player, true, "av_seat_workspot", nil, nil, 0, 1, nil)
                    Game.GetWorkspotSystem():SendJumpToAnimEnt(player, "sit_chair_lean180__2h_on_lap__01", true)
                end)
                Cron.Every(0.01, {tick = 1}, function(timer)
                    timer.tick = timer.tick + 1
                    local dummy_entity = Game.FindEntityByID(self.dummy_entity_id)
                    local pos = GetMountedVehicle(player):GetWorldPosition()
                    local angle = GetMountedVehicle(player):GetWorldOrientation():ToEulerAngles()
                    Game.GetTeleportationFacility():Teleport(dummy_entity, pos, angle)
                    if timer.tick > 2000 then
                        Cron.Halt(timer)
                    end
                end)
                Cron.Halt(timer)
            end
        end)
        print("Excute Test Function 13")
    end
    ImGui.SameLine()
    if ImGui.Button("TF14") then
        local player = Game.GetPlayer()
        local transform = player:GetWorldTransform()
        transform:SetPosition(player:GetWorldPosition())
        local angles = player:GetWorldOrientation():ToEulerAngles()
        transform:SetOrientationEuler(EulerAngles.new(0, 0, angles.yaw))
    
        self.dummy_entity_id = exEntitySpawner.Spawn("base\\itm\\metro_workspot.ent", transform, '')
    
        Cron.Every(0.01, {tick = 1}, function(timer)
            local dummy_entity = Game.FindEntityByID(self.dummy_entity_id)
            if dummy_entity ~= nil then
                Game.GetWorkspotSystem():StopInDevice(Game.GetPlayer())
                Cron.After(0.1, function()
                    Game.GetWorkspotSystem():PlayInDeviceSimple(dummy_entity, player, true, "metro_workspot", nil, nil, 0, 1, nil)
                    Game.GetWorkspotSystem():SendJumpToAnimEnt(player, "sit_chair_lean180__2h_on_lap__01", true)
                end)
                Cron.Every(0.01, {tick = 1}, function(timer)
                    timer.tick = timer.tick + 1
                    local dummy_entity = Game.FindEntityByID(self.dummy_entity_id)
                    local pos = GetMountedVehicle(player):GetWorldPosition()
                    local angle = GetMountedVehicle(player):GetWorldOrientation():ToEulerAngles()
                    Game.GetTeleportationFacility():Teleport(dummy_entity, pos, angle)
                    if timer.tick > 2000 then
                        Cron.Halt(timer)
                    end
                end)
                Cron.Halt(timer)
            end
        end)
        print("Excute Test Function 14")
    end
end

return Debug
