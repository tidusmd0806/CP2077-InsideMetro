local Config = {}
Config.__index = Config

-- single config source; edit values here and reload CET scripts
function Config:New()
    local obj = {}
    -- stand up via StopInDevice + Unmount
    obj.standup_stop_in_device = 1
    obj.standup_stop_gap = 0.5
    obj.standup_freeze = 1
    obj.standup_eyes = 1
    obj.standup_hold_pos = 1
    obj.standup_camera_reset = 1
    -- sit down via pose-change fact
    obj.sit_fact_name = "ue_metro_signal_pose_change"
    obj.sit_fact_delay = 0.05
    obj.sit_fact_freeze = 0
    -- seconds outside the metro domain before walk reset fires
    obj.walk_reset_grace = 2.0
    return setmetatable(obj, self)
end

return Config

