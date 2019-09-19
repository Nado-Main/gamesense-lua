local script = {
    _debug = false,

    menu = { "AA", "Other" },
    conditions = { "Default", "Running", "Slow motion", "Air", "Manual" },

    yaw_base = { "Local view", "At targets", "Movement direction" },
    jitter_type = { "Off", "Offset", "Center", "Random" },

    crooked_type = { "Twist", "Desync" },
    crooked_stand_type = { "Twist", "Desync", "Anti balance adjust" },

    treshold = false,
}

function script:call(func, name, ...)
    if func == nil then
        return
    end

    local end_name = name[2] == nil and "" or name[2]

    if name[1] ~= nil then
        end_name = end_name ~= "" and (end_name .. " ") or end_name
        end_name = end_name .. "\n " .. name[1]
    end

    return func(self.menu[1], self.menu[2], end_name, ...)
end

local active = script:call(ui.new_checkbox, { "afa_active", "Fake angles" })
local switch_hk = script:call(ui.new_hotkey, { "afa_hotkey", "Fake angles hotkey" }, true)

local manual_aa = script:call(ui.new_checkbox, { "afa_manual", "Manual anti-aims" })
local arrow_dst = script:call(ui.new_slider, { "afa_manual_arrow_distance", nil }, 1, 100, 12, true, "%")
local picker = script:call(ui.new_color_picker, { "afa_manual_color_picker", "Color picker" }, 130, 156, 212, 255)

local manual_left_dir = script:call(ui.new_hotkey, { "afa_manual_left", "Left direction" })
local manual_right_dir = script:call(ui.new_hotkey, { "afa_manual_right", "Right direction" })
local manual_backward_dir = script:call(ui.new_hotkey, { "afa_manual_backward", "Backward direction" })

local manual_state = script:call(ui.new_slider, { "afa_manual_state", nil }, 0, 3, 0)
local condition = script:call(ui.new_combobox, { "afa_condition", nil }, script.conditions)

-- REFERENCE
local base = ui.reference("AA", "Anti-aimbot angles", "Yaw base")
local yaw, yaw_num = ui.reference("AA", "Anti-aimbot angles", "Yaw")
local yaw_jt, yaw_jt_num = ui.reference("AA", "Anti-aimbot angles", "Yaw jitter")
local body, body_num = ui.reference("AA", "Anti-aimbot angles", "Body yaw")
local limit = ui.reference("AA", "Anti-aimbot angles", "Fake yaw limit")
local twist = ui.reference("AA", "Anti-aimbot angles", "Twist")

local lower_body_yaw = ui.reference("AA", "Anti-aimbot angles", "Lower body yaw target")
local fr_bodyyaw = ui.reference("AA", "Anti-aimbot angles", "Freestanding body yaw")
local fr, fr_hk = ui.reference("AA", "Anti-aimbot angles", "Freestanding")
local slowmo, slowmo_key = ui.reference("AA", "Other", "Slow motion")

local flag_limit = ui.reference("AA", "Fake lag", "Limit")
local onshot, onshot_hk = ui.reference("AA", "Other", "On shot anti-aim")
local dt, dt_hk = ui.reference("RAGE", "Other", "Double tap")
local duck_assist = ui.reference("RAGE", "Other", "Duck peek assist")

local menu_data = {
    ["Default"] = {
        base = script:call(ui.new_combobox, { "afa_default_yaw_base", "Yaw base" }, script.yaw_base),

        body_lean = script:call(ui.new_slider, { "afa_default_body_lean", "Body lean" }, 0, 100, 55, true, "%"),
        body_lean_inv = script:call(ui.new_slider, { "afa_default_body_lean_inverse", nil }, 0, 100, 55, true, "%"),

        yaw_jitter = script:call(ui.new_combobox, { "afa_default_yaw_jitter", "Yaw jitter" }, script.jitter_type),
        yaw_jitter_val = script:call(ui.new_slider, { "afa_default_yaw_jitter_value", nil }, -180, 180, 0, true, "°"),

        crooked = script:call(ui.new_multiselect, { "afa_default_crooked", "Crooked" }, script.crooked_stand_type),
        ubl = script:call(ui.new_checkbox, { "afa_default_979_force", "Force balance adjust" }),
        ubl_val = script:call(ui.new_slider, { "afa_default_anti979_value", nil }, 0, 30, 30, true, "°"),
    },

    ["Running"] = {
        base = script:call(ui.new_combobox, { "afa_running_yaw_base", "Yaw base" }, script.yaw_base),
        
        body_lean = script:call(ui.new_slider, { "afa_running_body_lean", "Body lean" }, 0, 100, 55, true, "%"),
        body_lean_inv = script:call(ui.new_slider, { "afa_running_body_lean_inverse", nil }, 0, 100, 55, true, "%"),

        yaw_jitter = script:call(ui.new_combobox, { "afa_running_yaw_jitter", "Yaw jitter" }, script.jitter_type),
        yaw_jitter_val = script:call(ui.new_slider, { "afa_running_yaw_jitter_value", nil }, -180, 180, 0, true, "°"),

        crooked = script:call(ui.new_multiselect, { "afa_running_crooked", "Crooked" }, script.crooked_type),
    },

    ["Slow motion"] = {
        base = script:call(ui.new_combobox, { "afa_slowmo_yaw_base", "Yaw base" }, script.yaw_base),
        
        body_lean = script:call(ui.new_slider, { "afa_slowmo_body_lean", "Body lean" }, 0, 100, 55, true, "%"),
        body_lean_inv = script:call(ui.new_slider, { "afa_slowmo_body_lean_inverse", nil }, 0, 100, 55, true, "%"),

        yaw_jitter = script:call(ui.new_combobox, { "afa_slowmo_yaw_jitter", "Yaw jitter" }, script.jitter_type),
        yaw_jitter_val = script:call(ui.new_slider, { "afa_slowmo_yaw_jitter_value", nil }, -180, 180, 0, true, "°"),

        crooked = script:call(ui.new_multiselect, { "afa_slowmo_crooked", "Crooked" }, script.crooked_type),
    },

    ["Air"] = {
        base = script:call(ui.new_combobox, { "afa_air_yaw_base", "Yaw base" }, script.yaw_base),
        
        body_lean = script:call(ui.new_slider, { "afa_air_body_lean", "Body lean" }, 0, 100, 55, true, "%"),
        body_lean_inv = script:call(ui.new_slider, { "afa_air_body_lean_inverse", nil }, 0, 100, 55, true, "%"),

        yaw_jitter = script:call(ui.new_combobox, { "afa_air_yaw_jitter", "Yaw jitter" }, script.jitter_type),
        yaw_jitter_val = script:call(ui.new_slider, { "afa_air_yaw_jitter_value", nil }, -180, 180, 0, true, "°"),

        crooked = script:call(ui.new_multiselect, { "afa_air_crooked", "Crooked" }, script.crooked_type),
    },

    ["Manual"] = {
        body_lean = script:call(ui.new_slider, { "afa_manual_body_lean", "Body lean" }, 0, 100, 55, true, "%"),
        body_lean_inv = script:call(ui.new_slider, { "afa_manual_body_lean_inverse", nil }, 0, 100, 55, true, "%"),

        yaw_jitter = script:call(ui.new_combobox, { "afa_manual_yaw_jitter", "Yaw jitter" }, script.jitter_type),
        yaw_jitter_val = script:call(ui.new_slider, { "afa_manual_yaw_jitter_value", nil }, -180, 180, 0, true, "°"),

        crooked = script:call(ui.new_multiselect, { "afa_manual_crooked", "Crooked" }, script.crooked_type),
    },
}

local cache = { }
local ui_get, ui_set = ui.get, ui.set
local entity_get_prop = entity.get_prop
local entity_get_local_player = entity.get_local_player

local multi_exec = function(func, list)
    if func == nil then
        return
    end
    
    for ref, val in pairs(list) do
        func(ref, val)
    end
end

local compare = function(tab, val)
    for i = 1, #tab do
        if tab[i] == val then
            return true
        end
    end
    
    return false
end

local cache_process = function(condition, should_call, a, b)
    local name = tostring(condition)
    cache[name] = cache[name] ~= nil and cache[name] or ui_get(condition)

    if should_call then
        if type(a) == "function" then a() else
            ui_set(condition, a)
        end
    else
        if cache[name] ~= nil then
            if b ~= nil and type(b) == "function" then
                b(cache[name])
            else
                ui_set(condition, cache[name])
            end

            cache[name] = nil
        end
    end
end

local get_flags = function(cm)
    local state = "Default"
    local me = entity_get_local_player()

    local flags = entity_get_prop(me, "m_fFlags")
    local x, y, z = entity_get_prop(me, "m_vecVelocity")
    local velocity = math.floor(math.min(10000, math.sqrt(x^2 + y^2) + 0.5))

    if bit.band(flags, 1) ~= 1 or (cm and cm.in_jump == 1) then state = "Air" else
        if velocity > 1 or (cm.sidemove ~= 0 or cm.forwardmove ~= 0) then
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
        velocity = velocity,
        state = state
    }
end

local calculate_body_lean = function(inverted, data)
    local inflean = inverted and ui_get(data[1]) or ui_get(data[2])
    local lean = 59 - (0.59 * inflean)

    return inverted and -lean or lean
end

local bind_system = {
    clr = { b = false, l = false, r = false }
}

bind_system.update = function()
    ui_set(manual_left_dir, "On hotkey")
    ui_set(manual_right_dir, "On hotkey")
    ui_set(manual_backward_dir, "On hotkey")

    local m_state = ui_get(manual_state)

    local left_state = ui_get(manual_left_dir)
    local right_state = ui_get(manual_right_dir)
    local backward_state = ui_get(manual_backward_dir)

    if  left_state == bind_system.clr.l and 
        right_state == bind_system.clr.r and
        backward_state == bind_system.clr.b then
        return
    end

    bind_system.clr.l = left_state
    bind_system.clr.r = right_state
    bind_system.clr.b = backward_state

    if (left_state and m_state == 1) or (right_state and m_state == 2) or (backward_state and m_state == 3) then
        ui_set(manual_state, 0)
        return
    end

    if left_state and m_state ~= 1 then
        ui_set(manual_state, 1)
    end

    if right_state and m_state ~= 2 then
        ui_set(manual_state, 2)
    end

    if backward_state and m_state ~= 3 then
        ui_set(manual_state, 3)
    end
end

local bind_callback = function(list, callback, elem)
    for k in pairs(list) do
        if list[k][elem] ~= nil then
            ui.set_callback(list[k][elem], callback)
        end
    end
end

local menu_callback = function(e, menu_call)
    local visible = not ui_get(active)
    local manual = ui_get(manual_aa)
    local bnum = ui_get(body)

    ui_set(switch_hk, "Toggle")

    local setup_menu = function(list, current_condition, vis)
        for k in pairs(list) do
            local mode = list[k]
            local active = k == current_condition

            for j in pairs(mode) do
                local set_element = true

                if j == "yaw_jitter_val" and ui_get(mode["yaw_jitter"]) == "Off" then 
                    set_element = false
                end

                if k == "Default" then
                    local balance_adjust_exploiting = compare(ui_get(mode["crooked"]), script.crooked_stand_type[3])

                    if  j == "ubl" and balance_adjust_exploiting or 
                        j == "ubl_val" and not balance_adjust_exploiting then
                        set_element = false
                    end
                end

                ui.set_visible(mode[j], active and vis and set_element)
            end
        end
    end

    if e == nil then visible = true end
    if menu_call == nil then
        setup_menu(menu_data, ui_get(condition), not visible)
    end

    multi_exec(ui.set_visible, {
        [manual_aa] = not visible,

        [picker] = not visible,
        [arrow_dst] = not visible and manual,
        [manual_left_dir] = not visible and manual,
        [manual_right_dir] = not visible and manual,
        [manual_backward_dir] = not visible and manual,

        [condition] = not visible,
        [manual_state] = false,
    })

    if script._debug then
        visible = true
    end

    multi_exec(ui.set_visible, {
        [yaw_num] = visible and ui_get(yaw) ~= "Off",

        [yaw_jt] = visible, 
        [yaw_jt_num] = visible and ui_get(yaw_jt) ~= "Off",

        [body] = visible,
        [body_num] = visible and bnum ~= "Off" and bnum ~= "Opposite",

        [fr_bodyyaw] = visible,
        [lower_body_yaw] = visible,
        [limit] = visible, 
        [twist] = visible,
    })
end

client.set_event_callback("shutdown", menu_callback)
client.set_event_callback("predict_command", function()
    cache_process(flag_limit, false)
end)

client.set_event_callback("setup_command", function(e)
    if not ui_get(active) then
        return
    end

    local data = get_flags(e)
    local direction = ui_get(manual_state)

    local current_yaw = ui_get(yaw)
    local end_yaw = compare({ "180", "180 Z" }, current_yaw) and current_yaw or "180"

    local state = (direction ~= 0 and not fr_active) and "Manual" or data.state
    local stack = menu_data[state]

    if stack == nil then
        return
    end

    local inverted = ui_get(switch_hk)
    local body_lean = calculate_body_lean(inverted, {
        stack.body_lean,
        stack.body_lean_inv
    })

    local manual_yaw = {
        [0] = direction ~= 0 and "0" or body_lean,
        
        [1] = -90 + body_lean, [2] = 90 + body_lean,
        [3] = body_lean,
    }

    -- Anti-aimbot modes
    local choked_cmds = e.chokedcommands
    local in_fduck, crooked = 
        ui_get(duck_assist),
        ui_get(stack.crooked)

    local dsn_ot = compare(crooked, script.crooked_type[2]) and not in_fduck

    if not dsn_ot then script.treshold = false else
        if choked_cmds == 0 then
            script.treshold = not script.treshold
        end
    end

    local holding_exp = 
        ui_get(onshot) and ui_get(onshot_hk) or 
        ui_get(dt) and ui_get(dt_hk)

    cache_process(flag_limit, dsn_ot and script.treshold and not holding_exp, 1)

    local stand_still = data.state == "Default"

    local balance_adj = {
        lby = (stack.ubl ~= nil and ui_get(stack.ubl)) and "Opposite" or "Eye yaw",
        limit = 60
    }

    if stand_still and compare(crooked, script.crooked_stand_type[3]) then
        manual_yaw[0] = manual_yaw[0] / 3

        balance_adj = {
            lby = "Opposite",
            limit = 30 - ui_get(stack.ubl_val)
        }
    end

    multi_exec(ui_set, {
        [yaw] = end_yaw,
        [body] = "Static",
        
        [yaw_num] = manual_yaw[direction],
        [body_num] = inverted and -180 or 180,

        [yaw_jt] = ui_get(stack.yaw_jitter),
        [yaw_jt_num] = ui_get(stack.yaw_jitter_val),

        [base] = state == "Manual" and "Local view" or ui_get(stack.base),
        [twist] = compare(crooked, script.crooked_type[1]),

        [lower_body_yaw] = balance_adj.lby,
        [limit] = balance_adj.limit,

        [fr_bodyyaw] = false,
    })
end)

client.set_event_callback("paint", function()
    menu_callback(true, true)

    local me = entity_get_local_player()
    
    if not ui_get(active) or not ui_get(manual_aa) or not entity.is_alive(me) then
        return
    end

    bind_system:update()
    local w, h = client.screen_size()
    local r, g, b, a = ui_get(picker)

    local m_state = ui_get(manual_state)
    local fr_active = #ui_get(fr) ~= 0 and ui_get(fr_hk)
    local onshot_active = ui_get(onshot) and ui_get(onshot_hk)

    local realtime = globals.realtime() % 3
    local distance = (w/2) / 210 * ui_get(arrow_dst)
    local alpha = not onshot_active and math.floor(math.sin(realtime * 4) * (a/2-1) + a/2) or a

    if m_state == 1 or fr_active then renderer.text(w/2 - distance, h / 2 - 1, r, g, b, alpha, "+c", 0, "◄") end
    if m_state == 2 or fr_active then renderer.text(w/2 + distance, h / 2 - 1, r, g, b, alpha, "+c", 0, "►") end

    if m_state == 3 and not fr_active then renderer.text(w/2, h / 2 + distance, r, g, b, alpha, "+c", 0, "▼") end
end)

menu_callback(active)
bind_callback(menu_data, menu_callback, "yaw_jitter")
bind_callback(menu_data, menu_callback, "crooked")

ui.set_callback(active, menu_callback)
ui.set_callback(manual_aa, menu_callback)
ui.set_callback(condition, menu_callback)
