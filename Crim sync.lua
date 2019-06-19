local yaw, yaw_num = ui.reference("AA", "Anti-aimbot angles", "Yaw")
local yaw_jitter, yaw_jitter_num = ui.reference("AA", "Anti-aimbot angles", "Yaw jitter")
local body, body_num = ui.reference("AA", "Anti-aimbot angles", "Body yaw")
local limit = ui.reference("AA", "Anti-aimbot angles", "Fake yaw limit")
-- local twist = ui.reference("AA", "Anti-aimbot angles", "Twist")

local flag_limit = ui.reference("AA", "Fake lag", "Limit")
local flag_onshot = ui.reference("AA", "Fake lag", "Fake lag while shooting")
local fr, fr_key = ui.reference("AA", "Anti-aimbot angles", "Freestanding")

local air_duck = ui.reference("MISC", "Miscellaneous", "Air duck")
local fr_bodyyaw = ui.reference("AA", "Anti-aimbot angles", "Freestanding body yaw")
local slowmo, slowmo_key = ui.reference("AA", "Other", "Slow motion")
local duck_peek_assist = ui.reference("RAGE", "Other", "Duck peek assist")
local onshot, onshot_hk = ui.reference("AA", "Other", "On shot anti-aim")

local ui_get, ui_set = ui.get, ui.set
local aa_type = { "Static", "Jitter" }
local jitter_type = { "Offset", "Center", "Random" }
local list = { "Default", "Running", "Slow motion", "Air" }

local set_element = function(name, var)
    local end_name = name == nil and "" or name

    if var ~= nil then
        end_name = end_name ~= "" and (end_name .. " ") or end_name
        end_name = end_name .. "\n " .. var
    end

    return end_name
end

local active = ui.new_checkbox("AA", "Other", set_element("Fake angles", "crimsync_active"))
local inverse_key = ui.new_hotkey("AA", "Other", set_element("Fake angles inverse", "crimsync_inverse_key"), true)
local condition = ui.new_combobox("AA", "Other", set_element("Condition", "crimsync_condition"), list)

local modes = {
    ["Default"] = {
        aa_mode = ui.new_multiselect("AA", "Other", set_element("Anti-aimbot mode", "aa_mode_default"), aa_type),
        body_lean = ui.new_slider("AA", "Other", set_element("Body lean", "bodylean_default"), 0, 100, 55, true, "%"),
        body_lean_inv = ui.new_slider("AA", "Other", set_element(nil, "bodylean_inv_default"), 0, 100, 55, true, "%"),
        jitter_type = ui.new_combobox("AA", "Other", set_element("Jitter mode", "jitter_type_default"), jitter_type),
        jitter_grad = ui.new_slider("AA", "Other", set_element(nil, "jitter_default"), 0, 180, 5, true, "°"),
        static_body = ui.new_checkbox("AA", "Other", set_element("Static body yaw", "default_static_bodyyaw")),
        shift_onshot = ui.new_checkbox("AA", "Other", set_element("Shift onshot", "shift_onshot_default")),
        -- desync = ui.new_checkbox("AA", "Other", set_element("Desync", "desync_default")),
    }, 
    
    ["Running"] = {
        aa_mode = ui.new_multiselect("AA", "Other", set_element("Anti-aimbot mode", "aa_mode_running"), aa_type),
        body_lean = ui.new_slider("AA", "Other", set_element("Body lean", "bodylean_running"), 0, 100, 55, true, "%"),
        body_lean_inv = ui.new_slider("AA", "Other", set_element(nil, "bodylean_inv_running"), 0, 100, 55, true, "%"),
        jitter_type = ui.new_combobox("AA", "Other", set_element("Jitter mode", "jitter_type_running"), jitter_type),
        jitter_grad = ui.new_slider("AA", "Other", set_element(nil, "jitter_running"), 0, 180, 5, true, "°"),
        shift_onshot = ui.new_checkbox("AA", "Other", set_element("Shift onshot", "shift_onshot_running")),
        -- desync = ui.new_checkbox("AA", "Other", set_element("Desync", "desync_running"))
    }, 
    
    ["Slow motion"] = {
        aa_mode = ui.new_multiselect("AA", "Other", set_element("Anti-aimbot mode", "aa_mode_slowmo"), aa_type),
        body_lean = ui.new_slider("AA", "Other", set_element("Body lean", "bodylean_slowmo"), 0, 100, 55, true, "%"),
        body_lean_inv = ui.new_slider("AA", "Other", set_element(nil, "bodylean_inv_slowmo"), 0, 100, 55, true, "%"),
        jitter_type = ui.new_combobox("AA", "Other", set_element("Jitter mode", "jitter_type_slowmo"), jitter_type),
        jitter_grad = ui.new_slider("AA", "Other", set_element(nil, "jitter_slowmo"), 0, 180, 5, true, "°"),
        shift_onshot = ui.new_checkbox("AA", "Other", set_element("Shift onshot", "shift_onshot_slowmo")),
        -- desync = ui.new_checkbox("AA", "Other", set_element("Desync", "desync_slowmo"))
    },

    ["Air"] = {
        aa_mode = ui.new_multiselect("AA", "Other", set_element("Anti-aimbot mode", "aa_mode_air"), aa_type),
        body_lean = ui.new_slider("AA", "Other", set_element("Body lean", "bodylean_air"), 0, 100, 55, true, "%"),
        body_lean_inv = ui.new_slider("AA", "Other", set_element(nil, "bodylean_inv_air"), 0, 100, 55, true, "%"),
        jitter_type = ui.new_combobox("AA", "Other", set_element("Jitter mode", "jitter_type_air"), jitter_type),
        jitter_grad = ui.new_slider("AA", "Other", set_element(nil, "jitter_air"), 0, 180, 5, true, "°"),
        shift_air_anims = ui.new_checkbox("AA", "Other", set_element("Shift air animations", "shift_air_anims")),
        -- desync = ui.new_checkbox("AA", "Other", set_element("Desync", "desync_air"))
    }
}

local function get_condition(list, id)
    for k in pairs(list) do
        if k == id then
            return list[k]
        end
    end

    return nil
end

local function ui_mset(list)
    for ref, val in pairs(list) do
        ui_set(ref, val)
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

local function _callback()
    local itself = ui_get(active)
    local cond = ui_get(condition)

    local setup_menu = function(list, id, visible)
        for k in pairs(list) do
            local mode = list[k]
            local active = k == id

            for j in pairs(mode) do
                local _act = true

                local jitter_list = { "jitter_grad", "jitter_type" }
                local jitter_active = compare(ui_get(mode.aa_mode), aa_type[2])

                if compare(jitter_list, j) and not jitter_active then
                    _act = false
                end

                ui.set_visible(mode[j], active and visible and _act)
            end
        end
    end

    ui.set_visible(condition, itself)

    setup_menu(modes, cond, itself)
end

local function get_flags(cm)
    local state = "Default"
    local get_prop = function(...)
        return entity.get_prop(entity.get_local_player(), ...)
    end

    local flags = get_prop("m_fFlags")
    local x, y, z = get_prop("m_vecVelocity")
    local velocity = math.floor(math.min(10000, math.sqrt(x^2 + y^2) + 0.5))

    if bit.band(flags, 1) ~= 1 or (cm and cm.in_jump == 1) then state = "Air" else
        if velocity > 1 or (cm ~= nil and (cm.sidemove ~= 0 or cm.forwardmove ~= 0)) then
            if ui_get(slowmo) and ui_get(slowmo_key) then 
                state = "Slow motion"
            else
                state = "Running"
            end
        else
            state = "Default"
        end
    end

    return {
        -- max_desync = (59 - 58 * velocity / 580),
        velocity = velocity,
        state = state
    }
end

local cache = { }
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

local can_shift = function()
    local me = entity.get_local_player()
    local weapon = entity.get_prop(me, "m_hActiveWeapon")
    local item = bit.band(entity.get_prop(weapon, "m_iItemDefinitionIndex"), 0xFFFF)

    if ui_get(duck_peek_assist) or item == 64 or (item > 42 and item < 49) then
        return false
    end

    return true
end

client.set_event_callback("setup_command", function(cmd)
    local cmd_active, inversed = 
        ui_get(active),
        ui_get(inverse_key)
        ui_set(inverse_key, "Toggle")

    local data = get_flags(cmd)
    local current_condition = get_condition(modes, data.state)
    local lean = 59 - (0.59 * ui_get(inversed and current_condition.body_lean or current_condition.body_lean_inv))

    local should_shift = data.state ~= "Air" and ui_get(current_condition.shift_onshot) and can_shift()
    local should_shift_air = data.state == "Air" and ui_get(current_condition.shift_air_anims)

    local inversed = inversed or compare(ui_get(fr), "Default") and ui_get(fr_key)
    local antiaim_mode, _yaw = ui_get(current_condition.aa_mode), ui_get(yaw)

    cache_process("onshot", onshot, cmd_active and should_shift, true)
    cache_process("onshot_hk", onshot_hk, cmd_active and should_shift, "Always on")
    cache_process("air_duck", air_duck, cmd_active and should_shift_air, "Spam")
    cache_process("fr_bodyyaw", fr_bodyyaw, cmd_active and ui_get(fr_key), false)

    if not cmd_active then 
        return
    end

    local jitter_data = {
        mode = compare(antiaim_mode, aa_type[2]),
        type = ui_get(current_condition.jitter_type),
        grad = ui_get(current_condition.jitter_grad)
    }

    ui_mset({
        [yaw] = compare({ "180", "180 Z" }, _yaw) and _yaw or '180',
        [body] = (compare(antiaim_mode, aa_type[1]) or ui_get(fr_key)) and 'Static' or 'Opposite',
    
        -- Body lean
        [yaw_num] = inversed and -lean or lean,
        [body_num] = inversed and -179 or 179,
        [yaw_jitter] = jitter_data.mode and jitter_data.type or 'Off',
        [yaw_jitter_num] = inversed and -jitter_data.grad or jitter_data.grad,
    })

    if data.state == "Default" and ui_get(current_condition.static_body) then
        local speed_th = cmd.in_duck ~= 0 and 2.941177 or 1.000001
        local sm = cmd.command_number % 4 < 2 and -speed_th or speed_th

        cmd.sidemove = cmd.sidemove ~= 0 and cmd.sidemove or sm
    end
end)

_callback(active)
ui.set_callback(active, _callback)
ui.set_callback(condition, _callback)
ui.set_callback(modes["Default"].aa_mode, _callback)
ui.set_callback(modes["Running"].aa_mode, _callback)
ui.set_callback(modes["Air"].aa_mode, _callback)
ui.set_callback(modes["Slow motion"].aa_mode, _callback)
