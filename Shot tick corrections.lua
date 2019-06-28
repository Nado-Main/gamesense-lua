--[[
    Selections:
    * On shot: It will attempt to send firing tick as soon as possible
    * Always on: It will hide firing animation as soon as possible + apply "on shot" selection

    - https://streamable.com/fu0h3 -- Explanation why this script is has to be used
    - This lua makes your bullets register faster, like onetap or aimware
    - Note: w/o this lua your shots will be delayed (even w/o fakelag while shooting / fakelag)
    - It won't even register when getting peeked (if your hp is lower than minimum damage of enemies weapon)
]]

local fl_onshot = ui.reference("AA", "Fake lag", "Fake lag while shooting")
local duck_assist = ui.reference("RAGE", "Other", "Duck peek assist")
local limit_ref = ui.reference("AA", "Fake lag", "Limit")

local mh = { "-", "On shot", "Always on" }
local method = ui.new_combobox("AA", "Other", "Shot tick corrections", mh)

local cache = { }
local data = {
    threshold = false,
    stored_last_shot = 0,
    stored_item = 0
}

local ui_get, ui_set = ui.get, ui.set
local entity_get_local_player = entity.get_local_player
local entity_get_player_weapon = entity.get_player_weapon
local entity_get_prop = entity.get_prop
local math_sqrt = math.sqrt
local bit_band = bit.band

local set_cache = function(self)
    local process = function(name, condition, should_call, VAR)
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

    process("limit_ref", limit_ref, (self == nil and false or self), 1)
end

client.set_event_callback("shutdown", set_cache)
client.set_event_callback("setup_command", function(cmd)
    local me = entity_get_local_player()
    local weapon = entity_get_player_weapon(me)

    local last_shot_time = entity_get_prop(weapon, "m_fLastShotTime")
    local m_iItem = bit_band(entity_get_prop(weapon, "m_iItemDefinitionIndex"), 0xFFFF)

    local limitation = function(cmd)
        local params = ui_get(method)
        if ui_get(duck_assist) or ui_get(fl_onshot) or params == mh[1] then
            return false
        end

        local in_accel = function()
            local me = entity_get_local_player()
            local x, y = entity_get_prop(me, "m_vecVelocity")
        
            return math_sqrt(x^2 + y^2) ~= 0
        end

        local max_commands = in_accel() and 1 or 2
        local onshot_mode = params == mh[2]

        if not data.threshold and last_shot_time ~= data.stored_last_shot then
            data.stored_last_shot = last_shot_time

            if not onshot_mode then
                data.threshold = true
            end

            return true
        end

        if not onshot_mode and data.threshold and cmd.chokedcommands >= max_commands then
            data.threshold = false
            return true
        end

        return false
    end
    
    if data.stored_item ~= m_iItem then
        data.stored_last_shot = last_shot_time
        data.stored_item = m_iItem
    end

    set_cache(limitation(cmd))
end)
