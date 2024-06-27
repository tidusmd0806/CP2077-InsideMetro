local HUD = {}
HUD.__index = HUD

function HUD:New(metro_obj)
    -- instance --
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "HUD")
    obj.metro_obj = metro_obj
    -- static --
    obj.max_stand_choice_num = 1
    obj.max_sit_choice_num = 1
    -- obj.enable_stand_choice_contents = {{caption = "ChoiceCaptionParts.GetUpIcon", lockey = "LocKey#37918"}, {caption = "ChoiceCaptionParts.MetroIcon", lockey = "LocKey#36196"}}
    obj.enable_stand_choice_contents = {{caption = "ChoiceCaptionParts.GetUpIcon", lockey = "LocKey#37918"}}
    obj.enable_sit_choice_contents = {{caption = "ChoiceCaptionParts.SitIcon", lockey = "LocKey#522"}}
    -- dynamic --
    obj.show_stand_hint_event = nil
    obj.hide_stand_hint_event = nil
    obj.show_sit_hint_event = nil
    obj.hide_sit_hint_event = nil
    obj.interaction_hub = nil
    obj.selected_choice_index = Def.ChoiceText.Stand
    return setmetatable(obj, self)
end

function HUD:Initialize()
    self:SetChoice()
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

    local choice_contents = {}
    if variation == Def.ChoiceVariation.Stand then
        choice_contents = self.enable_stand_choice_contents
    elseif variation == Def.ChoiceVariation.Sit then
        choice_contents = self.enable_sit_choice_contents
    end

    for _, v in ipairs(choice_contents) do
        local icon = TweakDBInterface.GetChoiceCaptionIconPartRecord(v.caption)
        local caption_part = gameinteractionsChoiceCaption.new()
        local choice_type = gameinteractionsChoiceTypeWrapper.new()
        caption_part:AddPartFromRecord(icon)
        choice_type:SetType(gameinteractionsChoiceType.Selected)

        local choice = gameinteractionsvisListChoiceData.new()

        local lockey = GetLocalizedText(v.lockey)
        choice.localizedName = lockey
        choice.inputActionName = CName.new("None")
        choice.captionParts = caption_part
        choice.type = choice_type
        table.insert(tmp_list, choice)
    end

    hub.choices = tmp_list

    self.interaction_hub = hub
end

function HUD:ShowChoice(variation)

    if variation == Def.ChoiceVariation.Stand then
        if self.selected_choice_index >= self.max_stand_choice_num then
            self.selected_choice_index = 0
        end
    elseif variation == Def.ChoiceVariation.Sit then
        if self.selected_choice_index >= self.max_sit_choice_num then
            self.selected_choice_index = 0
        end
    end
    self:SetChoice(variation)

    local ui_interaction_define = GetAllBlackboardDefs().UIInteractions
    local interaction_blackboard = Game.GetBlackboardSystem():Get(ui_interaction_define)

    interaction_blackboard:SetInt(ui_interaction_define.ActiveChoiceHubID, self.interaction_hub.id)
    local data = interaction_blackboard:GetVariant(ui_interaction_define.DialogChoiceHubs)
    self.dialogIsScrollable = true
    self.interaction_ui_base:OnDialogsSelectIndex(self.selected_choice_index)
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