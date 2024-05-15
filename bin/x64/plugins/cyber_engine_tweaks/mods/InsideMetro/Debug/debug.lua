local Utils = require("Tools/utils.lua")
local Debug = {}
Debug.__index = Debug

function Debug:New(core_obj)
    local obj = {}
    obj.core_obj = core_obj

    -- set parameters
    obj.is_im_gui_rw_count = false
    obj.is_im_gui_check_anim = false
    obj.is_im_gui_player_local = false
    obj.is_set_observer = false
    obj.is_im_gui_measurement = false
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
    self:ImGuiPlayerLocalPosition()
    self:ImGuiMeasurement()
    self:ImGuiExcuteFunction()

    ImGui.End()

end

function Debug:SetObserver()

    if not self.is_set_observer then
        -- reserved
        Observe('DataTerm', 'OpenSubwayGate', function(this)
            print('OpenSubwayGate')
        end)
        -- Observe('gameWorkspotGameSystem', 'StopInDevice', function(this)
        --     print('stopindevice')
        -- end)
        -- Observe('gameWorkspotGameSystem', 'SendReactionSignal', function(this)
        --     print('SendReactionSignal')
        -- end)
        -- Observe('gameWorkspotGameSystem', 'IsReactionAvailable', function(this)
        --     print('IsReactionAvailable')
        -- end)
        -- Observe('gameWorkspotGameSystem', 'MountToVehicle', function(this, parent, child, slidetime, animDelay, workspotresourceContaior, slotname, syncronizedObjects, entrysolt, anuvari)
        --     print(slidetime)
        --     print(animDelay)
        --     print(workspotresourceContaior.value)
        --     print(slotname.value)
        --     print(entrysolt.value)
        --     print(anuvari[1].value)
        -- end)
        -- Observe('gameWorkspotGameSystem', 'UnmountFromVehicle', function(this, parent, child, instance, pos, ori, exit)
        --     print(exit.value)
        -- end)
        -- Observe('WorkspotEvents', 'SetWorkspotAnimFeature', function(this)
        --     print('SetWorkspotAnimFeature')
        -- end)
        -- Override('gameWorkspotGameSystem', 'MountToVehicle', function(this, event, wrappred_method)
        --     print('MountToVehicle')
        -- end)
        -- Override('LocomotionTransition', 'IsTouchingGround', function(this, script_interface, wrapped_method)
        --     local res = wrapped_method(script_interface)
        --     -- print(res)
        --     return res
        -- end)
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

function Debug:ImGuiPlayerLocalPosition()
    self.is_im_gui_player_local = ImGui.Checkbox("[ImGui] Player Local Pos", self.is_im_gui_player_local)
    if self.is_im_gui_player_local then
        local player_pos = Game.GetPlayer():GetWorldPosition()
        local player_local_pos = self.core_obj.metro_obj:ChangeLocalPosition(player_pos)
        if player_local_pos == nil then
            return
        end
        local x_lo = string.format("%.2f", player_pos.x)
        local y_lo = string.format("%.2f", player_pos.y)
        local z_lo = string.format("%.2f", player_pos.z)
        ImGui.Text("Player World Pos : " .. x_lo .. ", " .. y_lo .. ", " .. z_lo)
        local absolute_position_x = string.format("%.2f", player_local_pos.x)
        local absolute_position_y = string.format("%.2f", player_local_pos.y)
        local absolute_position_z = string.format("%.2f", player_local_pos.z)
        ImGui.Text("Player Local Pos : " .. absolute_position_x .. ", " .. absolute_position_y .. ", " .. absolute_position_z)
        local vector = Vector4.new(player_local_pos.x, player_local_pos.y, player_local_pos.z, 1)
        local world_pos = self.core_obj.metro_obj:ChangeWorldPosition(vector)
        local x = string.format("%.2f", world_pos.x)
        local y = string.format("%.2f", world_pos.y)
        local z = string.format("%.2f", world_pos.z)
        ImGui.Text("Player World Pos : " .. x .. ", " .. y .. ", " .. z)
    end
end

function Debug:ImGuiMeasurement()
    self.is_im_gui_measurement = ImGui.Checkbox("[ImGui] Measurement", self.is_im_gui_measurement)
    if self.is_im_gui_measurement then
        local res_x, res_y = GetDisplayResolution()
        ImGui.SetNextWindowPos((res_x / 2) - 20, (res_y / 2) - 20)
        ImGui.SetNextWindowSize(40, 40)
        ImGui.SetNextWindowSizeConstraints(40, 40, 40, 40)
        ---
        ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 10)
        ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 5)
        ---
        ImGui.Begin("Crosshair", ImGuiWindowFlags.NoMove + ImGuiWindowFlags.NoCollapse + ImGuiWindowFlags.NoTitleBar + ImGuiWindowFlags.NoResize)
        ImGui.End()
        ---
        ImGui.PopStyleVar(2)
        ImGui.PopStyleColor(1)
        local look_at_pos = Game.GetTargetingSystem():GetLookAtPosition(Game.GetPlayer())
        if self.core_obj.metro_obj.entity == nil then
            return
        end
        local origin = self.core_obj.metro_obj.entity:GetWorldPosition()
        local right = self.core_obj.metro_obj.entity:GetWorldRight()
        local forward = self.core_obj.metro_obj.entity:GetWorldForward()
        local up = self.core_obj.metro_obj.entity:GetWorldUp()
        local relative = Vector4.new(look_at_pos.x - origin.x, look_at_pos.y - origin.y, look_at_pos.z - origin.z, 1)
        local x = Vector4.Dot(relative, right)
        local y = Vector4.Dot(relative, forward)
        local z = Vector4.Dot(relative, up)
        local absolute_position_x = string.format("%.2f", x)
        local absolute_position_y = string.format("%.2f", y)
        local absolute_position_z = string.format("%.2f", z)
        ImGui.Text("[LookAt]X:" .. absolute_position_x .. ", Y:" .. absolute_position_y .. ", Z:" .. absolute_position_z)
    end
end

function Debug:ImGuiExcuteFunction()
    if ImGui.Button("TF1") then
        self.core_obj:EnableWalkingMetro()
        print("Excute Test Function 1")
    end
    ImGui.SameLine()
    if ImGui.Button("TF2") then
        self.core_obj:DisableWalkingMetro()
        print("Excute Test Function 2")
    end
    ImGui.SameLine()
    if ImGui.Button("TF3") then
        self.core_obj:Init()
        print(self.core_obj.metro_obj.player_seat_position.x .. ", " .. self.core_obj.metro_obj.player_seat_position.y .. ", " .. self.core_obj.metro_obj.player_seat_position.z)
        print("Excute Test Function 3")
    end
    ImGui.SameLine()
    if ImGui.Button("TF4") then
        local entity = self.core_obj.metro_obj.entity:FindComponentByName("OccupantSlots"):GetEntity()
        local entity_pos = entity:GetWorldPosition()
        local local_pos = self.core_obj.metro_obj:ChangeLocalPosition(entity_pos)
        print(entity_pos.x .. ", " .. entity_pos.y .. ", " .. entity_pos.z)
        print(local_pos.x .. ", " .. local_pos.y .. ", " .. local_pos.z)
        local world_pos = self.core_obj.metro_obj:ChangeWorldPosition(local_pos)
        print(world_pos.x .. ", " .. world_pos.y .. ", " .. world_pos.z)
        print("Excute Test Function 4")
    end
    ImGui.SameLine()
    if ImGui.Button("TF5") then
        local player_pos = Game.GetPlayer():GetWorldPosition()
        local right = self.core_obj.metro_obj.entity:GetWorldRight()
        local forward = self.core_obj.metro_obj.entity:GetWorldForward()
        local up = self.core_obj.metro_obj.entity:GetWorldUp()
        local filter = "Static"
        local ratio = 20
        local next_pos_right = Vector4.new(player_pos.x + ratio * right.x, player_pos.y + ratio * right.y, player_pos.z + ratio * right.z, player_pos.w)
        local next_pos_forward = Vector4.new(player_pos.x + ratio * forward.x, player_pos.y + ratio * forward.y, player_pos.z + ratio * forward.z, player_pos.w)
        local next_pos_up = Vector4.new(player_pos.x + ratio * up.x, player_pos.y + ratio * up.y, player_pos.z + ratio * up.z, player_pos.w)
        local success, trace_result = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(player_pos, next_pos_right, filter, false, false)
        if success then
            print("Success Right")
            local trace_result_pos = trace_result.position
            print(trace_result_pos.x .. ", " .. trace_result_pos.y .. ", " .. trace_result_pos.z)
        end
        success, trace_result = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(player_pos, next_pos_forward, filter, false, false)
        if success then
            print("Success Forward")
            local trace_result_pos = trace_result.position
            print(trace_result_pos.x .. ", " .. trace_result_pos.y .. ", " .. trace_result_pos.z)
        end
        success, trace_result = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(player_pos, next_pos_up, filter, false, false)
        if success then
            print("Success Up")
            local trace_result_pos = trace_result.position
            print(trace_result_pos.x .. ", " .. trace_result_pos.y .. ", " .. trace_result_pos.z)
        end
        print("Excute Test Function 5")
    end
    ImGui.SameLine()
    if ImGui.Button("TF6") then
        local arr = self.core_obj.metro_obj.entity:FindComponentByName("OccupantSlots")
        print(arr[1].x .. ", " .. arr[1].y .. ", " .. arr[1].z)
        print("Excute Test Function 6")
    end
    if ImGui.Button("TF7") then
        print(self.core_obj.metro_obj.entity.pitchingValue)
        print(self.core_obj.metro_obj.entity.Z)
        print("Excute Test Function 7")
    end
    ImGui.SameLine()
    if ImGui.Button("TF8") then
        self.core_obj.metro_obj.entity:PerformPitchAdjustment(500)
        print("Excute Test Function 8")
    end
    ImGui.SameLine()
    if ImGui.Button("TF9") then
        Cron.Every(0.01, {tick = 1}, function(timer)
            print(self.core_obj.metro_obj.entity:GetCurrentSpeed())
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
