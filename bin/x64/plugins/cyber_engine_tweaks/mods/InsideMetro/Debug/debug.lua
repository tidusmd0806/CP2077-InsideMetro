local Debug = {}
Debug.__index = Debug

function Debug:New(core_obj)
    local obj = {}
    obj.core_obj = core_obj

    -- set parameters
    obj.is_im_gui_check_status = false
    obj.is_im_gui_player_local = false
    obj.is_im_gui_seat_position = false
    obj.is_im_gui_metro_speed = false
    obj.is_set_observer = false
    obj.is_im_gui_line_info = false
    obj.is_im_gui_measurement = false
    obj.is_im_gui_ristrict = false
    return setmetatable(obj, self)
end

function Debug:ImGuiMain()

    ImGui.Begin("InsideMetro DEBUG WINDOW")
    ImGui.Text("Debug Mode : On")

    self:SetObserver()
    self:SetLogLevel()
    self:SelectPrintDebug()
    self:ImGuiCheckStatus()
    self:ImGuiPlayerLocalPosition()
    self:ImGuiSeatPosition()
    self:ImGuiMetroSpeed()
    self:ImGuiRistrictedArea()
    self:ImGuiLineInfo()
    self:ImGuiMeasurement()
    self:ImGuiExcuteFunction()

    ImGui.End()

end

function Debug:SetObserver()

    if not self.is_set_observer then
        -- reserved
        -- Observe("NcartMetroComponent", "OnMountingEvent", function(this, event)
        --     print(event:GetClassName().value)
        --     if event:GetClassName().value == "enteventsPhysicalCollisionEvent" then
        --         print("collision")
        --     end
        -- end)
        -- Observe("QuestsSystem", "GetFact", function(this, factName)
        --     if string.find(factName.value, "ue_metro") then
        --         print('GetFact')
        --         print(factName.value)
        --     end
        -- end)
        Observe("QuestsSystem", "SetFact", function(this, factName, value)
            if string.find(factName.value, "ue_metro") then
                print('SetFact')
                print(factName.value)
                print(value)
            end
        end)
    
    end
    self.is_set_observer = true

    if self.is_set_observer then
        ImGui.SameLine()
        ImGui.Text("Observer : On")
    end

end

function Debug:SetLogLevel()
    function GetKeyFromValue(table_, target_value)
        for key, value in pairs(table_) do
            if value == target_value then
                return key
            end
        end
        return nil
    end
    function GetKeys(table_)
        local keys = {}
        for key, _ in pairs(table_) do
            table.insert(keys, key)
        end
        return keys
     end
    local selected = false
    if ImGui.BeginCombo("LogLevel", GetKeyFromValue(LogLevel, MasterLogLevel)) then
		for _, key in ipairs(GetKeys(LogLevel)) do
			if GetKeyFromValue(LogLevel, MasterLogLevel) == key then
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

function Debug:ImGuiCheckStatus()
    self.is_im_gui_check_status = ImGui.Checkbox("[ImGui] Check Status", self.is_im_gui_check_status)
    if self.is_im_gui_check_status then
        local status = self.core_obj.event_obj.current_status
        ImGui.Text("Status : " .. status)
        if Game.GetWorkspotSystem():IsActorInWorkspot(Game.GetPlayer()) then
            ImGui.Text("In Workspot : True")
        else
            ImGui.Text("In Workspot : False")
        end
    end
end

function Debug:ImGuiPlayerLocalPosition()
    self.is_im_gui_player_local = ImGui.Checkbox("[ImGui] Player Local Pos", self.is_im_gui_player_local)
    if self.is_im_gui_player_local then
        local player = Game.GetPlayer()
        if player == nil then
            return
        end
        local player_pos = player:GetWorldPosition()
        if self.core_obj.metro_obj.entity == nil or  self.core_obj.metro_obj.measurement_npc_position == nil then
            return
        end
        local player_local_pos = self.core_obj.metro_obj:ChangeWorldPosToLocal(player_pos)
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
        local npc_pos = self.core_obj.metro_obj.measurement_npc_position
        local npc_position_x = string.format("%.2f", npc_pos.x)
        local npc_position_y = string.format("%.2f", npc_pos.y)
        local npc_position_z = string.format("%.2f", npc_pos.z)
        ImGui.Text("NPC Measurement Pos : " .. npc_position_x .. ", " .. npc_position_y .. ", " .. npc_position_z)
        local pos = self.core_obj.metro_obj:GetAccurateLocalPosition(Game.GetPlayer():GetWorldPosition())
        if pos == nil then
            return
        end
        local player_pos_x = string.format("%.2f", pos.x)
        local player_pos_y = string.format("%.2f", pos.y)
        local player_pos_z = string.format("%.2f", pos.z)
        ImGui.Text("Player Local Pos Correctly : " .. player_pos_x .. ", " .. player_pos_y .. ", " .. player_pos_z)
        local prev_pos = self.core_obj.event_obj.prev_player_local_pos
        if prev_pos == nil then
            return
        end
        local prev_pos_x = string.format("%.2f", prev_pos.x)
        local prev_pos_y = string.format("%.2f", prev_pos.y)
        local prev_pos_z = string.format("%.2f", prev_pos.z)
        ImGui.Text("Player Prev Pos : " .. prev_pos_x .. ", " .. prev_pos_y .. ", " .. prev_pos_z)
    end
end

function Debug:ImGuiSeatPosition()
    self.is_im_gui_seat_position = ImGui.Checkbox("[ImGui] Seat Position", self.is_im_gui_seat_position)
    if self.is_im_gui_seat_position then
        local pos = self.core_obj.metro_obj.player_seat_position
        if pos == nil then
            return
        end
        local x = string.format("%.2f", pos.x)
        local y = string.format("%.2f", pos.y)
        local z = string.format("%.2f", pos.z)
        ImGui.Text("Seat Position : " .. x .. ", " .. y .. ", " .. z)
        if self.core_obj.metro_obj.is_player_seat_right_side then
            ImGui.Text("Seat Side : Right")
        else
            ImGui.Text("Seat Side : Left")
        end
    end
end

function Debug:ImGuiMetroSpeed()
    self.is_im_gui_metro_speed = ImGui.Checkbox("[ImGui] Metro Speed", self.is_im_gui_metro_speed)
    if self.is_im_gui_metro_speed then
        local metro_speed = self.core_obj.metro_obj:GetSpeed()
        ImGui.Text("Metro Speed : " .. metro_speed)
        local res = self.core_obj.event_obj.is_on_ground
        if res then
            ImGui.Text("On Ground : True")
        else
            ImGui.Text("On Ground : False")
        end
    end
end

function Debug:ImGuiRistrictedArea()
    self.is_im_gui_ristrict = ImGui.Checkbox("[ImGui] Available Station", self.is_im_gui_ristrict)
    if self.is_im_gui_ristrict then
        if self.core_obj.metro_obj:IsInvalidStation() then
            ImGui.Text("In Restricted Area : True")
        else
            ImGui.Text("In Restricted Area : False")
        end
    end
end

function Debug:ImGuiLineInfo()
    self.is_im_gui_line_info = ImGui.Checkbox("[ImGui] Line Info", self.is_im_gui_line_info)
    if self.is_im_gui_line_info then
        local active_station = Game.GetQuestsSystem():GetFact(CName.new("ue_metro_active_station"))
        local next_station = Game.GetQuestsSystem():GetFact(CName.new("ue_metro_next_station"))
        local line = Game.GetQuestsSystem():GetFact(CName.new("ue_metro_track_selected"))
        ImGui.Text("Activate Station : " .. active_station)
        ImGui.Text("Next Station : " .. next_station)
        ImGui.Text("Line : " .. line)
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
        local sys = Game.GetPlayer():GetFastTravelSystem()
        local arr = sys:GetFastTravelPoints()
        print(#arr)
        for _, point in ipairs(arr) do
            local pointID = tostring(point.pointRecord.value)
            if string.find(pointID, 'wat_lch_metro_ftp_02', 1, true) then
                print("aaa")
                pointData = point
                break
            end
        end
        sys:PerformFastTravel(Game.GetPlayer(), pointData)
        sys:SetFastTravelStarted()
        print("Excute Test Function 1")
    end
    ImGui.SameLine()
    if ImGui.Button("TF2") then
        local player = Game.GetPlayer()
        local player_pos = player:GetWorldPosition()
        local forward = player:GetWorldForward()
        local new_pos = Vector4.new(player_pos.x + 3 * forward.x, player_pos.y + 3 * forward.y, player_pos.z + 3 * forward.z, player_pos.w)
        local angle = player:GetWorldOrientation():ToEulerAngles()
        Game.GetTeleportationFacility():Teleport(player, new_pos, angle)
        print("Excute Test Function 2")
    end
    ImGui.SameLine()
    if ImGui.Button("TF3") then
        local entity = Game.GetPlayer()
        local component = entColliderComponent.new()
        component.name = "collider"
        local actor = physicsColliderBox.new()
        -- local actor
        -- local color = colors[settings.colliderColor + 1]

        -- if self.shape == 0 then
        --     actor = physicsColliderBox.new()
        --     actor.halfExtents = ToVector3(self.extents)
        --     visualizer.addBox(entity, self.extents, color)
        -- elseif self.shape == 1 then
        --     actor = physicsColliderCapsule.new()
        --     actor.height = self.height
        --     actor.radius = self.radius
        --     visualizer.addCapsule(entity, self.radius, self.height, color)
        -- elseif self.shape == 2 then
        --     actor = physicsColliderSphere.new()
        --     actor.radius = self.radius
        --     visualizer.addSphere(entity, self.radius, color)
        -- end

        actor.material = "concrete.physmat"

        component.colliders = { actor }

        local filterData = physicsFilterData.new()
        filterData.preset = self.preset

        local query = physicsQueryFilter.new()
        query.mask1 = 0
        query.mask2 = 0

        local sim = physicsSimulationFilter.new()
        sim.mask1 = 0
        sim.mask2 = 0

        filterData.queryFilter = query
        filterData.simulationFilter = sim
        component.filterData = filterData

        entity:AddComponent(component)
        print("Excute Test Function 3")
    end
    ImGui.SameLine()
    if ImGui.Button("TF4") then
        -- local sys = Game.GetPlayer():GetFastTravelSystem()
        -- local ft_point = RegisterFastTravelPointsRequest.new()
        -- ft_point.forceRefreshUI = true
        -- ft_point.isEnabled = true
        -- ft_point.reason = CName.new("InVehicle")
        -- local ft_enable = EnableFastTravelRequest.new()
        -- sys:QueueRequest(ft_enable)
        -- local questsSystem = Game.GetQuestsSystem()
        -- local factMetroStationNext = CName.new("ue_metro_next_station")
        -- local metroStationNextListenerId = questsSystem.RegisterListener(factMetroStationNext, this, n"OnMetroStationNextChange");
        local system = Game.GetQuestsSystem()
        system:SetFact(CName.new("ue_metro_next_station"), 1) 
        print("Excute Test Function 4")
    end
    ImGui.SameLine()
    if ImGui.Button("TF5") then
        print(Game.GetQuestsSystem():SetFact(CName.new("ue_metro_free_roam_get_up"), 1))
        print("Excute Test Function 5")
    end
    ImGui.SameLine()
    if ImGui.Button("TF6") then
        local current_pos = Game.GetPlayer():GetWorldPosition()
        print(current_pos.x .. ", " .. current_pos.y .. ", " .. current_pos.z)
        print("Excute Test Function 6")
    end

end

return Debug
