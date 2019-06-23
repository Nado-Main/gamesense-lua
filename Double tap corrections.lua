local reference, key_active = ui.reference("RAGE", "Other", "Double tap")
local ref_fake_duck = ui.reference("RAGE", "Other", "Duck peek assist")

local cache = { }
local ui_get, ui_set = ui.get, ui.set
local entity_get_prop = entity.get_prop

local renderer_indicator = renderer.indicator
local renderer_rectangle = renderer.rectangle

local function invoke_cache_callback(name, condition, should_call, VAR)
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

local valve_checks = function()
    local game_rules = entity.get_game_rules()

    local is_valve_ds = entity_get_prop(game_rules, "m_bIsValveDS") == 0
    local in_freeze_period = entity_get_prop(game_rules, "m_bFreezePeriod") == 0

    return is_valve_ds and in_freeze_period
end

client.set_event_callback("paint", function()
    local should_disable = nil

    local me = entity.get_local_player()
    local weapon = entity.get_player_weapon(me)

    if ui_get(key_active) and weapon ~= nil and valve_checks() then
        local item = bit.band(entity_get_prop(weapon, "m_iItemDefinitionIndex"), 0xFFFF)

        if ui_get(ref_fake_duck) or item == 64 or (item > 42 and item < 49) then should_disable = 1 else
            local m_flNextAttack = entity_get_prop(me, "m_flNextAttack")
            local next_attack = entity_get_prop(weapon, "m_flNextPrimaryAttack")
            local next_secondary_attack = entity_get_prop(weapon, "m_flNextSecondaryAttack")
            local m_flAttackTime = math.max(next_attack + 0.5, next_secondary_attack + 0.5)

            local max_time = 0.69
            local current_time = globals.curtime()

            local m_flNextAttack = m_flNextAttack + 0.5
            local shift_time = m_flAttackTime - current_time

            if m_flAttackTime < m_flNextAttack then
                max_time = 1.52
                shift_time = m_flNextAttack - current_time
            end

            -- Indicator
            local y = renderer_indicator(255, 255, 255, 150, "DT")

            if shift_time > -0.26 and max_time > shift_time then
                shift_time = shift_time < 0 and 0 or shift_time

                renderer_rectangle(10, y + 26, 30, 5, 0, 0, 0, 150)
                renderer_rectangle(11, y + 27, (28 / max_time) * (max_time - shift_time), 3, 133, 197, 12, 255)
            end
        end
    end

    invoke_cache_callback("reference", reference, should_disable ~= nil, false)
end)
