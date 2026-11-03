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
    obj.is_im_gui_spawn = false
    obj.spawned_metro_id = nil
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
    self:ImGuiSpawnMetro()

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
        local qs = Game.GetQuestsSystem()
        ImGui.Text(string.format("pose_change=%d stand_door=%d",
            qs:GetFactStr("ue_metro_signal_pose_change"), qs:GetFactStr("ue_metro_player_stand_door")))
        local ok, info = pcall(function() return Game.GetWorkspotSystem():GetExtendedInfo(Game.GetPlayer()) end)
        if ok and info ~= nil then
            ImGui.Text(string.format("ws: active=%s entering=%s exiting=%s",
                tostring(info.isActive), tostring(info.entering), tostring(info.exiting)))
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
        if self.core_obj.metro_obj.entity == nil then
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
    self.is_im_gui_ristrict = ImGui.Checkbox("[ImGui] Station", self.is_im_gui_ristrict)
    if self.is_im_gui_ristrict then
        local next_station_num = self.core_obj.metro_obj.next_station_num
        ImGui.Text("Next Station : " .. next_station_num)
        if self.core_obj.metro_obj:IsNextInvalidStation() then
            ImGui.Text("Next Invalid : True")
        else
            ImGui.Text("Next Invalid : False")
        end
        if self.core_obj.metro_obj:IsNextFinalStation() then
            ImGui.Text("Next Final : True")
        else
            ImGui.Text("Next Final : False")
        end
        if self.core_obj.metro_obj:IsInStation() then
            ImGui.Text("In Station : True")
        else
            ImGui.Text("In Station : False")
        end
        if self.core_obj.metro_obj:IsCurrentInvalidStation() then
            ImGui.Text("Current Invalid : True")
        else
            ImGui.Text("Current Invalid : False")
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

-- TEMP: spawn the metro train ent via codeware dynamic entity system
function Debug:ImGuiSpawnMetro()
    self.is_im_gui_spawn = ImGui.Checkbox("[ImGui] Spawn Metro (temp)", self.is_im_gui_spawn)
    if self.is_im_gui_spawn then
        if ImGui.Button("Spawn ue_metro_train") then
            local player = Game.GetPlayer()
            local pos = player:GetWorldPosition()
            local forward = player:GetWorldForward()
            local spawn_pos = Vector4.new(pos.x + forward.x * 10, pos.y + forward.y * 10, pos.z + 1, 1)
            local angle = Quaternion.new(player:GetWorldOrientation())
            local spec = DynamicEntitySpec.new()
            spec.recordID = "Vehicle.ue_metro_train"
            spec.position = spawn_pos
            spec.orientation = angle
            spec.alwaysSpawned = true
            spec.persistSpawn = false
            spec.persistState = false
            local id = Game.GetDynamicEntitySystem():CreateEntity(spec)
            self.spawned_metro_id = id
            print("[InsideMetro][Debug] spawned metro id=" .. tostring(id and id.hash))
        end
        if self.spawned_metro_id ~= nil then
            if ImGui.Button("Despawn metro") then
                Game.GetDynamicEntitySystem():DeleteEntity(self.spawned_metro_id)
                print("[InsideMetro][Debug] despawned metro id=" .. tostring(self.spawned_metro_id.hash))
                self.spawned_metro_id = nil
            end
        end
    end
end

return Debug
