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

local vector_distance = function(a, b)
	return math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2) + math.pow(a.z - b.z, 2))
end

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

local Colors = {
    { 124, 195, 13 },
    { 176, 205, 10 },
    { 213, 201, 19 },
    { 220, 169, 16 },
    { 228, 126, 10 },
    { 229, 104, 8 },
    { 235, 63, 6 },
    { 237, 27, 3 },
    { 255, 0, 0 }
}

local function get_color(number, max)
    local _math = function(int, max, declspec)
        local int = (int > max and max or int)
    
        local tmp = max / int;
        local i = (declspec / tmp)
        i = (i >= 0 and math.floor(i + 0.5) or math.ceil(i - 0.5))
    
        return i
    end

	i = _math(number, max, #Colors)
	return
		Colors[i <= 1 and 1 or i][1], 
		Colors[i <= 1 and 1 or i][2],
		Colors[i <= 1 and 1 or i][3]
end

local legit_active, legit_key = ui.reference("Legit", "Aimbot", "Enabled")
local rage_active, active_key = ui.reference("RAGE", "Aimbot", "Enabled")
local rage_selection = ui.reference("RAGE", "Aimbot", "Target selection")
local rage_hitbox = ui.reference("RAGE", "Aimbot", "Target hitbox")
local rage_recoil = ui.reference("RAGE", "Other", "Remove recoil")
local rage_autowall = ui.reference("RAGE", "Aimbot", "Automatic penetration")
local rage_fakeduck = ui.reference("RAGE", "Other", "Duck peek assist")

local TP, TP_KEY = ui.reference("VISUALS", "Effects", "Force third person (alive)")
local flag_limit = ui.reference("AA", "Fake lag", "Limit")
local pitch = ui.reference("AA", "Anti-aimbot angles", "Pitch")
local yaw_base = ui.reference("AA", "Anti-aimbot angles", "Yaw base")
local yaw, yaw_num = ui.reference("AA", "Anti-aimbot angles", "Yaw")
local yaw_jitter, yaw_jitter_num = ui.reference("AA", "Anti-aimbot angles", "Yaw jitter")
local body, body_num = ui.reference("AA", "Anti-aimbot angles", "Body yaw")
local limit = ui.reference("AA", "Anti-aimbot angles", "Fake yaw limit")
local twist = ui.reference("AA", "Anti-aimbot angles", "Twist")
local lby = ui.reference("AA", "Anti-aimbot angles", "Lower body yaw target")

local menu = {
    enabled = ui.new_checkbox("RAGE", "Other", "Legit mode"),
    rage_assist = ui.new_checkbox("RAGE", "Other", "Rage aimbot assist"),

    ov_autowall = ui.new_checkbox("RAGE", "Other", "Override automatic penetration"),
    ov_autowall_key = ui.new_hotkey("RAGE", "Other", "Override penetration key", true),
    nearest = ui.new_multiselect("RAGE", "Other", "Nearest hitboxes", names),

    legit_aa = ui.new_checkbox("RAGE", "Other", "Legit anti-aim"),
    bypass = ui.new_checkbox("RAGE", "Other", "Bypass restrictions"),
    static_aa = ui.new_checkbox("RAGE", "Other", "Static body yaw"),
    draw_edges = ui.new_checkbox("RAGE", "Other", "Draw anti-aim edges"),
    edge_picker = ui.new_color_picker("RAGE", "Other", "Edges color", 32, 160, 230, 255),

    edge_factor = ui.new_slider("RAGE", "Other", "Factor", 1, 7, 3),
    edge_distance = ui.new_slider("RAGE", "Other", "Distance", 0, 50, 25),

    aim_setup = ui.new_button("RAGE", "Other", "Setup aimbot", function()
        local autofire = ui.reference("RAGE", "Aimbot", "Automatic fire")
        local psilent = ui.reference("RAGE", "Aimbot", "Silent aim")
        local aimstep = ui.reference("RAGE", "Aimbot", "Reduce aim step")
        local maximum_fov = ui.reference("RAGE", "Aimbot", "Maximum FOV")

        local fov = ui_get(maximum_fov)

        ui_mset({
            [rage_selection] = 'Near crosshair',
            [rage_hitbox] = { 'Head' },
            [rage_recoil] = false,
            [psilent] = false,
            [autofire] = true,
            [aimstep] = false,
            [maximum_fov] = fov > 10 and 10 or fov
        })

        client.log("Legit mode > Done")
    end)
}

local function set_visible()
    local active = ui_get(menu.enabled)
    local legit_aa = ui_get(menu.legit_aa)

    ui.set_visible(menu.rage_assist, active)
    ui.set_visible(menu.ov_autowall, active)
    ui.set_visible(menu.ov_autowall_key, active)
    ui.set_visible(menu.nearest, active)

    ui.set_visible(menu.legit_aa, active)
    ui.set_visible(menu.bypass, active and legit_aa)
    ui.set_visible(menu.static_aa, active and legit_aa)
    ui.set_visible(menu.draw_edges, active and legit_aa)
    ui.set_visible(menu.edge_picker, active and legit_aa)
    ui.set_visible(menu.edge_factor, active and legit_aa)
    ui.set_visible(menu.edge_distance, active and legit_aa)
end

local function do_legit_aa()
    local local_player = get_local()

    if not entity.is_alive(local_player) then
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
        ["fraction"] = 1,
        ["surpassed"] = false,
        ["angle"] = vector(0, 0, 0),
        ["var"] = 0,
        ["side"] = "UNKNOWN"
    }

    for a = central, math.pi * 3.0, step do
        if a == central then
            central = clamp_angles(rad2deg(a))
        end

        local clm = clamp_angles(central - rad2deg(a))
        local abs = math.abs(clm)

        if abs < 90 and abs > 1 then
            local side = "UNKNOWN"
            local location = vector(
                radius * math.cos(a) + m_vecOrigin.x, 
                radius * math.sin(a) + m_vecOrigin.y, 
                m_vecOrigin.z
            )

            local fraction, entindex = trace_line(local_player, m_vecOrigin, location)

            if math.floor(clm + 0.5) < -21 then side = "LEFT" end
            if math.floor(clm + 0.5) > 21 then side = "RIGHT" end

            local fr_info = {
                ["fraction"] = fraction,
                ["surpassed"] = (fraction < 1),
                ["angle"] = vector(0, clamp_angles(rad2deg(a)), 0),
                ["var"] = math.floor(clm + 0.5),
                ["side"] = side --[ 0 - center / 1 - left / 2 - right ]
            }

            if data.fraction > fraction then data = fr_info end

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
    cache[name] = cache[name] ~= nil and cache[name] or condition

    if should_call then a() else
        if cache[name] ~= nil then
            b(cache[name])
            cache[name] = nil
        end
    end
end

client.set_event_callback("setup_command", function(cmd)
    local local_player = get_local()
    local in_legit = ui_get(legit_key)

    if not ui_get(menu.enabled) then
        return
    end

    if ui_get(menu.rage_assist) then
        cache_process("rage_active", ui_get(rage_active), in_legit and not ui_get(rage_fakeduck), function()
            ui_set(rage_recoil, false)
            ui_set(rage_active, false)
        end, function(c)
            ui_set(rage_active, c)
        end)

        cache_process("on_fakeduck", ui_get(flag_limit), ui_get(rage_active) and ui_get(rage_fakeduck), function()
            local _, _, m_vecViewOffset = get_prop(local_player, "m_vecViewOffset")

            ui_set(flag_limit, 14)
            if (ui_get(TP) and ui_get(TP_KEY)) or m_vecViewOffset < 64 then
                cmd.in_attack = 0
            end
        end, function(c)
            ui_set(flag_limit, c)
        end)
    end

    if ui_get(menu.ov_autowall) then
        ui_set(rage_autowall, ui_get(menu.ov_autowall_key))
    end

    if ui_get(menu.legit_aa) and ui_get(menu.static_aa) and not in_legit then
        local _, _, AIR_VELOCITY = get_prop(local_player, "m_vecVelocity")

        if cmd.in_jump == 0 and AIR_VELOCITY^2 < 1 then
            local sm = cmd.in_duck ~= 0 and 2.941177 or 1.000001
            local sm = cmd.command_number % 4 < 2 and -sm or sm
            
            cmd.sidemove = cmd.sidemove ~= 0 and cmd.sidemove or sm
        end
    end

    local enemy, hid, dst = get_nearbox(ui_get(rage_fakeduck))
    local hitbox = find_cmd(hitscan, hid)

    if contains(ui_get(menu.nearest), hitbox) then
        ui_set(rage_selection, "Near crosshair")
        ui_set(rage_hitbox, hitbox)
    end
end)

local cached_time = globals.realtime()
client.set_event_callback("paint", function()
    if not ui_get(menu.enabled) or not get_local() or not ui_get(menu.legit_aa) then
        return
    end

    -- Analysis
    local interval = 1 / globals.tickinterval()
    local frame = interval * globals.absoluteframetime()
    local latency = client.latency() * 1000

    local end_frame = 0
    local predicted_cmd = 0

    if frame > 0.55 then
        end_frame = frame
        end_frame = (end_frame / 0.55) * 100

        predicted_cmd = (end_frame - 100) / 100

        if not ui_get(menu.bypass) and predicted_cmd > 0.7 then
            cached_time = globals.realtime() + 1
        end
    end

    if 150 - latency < 75 then
        latency = 75 - (150 - latency)
        if latency < 1 then latency = 1 end

        latency = (latency / 75) * 100
        predicted_cmd = predicted_cmd + (latency / 100)
    end

    if predicted_cmd > 1 then 
        predicted_cmd = 1
    end

    local surpassed = globals.realtime() > cached_time
    local p_key = ui_get(legit_key) or not surpassed
    local data = do_legit_aa()

    cache_process("AA_PITCH", ui_get(pitch), p_key, function() ui_set(pitch, "Off") end, function(c) ui_set(pitch, c) end)
    cache_process("AA_YAW", ui_get(yaw), p_key, function() ui_set(yaw, "Off") end, function(c) ui_set(yaw, c) end)
    cache_process("AA_BODY", ui_get(body), p_key, function() ui_set(body, "Off") end, function(c) ui_set(body, c) end)

    if data ~= nil then
        if not ui_get(menu.bypass) and predicted_cmd > 0.85 then
            cached_time = globals.realtime() + 1
        end

        if not p_key and surpassed and data.fraction < 1 then
            ui_mset({
                [pitch] = 'Off',
                [yaw_base] = 'Local view',
                [yaw] = '180',
                [yaw_num] = 180,
                [yaw_jitter] = "Off",
                [limit] = 60,
            
                [body] = 'Static',
                [twist] = false,
                [lby] = "Opposite"
            })
    
            if data.fraction < 1 then
                ui_set(body_num, data.var > 0 and 120 or -120)
            end
        elseif p_key then
            data.side = "DISABLED"
        end

        -- Indicators
        local i = 0.5
        local end_datagram = 1 - predicted_cmd
        local r, g, b = Colors[1][1], Colors[1][2], Colors[1][3]

        if (predicted_cmd * 100) > 35 then
            r, g, b = get_color((predicted_cmd * 100) - 35, 35)
        end

        local text = "AA"
        local width, height = renderer.measure_text("+", text)
        local y = renderer.indicator(255, 255, 255, 150, text)

        renderer.rectangle(10, y + 28, width, 5, 0, 0, 0, not p_key and 150 or 0)
        renderer.rectangle(11, y + 29, ((width - 2) / 1) * end_datagram, 3, r, g, b, not p_key and 255 or 0)

        local sync = not surpassed and "OUT OF SYNC" or (math.floor(end_datagram * 100) .. "%")

        renderer.text(width + 17, y + (10  * i), 255, 255, 255, 255, "-", nil, "SYNC: " .. sync); i = i + 1;
        renderer.text(width + 17, y + (10 * i), 255, 255, 255, 255, "-", nil, "STATE: " .. data.side); i = i + 1;
    end
end)
