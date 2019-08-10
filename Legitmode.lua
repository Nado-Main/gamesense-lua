local vector = function(x, y, z)
    x = x ~= nil and x or 0
    y = y ~= nil and y or 0
    z = z ~= nil and z or 0

    return {
        ["x"] = x,
        ["y"] = y,
        ["z"] = z
    }
end

local vector_add = function(vector1, vector2)
    return { 
        ["x"] = vector1.x + vector2.x, 
        ["y"] = vector1.y + vector2.y, 
        ["z"] = vector1.z + vector2.z
    }
end

local vector_substract = function(vector1, vector2)
    return { 
        ["x"] = vector1.x - vector2.x, 
        ["y"] = vector1.y - vector2.y, 
        ["z"] = vector1.z - vector2.z
    }
end

local rad2deg = function(rad) return (rad * 180 / math.pi) end
local deg2rad = function(deg) return (deg * math.pi / 180) end

local trace_line = function(entity, start, _end)
    return client.trace_line(entity, start.x, start.y, start.z, _end.x, _end.y, _end.z)
end

local world_to_screen = function(x, y, z, func)
    local x, y = renderer.world_to_screen(x, y, z)
    if x ~= nil and y ~= nil then 
        func(x, y)
    end
end

local clamp_angles = function(angle)
    angle = angle % 360 
    angle = (angle + 360) % 360

    if angle > 180 then
        angle = angle - 360
    end

    return angle
end

local get_atan = function(ent, eye_pos, camera)
    local data = { id = nil, dst = 2147483647 }

    for i = 0, 19 do
        local hitbox = vector(entity.hitbox_position(ent, i))
        local ext = vector_substract(hitbox, eye_pos)

        local yaw = rad2deg(math.atan2(ext.y, ext.x))
        local pitch = -rad2deg(math.atan2(ext.z, math.sqrt(ext.x^2 + ext.y^2)))
    
        local yaw_dif = math.abs(camera.y % 360 - yaw % 360) % 360
        local pitch_dif = math.abs(camera.x - pitch) % 360
            
        if yaw_dif > 180 then 
            yaw_dif = 360 - yaw_dif
        end

        local dst = math.sqrt(yaw_dif^2 + pitch_dif^2)

        if dst < data.dst then
            data.dst = dst
            data.id = i
        end
    end

    return data.id, data.dst
end

local function get_nearbox(z_pos)
    local get_players = entity.get_players(true)
    local closest = { enemy = nil, hitbox = nil, dst = 2147483647 }
    
    if #get_players == 0 then
        return
    end

    local eye_pos = vector(client.eye_position())
    local camera = vector(client.camera_angles())

    camera.z = z_pos ~= nil and 64 or camera.z

    for i = 1, #get_players do
        local hitbox_id, distance = 
            get_atan(get_players[i], eye_pos, camera)

        if distance < closest.dst then
            closest.dst = distance
            closest.hitbox = hitbox_id
            closest.enemy = get_players[i]
        end
    end

    return closest.enemy, closest.hitbox, closest.dst
end

local contains = function(tab, val, sys)
    for index, value in ipairs(tab) do
        if sys == 1 and index == val then 
            return true
        elseif value == val then
            return true
        end
    end
 
    return false
end

local find_cmd = function(tab, value)
    for k, v in pairs(tab) do
        if contains(v, value) then
            return k
        end
    end

    return nil
end

local ui_mset = function(list)
    for ref, val in pairs(list) do
        ui.set(ref, val)
    end
end

local ui_get, ui_set = ui.get, ui.set
local get_local = entity.get_local_player
local get_prop = entity.get_prop

local var_direction = {
    "Safe",
    "Maximum"
}

local edge_count = { [1] = 7, [2] = 12, [3] = 15, [4] = 19, [5] = 23, [6] = 28, [7] = 29 }
local names = { "Head", "Chest", "Stomach" --[[, "Arms", "Legs", "Feet" ]] }

local hitscan = {
    ["Head"] = { 0, 1 },
    ["Chest"] = { 2, 3, 4 },
    ["Stomach"] = { 5, 6 },
    ["Arms"] = { 13, 14, 15, 16, 17, 18 },
    ["Legs"] = { 7, 8, 9, 10 },
    ["Feet"] = { 11, 12 }
}

local legit_active, legit_key = ui.reference("Legit", "Aimbot", "Enabled")
local rage_active, active_key = ui.reference("RAGE", "Aimbot", "Enabled")
local rage_selection = ui.reference("RAGE", "Aimbot", "Target selection")
local rage_hitbox = ui.reference("RAGE", "Aimbot", "Target hitbox")
local rage_recoil = ui.reference("RAGE", "Other", "Remove recoil")
local rage_autowall = ui.reference("RAGE", "Aimbot", "Automatic penetration")
local rage_fakeduck = ui.reference("RAGE", "Other", "Duck peek assist")
local infinite_duck = ui.reference("AA", "Other", "Infinite duck")
local auto_pistols = ui.reference("MISC", "Miscellaneous", "Automatic weapons")

local autofire = ui.reference("RAGE", "Aimbot", "Automatic fire")
local psilent = ui.reference("RAGE", "Aimbot", "Silent aim")
local aimstep = ui.reference("RAGE", "Aimbot", "Reduce aim step")
local maximum_fov = ui.reference("RAGE", "Aimbot", "Maximum FOV")

local flag_limit = ui.reference("AA", "Fake lag", "Limit")
local pitch = ui.reference("AA", "Anti-aimbot angles", "Pitch")
local yaw_base = ui.reference("AA", "Anti-aimbot angles", "Yaw base")
local yaw, yaw_num = ui.reference("AA", "Anti-aimbot angles", "Yaw")
local yaw_jitter = ui.reference("AA", "Anti-aimbot angles", "Yaw jitter")
local body, body_num = ui.reference("AA", "Anti-aimbot angles", "Body yaw")
local limit = ui.reference("AA", "Anti-aimbot angles", "Fake yaw limit")
local twist = ui.reference("AA", "Anti-aimbot angles", "Twist")
local lby = ui.reference("AA", "Anti-aimbot angles", "Lower body yaw target")

local menu = {
    enabled = ui.new_checkbox("RAGE", "Other", "Rage aimbot assistance"),

    ov_autowall = ui.new_checkbox("RAGE", "Other", "Override automatic penetration"),
    ov_autowall_key = ui.new_hotkey("RAGE", "Other", "Override penetration key", true),

    nearest = ui.new_multiselect("RAGE", "Other", "Nearest hitboxes", names),

    legit_aa = ui.new_checkbox("RAGE", "Other", "Legit anti-aim"),
    direction = ui.new_combobox("RAGE", "Other", "\n legitmode_aa_direction", var_direction),

    edge_factor = ui.new_slider("RAGE", "Other", "Edge count per side \n legitmode_edges_factor", 1, 7, 3),
    edge_distance = ui.new_slider("RAGE", "Other", "\n legitmode_edges_distance", 0, 50, 25, true, "in"),

    draw_edges = ui.new_checkbox("RAGE", "Other", "Draw anti-aim edges"),
    edge_picker = ui.new_color_picker("RAGE", "Other", "\n legitmode_edges_clr", 32, 160, 230, 255),
}

local function set_visible()
    local active = ui_get(menu.enabled)
    local legit_aa = ui_get(menu.legit_aa)

    ui.set_visible(menu.ov_autowall, active)
    ui.set_visible(menu.ov_autowall_key, active)

    ui.set_visible(menu.nearest, active)

    ui.set_visible(menu.legit_aa, active)
    ui.set_visible(menu.direction, active and legit_aa)

    ui.set_visible(menu.edge_factor, active and legit_aa)
    ui.set_visible(menu.edge_distance, active and legit_aa)

    ui.set_visible(menu.draw_edges, active and legit_aa)
    ui.set_visible(menu.edge_picker, active and legit_aa)
end

local function do_legit_aa(local_player)
    if not local_player or not entity.is_alive(local_player) then
        return
    end

    local m_vecOrigin = vector(get_prop(local_player, "m_vecOrigin"))
    local m_vecViewOffset = vector(get_prop(local_player, "m_vecViewOffset"))

    local m_vecOrigin = vector_add(m_vecOrigin, m_vecViewOffset)

    local radius = 20 + ui_get(menu.edge_distance) + 0.1
    local step = math.pi * 2.0 / edge_count[ui_get(menu.edge_factor)]

    local camera = vector(client.camera_angles())
    local central = deg2rad(math.floor(camera.y + 0.5))

    local data = {
        fraction = 1,
        surpassed = false,
        angle = vector(0, 0, 0),
        var = 0,
        side = "LAST KNOWN"
    }

    for a = central, math.pi * 3.0, step do
        if a == central then
            central = clamp_angles(rad2deg(a))
        end

        local clm = clamp_angles(central - rad2deg(a))
        local abs = math.abs(clm)

        if abs < 90 and abs > 1 then
            local side = "LAST KNOWN"
            local location = vector(
                radius * math.cos(a) + m_vecOrigin.x, 
                radius * math.sin(a) + m_vecOrigin.y, 
                m_vecOrigin.z
            )

            local _fr, entindex = trace_line(local_player, m_vecOrigin, location)

            if math.floor(clm + 0.5) < -21 then side = "LEFT" end
            if math.floor(clm + 0.5) > 21 then side = "RIGHT" end

            local fr_info = {
                fraction = _fr,
                surpassed = (_fr < 1),
                angle = vector(0, clamp_angles(rad2deg(a)), 0),
                var = math.floor(clm + 0.5),
                side = side --[ 0 - center / 1 - left / 2 - right ]
            }

            if data.fraction > _fr then data = fr_info end

            if ui_get(menu.draw_edges) then
                world_to_screen(location.x, location.y, location.z - m_vecViewOffset.z, function(x, y)
                    local r, g, b = 255, 255, 255
                    if fr_info.surpassed then
                        r, g, b = ui_get(menu.edge_picker)
                    end

                    renderer.text(x, y, r, g, b, 255, "c", 0, "•")
                end)
            end
        end
    end

    return data
end

set_visible()

ui.set_callback(menu.enabled, set_visible)
ui.set_callback(menu.legit_aa, set_visible)

local cache = { }
local cache_process = function(name, condition, should_call, a, b)
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

client.set_event_callback("setup_command", function(cmd)
    local local_player = get_local()
    
    if not ui_get(menu.enabled) then
        return
    end

    if ui_get(menu.ov_autowall) then
        ui_set(rage_autowall, ui_get(menu.ov_autowall_key))
    end

    local fov = ui_get(maximum_fov)
    local ractive = ui_get(rage_active)

    local in_legit = ui_get(legit_active) and ui_get(legit_key)
    local fakeduck_ready = ractive and ui_get(infinite_duck) and ui_get(rage_fakeduck)

    local enemy, hid, dst = get_nearbox(fakeduck_ready)
    local hitbox = find_cmd(hitscan, hid)

    ui_mset({
        [rage_selection] = 'Near crosshair',
        [rage_hitbox] = contains(ui_get(menu.nearest), hitbox) and hitbox or ui_get(rage_hitbox),

        [maximum_fov] = fov > 10 and 10 or fov,
        [rage_recoil] = false,
        [aimstep] = false,
        [psilent] = false,
        [autofire] = true
    })

    -- cache_process("rage_active", rage_active, in_legit and not fakeduck_ready, false)
    cache_process("on_fakeduck_ph1", flag_limit, ractive and fakeduck_ready, 14)
    cache_process("on_fakeduck_ph2", auto_pistols, ractive and fakeduck_ready, false)
    cache_process("on_fakeduck_ph3", legit_active, ractive and fakeduck_ready, function()
        ui_set(legit_active, false)
        if get_prop(local_player, "m_flDuckAmount") > 0.01 then
            cmd.in_attack = 0
        end
    end)
end)

client.set_event_callback("paint", function()
    local local_player = get_local()

    local aim_active = ui_get(legit_active) and ui_get(legit_key)
    local lowerbody = ui_get(menu.direction) == var_direction[1] and 'Eye yaw' or 'Opposite'

    if not ui_get(menu.enabled) or not ui_get(menu.legit_aa) or not local_player then
        return
    end

    -- cache_process("antiaim_pitch", pitch, aim_active, "Off")
    -- cache_process("antiaim_yaw", yaw, aim_active, "Off")
    -- cache_process("antiaim_byaw", body, aim_active, "Off")
    -- cache_process("antiaim_lbyt", lby, aim_active, "Off")

    local data = do_legit_aa(local_player)

    if data == nil then
        return
    end

    if not aim_active then
        ui_mset({
            [pitch] = 'Off',
            [yaw_base] = 'Local view',
            [yaw] = '180',
            [yaw_num] = 180,
            [yaw_jitter] = "Off",
            
            [body] = 'Static',
    
            [lby] = lowerbody,
            [twist] = false,
            [limit] = 60,
        })
    
        if not aim_active and data.fraction < 1 then
            if data.fraction < 1 then
                ui_set(body_num, data.var > 0 and 180 or -180)
            end
        end
    end

    -- calculations
    local clamp = function(int, min, max)
        local vl = int

        vl = vl < min and min or vl
        vl = vl > max and max or vl

        return vl
    end

    local vl = { get_prop(local_player, "m_vecVelocity") }
    local vl_sqrt = math.sqrt(vl[1]*vl[1] + vl[2]*vl[2])
    local vl_actual = math.floor(math.min(10000, vl_sqrt + 0.5))

    local by = ui_get(body_num) 
    local max_dsn = clamp(59 - 58 * vl_actual / 580, 0, 60)
    local byaw_value = clamp(by, by < 0 and -60 or 0, by > 0 and 60 or 0)
    local end_byaw = clamp(byaw_value, by < 0 and -max_dsn or 0, by > 0 and max_dsn or 0)

    -- indication
    local i = 0.5
    local text = "AA"
    local percent = 1

    local width, height = renderer.measure_text("+", text)
    local y = renderer.indicator(255, 255, 255, 150, text)

    local state = aim_active and "DISABLED" or data.side
    local end_width = ((width / 2 - 2) / 60) * end_byaw

    renderer.rectangle(10, y + 27, width, 5, 0, 0, 0, not aim_active and 150 or 0)

    if end_byaw > 0 then
        renderer.rectangle(11 + width / 2, y + 28, end_width, 3, 124, 195, 13, not aim_active and 255 or 0)
        renderer.text(11 + width / 2 + end_width, y + 24, 255, 255, 255, not aim_active and 255 or 0, "-", nil, ">")
    else
        end_width = 15 - (end_width * -1)
        end_width = end_width > 15 and 15 or end_width

        renderer.rectangle(10 + end_width, y + 28, width / 2 - end_width, 3, 124, 195, 13, not aim_active and 255 or 0)
        renderer.text(10 + end_width, y + 24, 255, 255, 255, not aim_active and 255 or 0, "-", nil, "<")
    end

    renderer.text(width + 17, y + (10  * i), 255, 255, 255, 255, "-", nil, "MAX DSN: " .. (aim_active and "0" or math.abs(end_byaw)) .. "°"); i = i + 1;
    renderer.text(width + 17, y + (10 * i), 255, 255, 255, 255, "-", nil, "DIR: " .. (aim_active and "EYE YAW" or data.side)); i = i + 1;
end)
