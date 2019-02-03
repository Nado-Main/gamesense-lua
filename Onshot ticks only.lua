local csd = { [1] = "1 tick" }
for i = 2, 5 do csd[i] = i .. " ticks" end

local lagcomp = {}
local get_prop = entity.get_prop
local ui_get, ui_set = ui.get, ui.set

local dbg = { "Console log", "Target flag" }
local min_dmg = nil

local is_active = ui.new_checkbox("RAGE", "Other", "Onshot ticks only")
local hotkey = ui.new_hotkey("RAGE", "Other", "Onshot ticks key", true)
local override_dmg = ui.new_checkbox("RAGE", "Other", "Override minimum damage")
local disable_lagcomp = ui.new_checkbox("RAGE", "Other", "Disable lag compensation")
local debug_info = ui.new_multiselect("RAGE", "Other", "Debug information", dbg)
local shot_ticks = ui.new_slider("RAGE", "Other", "Client side delay", 1, 5, 2, true, nil, 0, csd)

-- REFERENCES
local _, aim_active = ui.reference("RAGE", "Aimbot", "Enabled")
local shared_esp = ui.reference("Visuals", "Other ESP", "Shared ESP")
local restrict_shared = ui.reference("Visuals", "Other ESP", "Restrict shared ESP updates")
local minimum_damage = ui.reference("RAGE", "Aimbot", "Minimum damage")

local playerlist = ui.reference("PLAYERS", "Players", "Player list")
local apply = ui.reference("PLAYERS", "Adjustments", "Apply to all")
local resetall = ui.reference("PLAYERS", "Players", "Reset all")
local whitelist = ui.reference("PLAYERS", "Adjustments", "Add to whitelist")
local highpriority = ui.reference("PLAYERS", "Adjustments", "High priority")
local accuracyboost = ui.reference("PLAYERS", "Adjustments", "Override accuracy boost")

-- FUNCTIONS
local round = function(num, dec) return tonumber(string.format("%." .. (dec or 0) .. "f", num)) end

local menu_listener = function()
    local active = ui_get(is_active)
    ui.set_visible(override_dmg, active)
    ui.set_visible(disable_lagcomp, active)
    ui.set_visible(debug_info, active)
    ui.set_visible(shot_ticks, active)
end

function contains(tab, val)
    for index, value in ipairs(ui_get(tab)) do
        if value == val then return true end
    end

    return false
end

local notify, notify_active = nil, true
if notify_active then
    notify = require "notify"
end

-- CALLBACKS
client.set_event_callback("weapon_fire", function(c)
    local i = client.userid_to_entindex(c.userid)
    if not ui_get(is_active) or not entity.is_enemy(i) then 
        return
    end

    local pitch, yaw = get_prop(i, "m_angEyeAngles")    
    if lagcomp[i] ~= nil then
        for j = 5, 2, -1 do
            lagcomp[i][j] = lagcomp[i][j-1]
        end
    else
        lagcomp[i] = {
            [1] = { ["tickcount"] = globals.tickcount() }
        }
    end

    lagcomp[i][1] = {
        ["tickcount"] = globals.tickcount() + ui_get(shot_ticks),
        ["angles"] = {
            ["x"] = pitch,
            ["y"] = yaw
        }
    }

    if contains(debug_info, dbg[1]) and not entity.is_dormant(i) then
        if notify_active then
            notify.setup_color({ 25, 118, 210 })
            notify.add(5, true, 
            { 255, 255, 255, "Added onshot record (", }, 
            { 150, 185, 1, entity.get_player_name(i) }, 
            { 255, 255, 255, ", Pitch: " }, 
            { 150, 185, 1, round(pitch, 1) .. "°" }, 
            { 255, 255, 255, ")" })
        else
            client.color_log(139, 195, 74, "[onshot] ".. entity.get_player_name(i) .. ": Added record (Pitch: " .. round(pitch, 1) .. "°)")
        end
    end
end)

client.set_event_callback("paint", function(c)
    if notify_active then notify:listener() end
    if not ui_get(is_active) then
        return
    end

    local is_pressed = ui_get(hotkey)

    min_dmg = min_dmg ~= nil and min_dmg or ui_get(minimum_damage)
    if is_pressed and ui_get(override_dmg) then ui_set(minimum_damage, 101) else
        if min_dmg ~= nil then
            ui_set(minimum_damage, min_dmg)
            min_dmg = nil
        end
    end

    local players = entity.get_players(true)

    ui_set(shared_esp, true)
    ui_set(restrict_shared, is_pressed)

    if ui_get(playerlist) == nil then
        return
    end

    for i = 1, #players do
        local m = players[i]
        local can_shoot, time = not is_pressed, nil

        if lagcomp[m] ~= nil and lagcomp[m][1] ~= nil then
            if is_pressed and lagcomp[m][1].tickcount > globals.tickcount() then
                can_shoot = true
            end
        else
            lagcomp[m] = {
                [1] = { ["tickcount"] = globals.tickcount() }
            }
        end

        ui_set(playerlist, players[i])
        ui_set(whitelist, not can_shoot)
        ui_set(accuracyboost, (is_pressed and ui_get(disable_lagcomp)) and "Disable" or "-")

        -- Target esp
        if is_pressed and contains(debug_info, dbg[2]) then
            local name = entity.get_player_name(m)
            local y_additional = name == "" and -8 or 0
            local x1, y1, x2, y2, a_multiplier = entity.get_bounding_box(c, m)

            if x1 ~= nil and a_multiplier > 0 then
                local x_center = x1 + (x2-x1)/2
                if x_center ~= nil then
                    local dormant_state = a_multiplier * 255

                    local r, g, b = 235, 63, 6
                    if ui_get(whitelist) then
                        r, g, b = 139, 195, 74
                    end

                    renderer.text(x_center, y1 - 25 + y_additional, r, g, b, dormant_state, "c-", 0, "ONSHOT (" .. (can_shoot and "YES" or "NO") .. ")")
                end
            end
        end
    end
end)


menu_listener()
ui.set_callback(is_active, menu_listener)