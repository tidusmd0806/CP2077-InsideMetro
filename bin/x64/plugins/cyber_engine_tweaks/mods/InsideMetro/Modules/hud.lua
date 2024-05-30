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
    obj.interaction_hub = nil
    obj.selected_choice_index = 0
    return setmetatable(obj, self)
end

function HUD:Initialize()
    self:SetStandHint()
    self:SetSitHint()
    self:SetChoice()
end

function HUD:SetStandHint()

    local hint_table = {{action = "ChoiceApply", source = "itm_stand", holdIndicationType = "FromInputConfig", sortingPriority = 0, enableHoldAnimation = false, localizedLabel = "LocKey#37918"}}
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

    local hint_table = {{action = "ChoiceApply", source = "itm_stand", holdIndicationType = "FromInputConfig", sortingPriority = 0, enableHoldAnimation = false, localizedLabel = "LocKey#522"}}
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

function HUD:SetChoice(variation)

    local tmp_list = {}

    local hub = gameinteractionsvisListChoiceHubData.new()
    hub.title = GetLocalizedText("LocKey#83821")
    hub.activityState = gameinteractionsvisEVisualizerActivityState.Active
    hub.hubPriority = 1
    hub.id = 69420 + math.random(99999)

    if variation == Def.ChoiceVariation.Stand then
        local icon = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.MetroIcon")
        local caption_part = gameinteractionsChoiceCaption.new()
        local choice_type = gameinteractionsChoiceTypeWrapper.new()
        caption_part:AddPartFromRecord(icon)
        choice_type:SetType(gameinteractionsChoiceType.Selected)

        local choice = gameinteractionsvisListChoiceData.new()

        local lockey = GetLocalizedText("LocKey#37918")
        choice.localizedName = lockey
        choice.inputActionName = CName.new("None")
        choice.captionParts = caption_part
        choice.type = choice_type
        table.insert(tmp_list, choice)
    elseif variation == Def.ChoiceVariation.Sit then
        local icon = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.SitIcon")
        local caption_part = gameinteractionsChoiceCaption.new()
        local choice_type = gameinteractionsChoiceTypeWrapper.new()
        caption_part:AddPartFromRecord(icon)
        choice_type:SetType(gameinteractionsChoiceType.Selected)

        local choice = gameinteractionsvisListChoiceData.new()

        local lockey = GetLocalizedText("LocKey#522")
        choice.localizedName = lockey
        choice.inputActionName = CName.new("None")
        choice.captionParts = caption_part
        choice.type = choice_type
        table.insert(tmp_list, choice)
    end

    hub.choices = tmp_list

    self.interaction_hub = hub
end

function HUD:ShowChoice(variation, selected_index)

    self.selected_choice_index = selected_index

    self:SetChoice(variation)

    local ui_interaction_define = GetAllBlackboardDefs().UIInteractions
    local interaction_blackboard = Game.GetBlackboardSystem():Get(ui_interaction_define)

    interaction_blackboard:SetInt(ui_interaction_define.ActiveChoiceHubID, self.interaction_hub.id)
    local data = interaction_blackboard:GetVariant(ui_interaction_define.DialogChoiceHubs)
    self.dialogIsScrollable = true
    self.interaction_ui_base:OnDialogsSelectIndex(selected_index - 1)
    self.interaction_ui_base:OnDialogsData(data)
    self.interaction_ui_base:OnInteractionsChanged()
    self.interaction_ui_base:UpdateListBlackboard()
    self.interaction_ui_base:OnDialogsActivateHub(self.interaction_hub.id)

end

function HUD:HideChoice()

    self.interaction_hub = nil

    local ui_interaction_define = GetAllBlackboardDefs().UIInteractions;
    local interaction_blackboard = Game.GetBlackboardSystem():Get(ui_interaction_define)

    local data = interaction_blackboard:GetVariant(ui_interaction_define.DialogChoiceHubs)
    if self.interaction_ui_base == nil then
        return
    end
    self.interaction_ui_base:OnDialogsData(data)

end

function HUD:ShowDangerWarning()
    local text = GetLocalizedText("LocKey#49558")
    GameHUD.ShowWarning(text, 0.5)
end

return HUD