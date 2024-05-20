local HUD = {}
HUD.__index = HUD

function HUD:New(metro_obj)
    -- instance --
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "HUD")
    obj.metro_obj = metro_obj
    -- dynamic --
    obj.show_stand_hint_event = nil
    obj.hide_stand_hint_event = nil
    obj.show_sit_hint_event = nil
    obj.hide_sit_hint_event = nil
    return setmetatable(obj, self)
end

function HUD:Initialize()
    self:SetStandHint()
    self:SetSitHint()
end

function HUD:SetStandHint()

    local hint_table = {{action = "CallVehicle", source = "itm_stand", holdIndicationType = "FromInputConfig", sortingPriority = 0, enableHoldAnimation = false, localizedLabel = "LocKey#37918"}}
    self.show_stand_hint_event = UpdateInputHintMultipleEvent.new()
    self.hide_stand_hint_event = UpdateInputHintMultipleEvent.new()
    self.show_stand_hint_event.targetHintContainer = CName.new("GameplayInputHelper")
    self.hide_stand_hint_event.targetHintContainer = CName.new("GameplayInputHelper")
    for _, hint in ipairs(hint_table) do
        local input_hint_data = InputHintData.new()
        input_hint_data.source = CName.new(hint.source)
        input_hint_data.action = CName.new(hint.action)
        if hint.holdIndicationType == "FromInputConfig" then
            input_hint_data.holdIndicationType = inkInputHintHoldIndicationType.FromInputConfig
        elseif hint.holdIndicationType == "Hold" then
            input_hint_data.holdIndicationType = inkInputHintHoldIndicationType.Hold
        elseif hint.holdIndicationType == "Press" then
            input_hint_data.holdIndicationType = inkInputHintHoldIndicationType.Press
        else
            input_hint_data.holdIndicationType = inkInputHintHoldIndicationType.FromInputConfig
        end
        input_hint_data.sortingPriority = hint.sortingPriority
        input_hint_data.enableHoldAnimation = hint.enableHoldAnimation
        local keys = string.gmatch(hint.localizedLabel, "LocKey#(%d+)")
        local localizedLabels = {}
        for key in keys do
            table.insert(localizedLabels, GetLocalizedText("LocKey#" .. key))
        end
        input_hint_data.localizedLabel = table.concat(localizedLabels, "-")
        self.show_stand_hint_event:AddInputHint(input_hint_data, true)
        self.hide_stand_hint_event:AddInputHint(input_hint_data, false)
    end

end

function HUD:SetSitHint()

    local hint_table = {{action = "CallVehicle", source = "itm_stand", holdIndicationType = "FromInputConfig", sortingPriority = 0, enableHoldAnimation = false, localizedLabel = "LocKey#37918"}}
    self.show_sit_hint_event = UpdateInputHintMultipleEvent.new()
    self.hide_sit_hint_event = UpdateInputHintMultipleEvent.new()
    self.show_sit_hint_event.targetHintContainer = CName.new("GameplayInputHelper")
    self.hide_sit_hint_event.targetHintContainer = CName.new("GameplayInputHelper")
    for _, hint in ipairs(hint_table) do
        local input_hint_data = InputHintData.new()
        input_hint_data.source = CName.new(hint.source)
        input_hint_data.action = CName.new(hint.action)
        if hint.holdIndicationType == "FromInputConfig" then
            input_hint_data.holdIndicationType = inkInputHintHoldIndicationType.FromInputConfig
        elseif hint.holdIndicationType == "Hold" then
            input_hint_data.holdIndicationType = inkInputHintHoldIndicationType.Hold
        elseif hint.holdIndicationType == "Press" then
            input_hint_data.holdIndicationType = inkInputHintHoldIndicationType.Press
        else
            input_hint_data.holdIndicationType = inkInputHintHoldIndicationType.FromInputConfig
        end
        input_hint_data.sortingPriority = hint.sortingPriority
        input_hint_data.enableHoldAnimation = hint.enableHoldAnimation
        local keys = string.gmatch(hint.localizedLabel, "LocKey#(%d+)")
        local localizedLabels = {}
        for key in keys do
            table.insert(localizedLabels, GetLocalizedText("LocKey#" .. key))
        end
        input_hint_data.localizedLabel = table.concat(localizedLabels, "-")
        self.show_sit_hint_event:AddInputHint(input_hint_data, true)
        self.hide_sit_hint_event:AddInputHint(input_hint_data, false)
    end

end

function HUD:ShowStandHint()
    Game.GetUISystem():QueueEvent(self.show_stand_hint_event)
end

function HUD:HideStandHint()
    Game.GetUISystem():QueueEvent(self.hide_stand_hint_event)
end

function HUD:ShowSitHint()
    Game.GetUISystem():QueueEvent(self.show_sit_hint_event)
end

function HUD:HideSitHint()
    Game.GetUISystem():QueueEvent(self.hide_sit_hint_event)
end

return HUD