local bit = require "bit"

local active = ui.new_checkbox("LEGIT", "Other", "Auto revolver")
local hotkey = ui.new_hotkey("LEGIT", "Other", "Auto revolver key", true)
local ticks = ui.new_slider("LEGIT", "Other", "Revolver ticks", 1, 14, 12, true)

local menu_listener = function() ui.set_visible(ticks, ui.get(active)) end

client.set_event_callback("setup_command", function(cmd)
    if not ui.get(active) or not ui.get(hotkey) then
        return
    end

    local localplayer = entity.get_local_player()
    local weapon = entity.get_player_weapon(localplayer)

    if bit.band(entity.get_prop(weapon, "m_iItemDefinitionIndex"), 0xFFFF) ~= 64 then
        return
    end

    if cmd.in_attack == 0 and cmd.in_reload == 0 then
        cmd.in_attack = 1

        local m_flFireReady = entity.get_prop(weapon, "m_flPostponeFireReadyTime")
        if m_flFireReady > 0 and m_flFireReady < globals.curtime() then
            cmd.in_attack = 0
            if m_flFireReady + globals.tickinterval() * ui.get(ticks) > globals.curtime() then
                cmd.in_attack2 = 1
            end
        end
    end
end)

menu_listener()
ui.set_callback(active, menu_listener)