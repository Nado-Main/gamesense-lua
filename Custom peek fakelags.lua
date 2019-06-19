local cond = { "On visible", "While visible", "[*] Nervos" }
local double_tap, dtap_hk = ui.reference("RAGE", "Other", "Double tap")

local reference = {
    is_active = ui.new_checkbox("AA", "Fake lag", "Customize peek fake-lags"),
    vizualise = ui.new_checkbox("AA", "Fake lag", "Vizualise predicted data"),
    vizualise_color = ui.new_color_picker("AA", "Fake lag", "Vizualisation color", 90, 236, 138, 255),

    condition = ui.new_combobox("AA", "Fake lag", "\n fl_condition", cond),
    extrapolation = ui.new_slider("AA", "Fake lag", "Extrapolation (ticks)", 5, 15, 8, true),

    fl = ui.reference("AA", "Fake lag", "Enabled"),
    fl_limit = ui.reference("AA", "Fake lag", "Limit"),
    minimum_dmg = ui.reference("RAGE", "Aimbot", "Minimum Damage"),

    pos = { 0, 0, 0 },
    last_fl = 0
}

local ui_get, math_sqrt = ui.get, math.sqrt
local entity_get_prop = entity.get_prop
local globals_tickinterval = globals.tickinterval
local client_trace_line = client.trace_line
local client_trace_bullet = client.trace_bullet
local entity_is_enemy = entity.is_enemy
local entity_get_local_player = entity.get_local_player
local entity_get_players = entity.get_players
local entity_hitbox_position = entity.hitbox_position

local function is_moving(index)
    local x, y, z = entity_get_prop(index, "m_vecVelocity")
    return math.sqrt(x*x + y*y + z*z) > 1.0
end

local function vec_add(a, b) 
    return { a[1] + b[1], a[2] + b[2], a[3] + b[3] }
end

local lag_data = { 
    count = 0, 
    chokedcommands = 0, 
    passed = false, 
    extrapolated = { }
}

lag_data.should_lag = function() return (lag_data.count > 0) end
lag_data.reset = function()
    lag_data.count = 0
    lag_data.chokedcommands = 0
    lag_data.extrapolated = { }
end

lag_data.predict_player = function(player, simulation_tick_delta, no_collision)
    local simulation_data = {
        entity = player,
        on_ground = entity_get_prop(player, "m_hGroundEntity") ~= nil,

        velocity = { entity_get_prop(player, "m_vecVelocity") },
        origin = { entity_get_prop(player, "m_vecOrigin") },
    }

    local simulate_movement = function(record)
        local sv_gravity = cvar.sv_gravity:get_int()
        local sv_jump_impulse = cvar.sv_jump_impulse:get_int()

        local data = record
        local predicted_origin = data.origin
        local tickinterval = globals_tickinterval()
    
        if not data.on_ground and not no_collision then
            local gravity_per_tick = sv_gravity * tickinterval
            data.velocity[3] = data.velocity[3] - gravity_per_tick
        else
            local sv_accelerate = cvar.sv_accelerate:get_int()
            local sv_maxspeed = cvar.sv_maxspeed:get_int()
            local surface_friction = 1.0

            local speed = math.sqrt(data.velocity[1]^2 + data.velocity[2]^2)
            local max_accelspeed = sv_accelerate * tickinterval * sv_maxspeed * surface_friction
    
            local wishspeed = max_accelspeed

            if speed - max_accelspeed <= -1 then
                wishspeed = max_accelspeed / (speed / (sv_accelerate * tickinterval))
            end
        end
    
        predicted_origin = vec_add(predicted_origin, {
            data.velocity[1] * tickinterval,
            data.velocity[2] * tickinterval,
            data.velocity[3] * tickinterval
        })

        local fraction = client_trace_line(player, data.origin[1], data.origin[2], data.origin[3], predicted_origin[1], predicted_origin[2], predicted_origin[3])
        local ground_fraction = client_trace_line(player, data.origin[1], data.origin[2], data.origin[3], data.origin[1], data.origin[2], data.origin[3] - 2)
    
        if no_collision or fraction > 0.97 then
            data.origin = predicted_origin
            data.on_ground = (ground_fraction == 0)
    
            lag_data.extrapolated[#lag_data.extrapolated+1] = data.origin
        end
    
        return data
    end

    if simulation_tick_delta > 0 then
        local ticks_left = simulation_tick_delta

        repeat
            simulation_data = simulate_movement(simulation_data)
            ticks_left = ticks_left - 1
        until ticks_left < 1

        return simulation_data
    end
end

lag_data.trace_positions = function(me, local_pos, list)
    local ray_exec = function(me, local_pos, data)
        local index, dmg = client_trace_bullet(me, 
            local_pos[1], local_pos[2], local_pos[3], 
            data[1], data[2], data[3]
        )
    
        if index == nil or index == me or not entity.is_enemy(index) then
            return false
        end
        
        return dmg > ui_get(reference.minimum_dmg)
    end

    if local_pos[1] ~= nil then
        for i = 1, #list do
            if list[i][1] ~= nil and ray_exec(me, local_pos, list[i]) then
                return true
            end
        end
    end
    
	return false
end

local function _callback(arg)
    local active = ui_get(reference.is_active)

    ui.set_visible(reference.vizualise, active)
    ui.set_visible(reference.vizualise_color, active)

    ui.set_visible(reference.condition, active)
    ui.set_visible(reference.extrapolation, active)

    if arg == nil then
        ui.set_callback(reference.is_active, _callback)
    end
end

_callback()

client.set_event_callback("paint", function()
    if not ui_get(reference.is_active) or not ui_get(reference.vizualise) then
        return
    end

    local extrapolated = lag_data.extrapolated
    local r, g, b, a = ui_get(reference.vizualise_color)

    for i = 1, #extrapolated do
        local current = extrapolated[i]
        local x, y = renderer.world_to_screen(current[1], current[2], current[3])

        if extrapolated[i-1] ~= nil and x ~= nil and y ~= nil then
            local prev_data = extrapolated[i-1]
            local prev_x, prev_y = renderer.world_to_screen(prev_data[1], prev_data[2], prev_data[3])

            if prev_x ~= nil and prev_y ~= nil then
                renderer.line(prev_x, prev_y, x, y, r, g, b, a)
                -- renderer.line(prev_x + 1, prev_y + 1, x, y, r, g, b, a)
            end

            if i == #extrapolated then
                renderer.text(x, y, 255, 255, 255, 255, "-", 0, "*")
            end
        end
    end
end)

client.set_event_callback("setup_command", function(cmd)
    local me = entity_get_local_player()
    local players = entity_get_players(true)

    local eye_pos = { client.eye_position() } 
    local condition = ui_get(reference.condition)
    local ui_ticks = ui_get(reference.extrapolation)

    if not ui_get(reference.is_active) or players == nil or eye_pos[1] == nil then
        return
    end

    lag_data.reset() -- Reset previous command
    lag_data.chokedcommands = cmd.chokedcommands
    
    if not is_moving(me) then reference.pos = eye_pos else
        local predicted_data = 
            lag_data.predict_player(me, ui_ticks, true)

        reference.pos = vec_add(predicted_data.origin, { entity_get_prop(me, "m_vecViewOffset") })
    end

    for i=1, #players do
        local hitboxes = {
            { entity_hitbox_position(players[i], 0) },
            { entity_hitbox_position(players[i], 4) },
            { entity_hitbox_position(players[i], 2) }
        }

        if lag_data.trace_positions(me, reference.pos, hitboxes) then
            lag_data.count = lag_data.count + 1
        end
    end

    if condition ~= cond[3] then
        if lag_data.should_lag() then
            if cmd.chokedcommands < reference.last_fl then
                lag_data.passed = true
            end
        
            if condition == cond[2] or (condition ~= cond[2] and not lag_data.passed) then
                cmd.allow_send_packet = false
            end
        elseif lag_data.passed then
            lag_data.passed = false
        end
    else
        ui.set(double_tap, true)
        ui.set(dtap_hk, lag_data.should_lag() and "On Hotkey" or "Always on")
    end

    reference.last_fl = cmd.chokedcommands
end)
