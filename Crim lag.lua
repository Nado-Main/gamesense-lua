local list = { "Default", "Hit ground" }

local alpha = 0
local enabled = ui.new_checkbox("AA", "Fake lag", "Lag comp shifter")
local condition = ui.new_multiselect("AA", "Fake lag", "\n lagcomp_shifter_condition", list)

local amount = ui.reference("AA", "Fake lag", "Amount")
local variance = ui.reference("AA", "Fake lag", "Variance")
local custom_triggers = ui.reference("AA", "Fake lag", "Customize triggers")
local onshot_fakelag = ui.reference("AA", "Fake lag", "Fake lag while shooting")

local phases = {
    { amount = "Maximum", variance = 0 },
    { amount = "Dynamic", variance = 0 },
    { amount = "Maximum", variance = 36 },
    { amount = "Dynamic", variance = 0 },
    { amount = "Maximum", variance = 68 },
    { amount = "Dynamic", variance = 0 },
    { amount = "Fluctuate", variance = 0 },
    -- { amount = "Fluctuate", variance = 100 },
}

local data = {
    current_phase = 0,
    prev_choked = 14,
}

local cache = { }
local ui_get, ui_set = ui.get, ui.set
local entity_is_alive = entity.is_alive
local renderer_measure_text = renderer.measure_text
local renderer_indicator = renderer.indicator
local renderer_rectangle = renderer.rectangle

local bit_band = bit.band
local math_sqrt = math.sqrt
local entity_get_prop = entity.get_prop
local entity_get_local_player = entity.get_local_player

local cache_process = function(name, condition, should_call, VAR)
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

local function compare(tab, val)
    for i = 1, #tab do
        if tab[i] == val then
            return true
        end
    end
    
    return false
end

client.set_event_callback("setup_command", function(c)
    local get_prop = function(...) 
        return entity_get_prop(entity_get_local_player(), ...)
    end

    local conditions = ui_get(condition)

    local x, y, z = get_prop("m_vecVelocity")
    local in_air = c.in_jump == 1 or bit_band(get_prop("m_fFlags"), 1) ~= 1

    local is_active = ui_get(enabled) and (
        (compare(conditions, list[1]) and not in_air and math.sqrt(x^2 + y^2) > 0) or 
        (compare(conditions, list[2]) and in_air)
    )

    if is_active then
        if alpha < 248 then
            alpha = alpha + 8
        end
    else
        if alpha > 7 then
            alpha = alpha - 8
        end
    end

    if c.chokedcommands < data.prev_choked then
        data.current_phase = data.current_phase + 1

        if data.current_phase > #phases then
            data.current_phase = 1
        end
    end

    -- cache_process("onshot_fakelag", onshot_fakelag, is_active, true)
    cache_process("custom_triggers", custom_triggers, is_active, false)
    cache_process("amount", amount, is_active, phases[data.current_phase].amount)
    cache_process("variance", variance, is_active, phases[data.current_phase].variance)

    data.prev_choked = c.chokedcommands
end)

client.set_event_callback("paint", function(c)
    local me = entity_get_local_player()

    if not ui_get(enabled) or not entity_is_alive(me) then
        return
    end

    if alpha > 0 then
        local text = "CL"
        local width, height = renderer_measure_text("+", text)
        local y = renderer_indicator(255, 255, 255, alpha > 150 and 150 or alpha, text)

        renderer_rectangle(10, y + 26, width, 5, 0, 0, 0, alpha > 150 and 150 or alpha)
        renderer_rectangle(11, y + 27, ((width - 2) / #phases) * data.current_phase, 3, 133, 197, 12, alpha)
    end
end)

local _callback = function(self)
    ui.set_visible(condition, ui_get(self))
end

ui.set_callback(enabled, _callback)
_callback(enabled)
