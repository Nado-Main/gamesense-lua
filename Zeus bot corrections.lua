local quickstop_ref = ui.reference("RAGE", "Other", "Quick stop")
local hitchance_ref = ui.reference("RAGE", "Aimbot", "Minimum hit chance")

local active = ui.new_checkbox("RAGE", "Other", "Correct zeus bot")
local hitchance = ui.new_slider("RAGE", "Other", "\n zeusbot_hc", 0, 100, 85, true, "%", 1, {  [0] = "Off" })

local cache = { }
local ui_get = ui.get
local ui_set = ui.set
local bit_band = bit.band
local entity_is_alive = entity.is_alive
local entity_get_prop = entity.get_prop
local entity_get_local_player = entity.get_local_player
local entity_get_player_weapon = entity.get_player_weapon

local visible_callback = function(this)
    ui.set_visible(hitchance, ui_get(this))
end

local invoke_cache_process = function(name, condition, should_call, VAR)
    local hotkey_modes = {
        [0] = "always on",
        [1] = "on hotkey",
        [2] = "toggle",
        [3] = "off hotkey"
    }

    local _cond = ui_get(condition)
    local _type = type(_cond)

    local value, mode = ui_get(condition)
    local finder = mode ~= nil and mode or (_type == "boolean" and tostring(_cond) or _cond)
    cache[name] = cache[name] ~= nil and cache[name] or finder

    if should_call then ui_set(condition, mode ~= nil and hotkey_modes[VAR] or VAR) else
        if cache[name] ~= nil then
            local _cache = cache[name]
            
            if _type == "boolean" then
                if _cache == "true" then _cache = true end
                if _cache == "false" then _cache = false end
            end

            ui_set(condition, mode ~= nil and hotkey_modes[_cache] or _cache)
            cache[name] = nil
        end
    end
end

client.set_event_callback("paint", function()
    local me = entity_get_local_player()
    local weapon = entity_get_player_weapon(me)

    local is_active = ui_get(active) and weapon ~= nil
    local is_taser = is_active and bit_band(entity_get_prop(weapon, "m_iItemDefinitionIndex"), 0xFFFF) == 31

    invoke_cache_process("quickstop_ref", quickstop_ref, is_taser, "Off")
    invoke_cache_process("hitchance_ref", hitchance_ref, is_taser, ui_get(hitchance))
end)

visible_callback(active)

ui.set_callback(active, visible_callback)
