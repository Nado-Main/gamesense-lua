local list = {
    { "ID", 20 },
    { "Player", 30 },
    { "Hitbox", 25 },
    { "Damage", 10 },
    { "Flags", 15 },
    { "Reason", 30 },
    { "Lag Comp", 25 },
}

local max_alpha = 0
local player_data, bullet_info = { }, { }
local ui_get, ui_set = ui.get, ui.set

local rebase_table = function(tab)
    local end_table = { }

    for i = 1, #tab do
        end_table[#end_table+1] = tab[i][1]
    end

    return end_table
end

local find_value = function(tab, value)
    for i = 1, #tab do
        if tab[i][1] == value then
            return tab[i]
        end
    end
end

local set_alpha = function(alpha, max)
    return (alpha > max and max or alpha)
end

local client_eye_position = client.eye_position
local math_deg, math_atan2, math_sqrt = math.deg, math.atan2, math.sqrt
local math_pow = math.pow
local math_floor = math.floor
local math_ceil = math.ceil
local math_abs = math.abs
local globals_tickcount = globals.tickcount
local globals_tickinterval = globals.tickinterval
local globals_frametime = globals.frametime
local table_concat = table.concat
local math_sin = math.sin
local globals_realtime = globals.realtime
local renderer_gradient = renderer.gradient
local string_upper = string.upper
local renderer_measure_text = renderer.measure_text
local renderer_rectangle = renderer.rectangle
local renderer_text = renderer.text
local ui_mouse_position = ui.mouse_position
local ui_is_menu_open = ui.is_menu_open

local vector_angles = function(x1, y1, z1, x2, y2, z2)
    local origin_x, origin_y, origin_z
    local target_x, target_y, target_z
    if x2 == nil then
        target_x, target_y, target_z = x1, y1, z1
        origin_x, origin_y, origin_z = client_eye_position()

        if origin_x == nil then
            return
        end
    else
        origin_x, origin_y, origin_z = x1, y1, z1
        target_x, target_y, target_z = x2, y2, z2
    end

    local delta_x, delta_y, delta_z = target_x-origin_x, target_y-origin_y, target_z-origin_z

    if delta_x == 0 and delta_y == 0 then return (delta_z > 0 and 270 or 90), 0 else
        local yaw = math_deg(math_atan2(delta_y, delta_x))
        local hyp = math_sqrt(delta_x*delta_x + delta_y*delta_y)
        local pitch = math_deg(math_atan2(-delta_z, hyp))

        return pitch, yaw
    end
end

local vector_distance = function(a, b)
    return math_sqrt(math_pow(a[1] - b[1], 2) + math_pow(a[2] - b[2], 2)) --[[ + math_pow(a[3] - b[3], 2) ]]
end

local round = function(x, n)
    local n = math_pow(10, n or 0)
    local x = x * n

    if x >= 0 then 
        x = math_floor(x + 0.5)
    else 
        x = math_ceil(x - 0.5)
    end

    return x / n
end

local menu = {
    enabled = ui.new_checkbox("RAGE", "Aimbot", "Log aimbot history"),
    drag_key = ui.new_hotkey("RAGE", "Aimbot", "\n history_drag_key", true),
    store_info = ui.new_multiselect("RAGE", "Aimbot", "\n history_stored", rebase_table(list)),
    count = ui.new_slider("RAGE", "Aimbot", "\n history_value", 2, 10, 6, true),

    line_type = ui.new_combobox("RAGE", "Aimbot", "Line color type", { "Off", "Static", "Fade" }),
    color_picker = ui.new_color_picker("RAGE", "Aimbot", "\n history_line_color", 235, 93, 167, 255),

    -- Menu data
    x_axis = ui.new_slider("RAGE", "Aimbot", "\n history_posx", 0, 8192, 350, false),
    y_axis = ui.new_slider("RAGE", "Aimbot", "\n history_posy", 0, 8192, 5, false),

    size = { 245, 150 },
    is_dragging = false,
    drag_x = 0, drag_y = 0,
}

client.set_event_callback("aim_hit", function(e) 
    for i = 1, #player_data do 
        local pdata = player_data[i]

        if pdata.id == e.id then
            player_data[i].state = 2
        end
    end
end)

client.set_event_callback("bullet_impact", function(e)
    local me = entity.get_local_player()

    if client.userid_to_entindex(e.userid) == me then
        bullet_info[#bullet_info+1] = {
            called = false,
            tick = globals_tickcount(),
            pos = { e.x, e.y, e.z }
        }
    end
end)

client.set_event_callback("aim_miss", function(e)
    if e.reason == "death" then
        return
    end

    for i = 1, #bullet_info do
        local binfo = bullet_info[i]
        if  bullet_info[i] ~= nil and not bullet_info[i].called and 
            binfo.tick <= globals_tickcount() + 1 then

            bullet_info[i].called = true

            for i = 1, #player_data do 
                local pinfo = player_data[i]

                if pinfo.id == e.id then
                    if e.reason == "spread" then
                        local origin = { client_eye_position() }

                        local pitch_aim, yaw_aim = vector_angles(origin[1], origin[2], origin[3], pinfo.data.x, pinfo.data.y, pinfo.data.z)
                        local pitch_shot, yaw_shot = vector_angles(origin[1], origin[2], origin[3], binfo.pos[1], binfo.pos[2], binfo.pos[3])
                
                        local spread_angles = vector_distance({ pitch_aim, yaw_aim }, { pitch_shot, yaw_shot})
                        player_data[i].spread_inaccuracy = round(spread_angles, 2)
                    end


                    player_data[i].state = 1
                    player_data[i].reason = e.reason
                end
            end

        end
    end
end)

client.set_event_callback("aim_fire", function(e)
    for i = ui_get(menu.count), 2, -1 do 
        player_data[i] = player_data[i-1]
    end

    if #player_data > ui_get(menu.count) then
        for i = #player_data, max, -1 do 
            player_data[i] = nil
        end
    end

    local name = entity.get_player_name(e.target)
    local sub = string.sub(name, 0, 9)

    player_data[1] = {
        id = e.id,
        data = e,
        state = 0,
        nickname = sub,
    }
end)

local get_datagram = function(name, e)
    local r, g, b = 255, 255, 255

    local pi = {
        ["ID"] = function() return e.id end,
        ["Player"] = function() return e.nickname end,
        ["Damage"] = function() return e.data.damage end,

        ["Hitbox"] = function()
            local hitgroups = {
                full = { "body", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear" },
                abb = { "B", "H", "C", "S", "LA", "RA", "LL", "RL", "N", "?", "G" },
            }
            
            return hitgroups.full[e.data.hitgroup + 1]
        end,

        ["Flags"] = function()
            local flags = {
                e.data.teleported and 'T' or '',
                e.data.interpolated and 'I' or '',
                e.data.extrapolated and 'E' or '',
                e.data.high_priority and 'H' or ''
                -- m.boosted and 'B' or '',
            }

            for i = 1, #flags do
                if flags[i] ~= "" then 
                    return table_concat(flags)
                end
            end

            return "-"
        end,

        ["Lag Comp"] = function()
            local bt = e.data.backtrack / globals_tickinterval()

            if e.data.teleported then
                r, g, b = 55, 84, 84
                return "breaking"
            elseif bt < 0 then
                r, g, b = 181, 181, 100
                return "predict: " .. math_abs(bt) .. "t"
            elseif bt ~= 0 then
                return bt .. " ticks"
            end
        end,
        
        ["Reason"] = function() 
            if e.state == 1 then

                local sp_in = e.spread_inaccuracy

                local _errors = {
                    ["death"] = "death",
                    ["?"] = "unknown",
                    ["spread"] = "sp: " .. (sp_in ~= nil and sp_in or "?") .. "°",
                    ["prediction error"] = "prediction"
                }

                return _errors[e.reason]
            end
        end,
    }

    return {
        value = (pi[name] ~= nil and pi[name]() or "-"),
        color = { r, g, b }
    }
end

client.set_event_callback("paint", function()
    local selected = ui_get(menu.store_info)
    local frame = 255 / 0.5 * globals_frametime()

    if #player_data ~= 0 then
       max_alpha = max_alpha + frame
       max_alpha = max_alpha > 255 and 255 or max_alpha
    else
        max_alpha = max_alpha - frame
        max_alpha = max_alpha < 0 and 0 or max_alpha
    end

    if not ui_get(menu.enabled) or #selected < 1 or max_alpha < 1 then
        return
    end

    local line_type, gradient = ui_get(menu.line_type), 3
    local pos = { ui_get(menu.x_axis), ui_get(menu.y_axis) }

    renderer_rectangle(pos[1], pos[2], menu.size[1], 34 + 16 * (#player_data-1), 22, 20, 26, set_alpha(100, max_alpha))
    renderer_rectangle(pos[1], pos[2], menu.size[1], 15, 16, 22, 29, set_alpha(160, max_alpha))

    if line_type ~= "Off" then
        gradient = 2
        if line_type == "Static" then
            local r, g, b, a = 
                ui_get(menu.color_picker)

            renderer_rectangle(pos[1], pos[2] + 14, menu.size[1], 1, r, g, b, set_alpha(a, max_alpha))
        else
            local realtime = globals_realtime()
            
            local color = {
                math_floor(math_sin(realtime * 2) * 127 + 128),
                math_floor(math_sin(realtime * 2 + 2) * 127 + 128),
                math_floor(math_sin(realtime * 2 + 4) * 127 + 128)
            }

            renderer.gradient(pos[1], pos[2] + 14, menu.size[1], 1, color[1], color[2], color[3], set_alpha(255, max_alpha), color[3], color[2], color[1], set_alpha(200, max_alpha), true)
        end
    end

    local val_offset = 8
    local x, y = pos[1], pos[2] + 16

    local text_alpha = set_alpha(255, max_alpha)

    local colors = {
        [0] = { 118, 171, 255 },
        [1] = { 255, 84, 84 },
        [2] = { 94, 230, 75 }
    }

    for name, value in pairs(selected) do
        local val = string_upper(value)
        local offset = find_value(list, value)
        local width, height = renderer_measure_text("-", val)

        renderer_text(x + val_offset, pos[2] + gradient, 255, 255, 255, text_alpha, "-", 70, val)

        for i = 1, #player_data do
            local e = player_data[i]
            local yaw = pos[2] + 1 + (16 * i)
            local datagram = get_datagram(value, e)

            local r, g, b = unpack(colors[e.state])
            renderer_rectangle(x, yaw, 2, 15, r, g, b, text_alpha)
            renderer_text(x + val_offset, yaw + 1, datagram.color[1], datagram.color[2], datagram.color[3], text_alpha, nil, 70, datagram.value)
        end

        val_offset = val_offset + width + (offset ~= nil and offset[2] or 5)
    end

    menu.size[1] = val_offset
end)

client.set_event_callback("paint", function()
    ui_set(menu.drag_key, "On hotkey")

    if not ui_get(menu.enabled) then
        return
    end

    local mouse_in_rect = function(x1, y1, x2, y2)
        local mouse_position = { ui_mouse_position() }
        return (mouse_position[1] >= x1 and mouse_position[1] <= x2 and mouse_position[2] >= y1 and mouse_position[2] <= y2)
    end

    local mouse_position = { ui_mouse_position() }
    local key_state = ui.is_menu_open() and ui_get(menu.drag_key)

    if menu.is_dragging and not key_state then
        menu.is_dragging = false
        menu.drag_x = 0
        menu.drag_y = 0
        return
    end

    if menu.is_dragging then
        local end_x, end_y = 
            mouse_position[1] - menu.drag_x,
            mouse_position[2] - menu.drag_y

        if end_x > 0 then ui_set(menu.x_axis, end_x) end
        if end_y > 0 then ui_set(menu.y_axis, end_y) end
    end

    local mpos = {
        ui_get(menu.x_axis),
        ui_get(menu.y_axis)
    }

    if key_state and mouse_in_rect(mpos[1], mpos[2], mpos[1] + menu.size[1], mpos[2] + menu.size[2]) then
        menu.is_dragging = true

        menu.drag_x = mouse_position[1] - ui_get(menu.x_axis)
        menu.drag_y = mouse_position[2] - ui_get(menu.y_axis)
    end
end)

local function set_visible()
    local active = ui_get(menu.enabled)

    ui.set_visible(menu.store_info, active)
    ui.set_visible(menu.count, active)
    ui.set_visible(menu.line_type, active)
    ui.set_visible(menu.color_picker, active)
end

set_visible()

ui.set_callback(menu.enabled, set_visible)
ui.set_visible(menu.x_axis, false)
ui.set_visible(menu.y_axis, false)
