local cond = { "On visible", "While visible" }

local cache = { }
local reference = {
    is_active = ui.new_checkbox("AA", "Fake lag", "Customize peek fake-lags"),

    nervos = ui.new_checkbox("AA", "Fake lag", "On peek nervos"),
    nervos_key = ui.new_hotkey("AA", "Fake lag", "On peek nervos hotkey", true),

    condition = ui.new_combobox("AA", "Fake lag", "\n fl_condition", cond),
    extrapolation = ui.new_slider("AA", "Fake lag", "Extrapolation (ticks)", 5, 15, 8, true),

    normal_choke = ui.new_slider("AA", "Fake lag", "Normal limit", 4, 14, 11, true),
    maximum_choke = ui.new_slider("AA", "Fake lag", "Maximum limit", 4, 14, 14, true),

    vizualise = ui.new_checkbox("AA", "Fake lag", "Vizualise extrapolation"),
    vizualise_color = ui.new_color_picker("AA", "Fake lag", "Vizualisation color", 90, 236, 138, 255),

    fl = ui.reference("AA", "Fake lag", "Enabled"),
    fl_customize = ui.reference("AA", "Fake lag", "Customize triggers"),
    fl_triggers = ui.reference("AA", "Fake lag", "Triggers"),
    fl_limit = ui.reference("AA", "Fake lag", "Limit"),

    minimum_dmg = ui.reference("RAGE", "Aimbot", "Minimum Damage"),
    fake_duck = ui.reference("RAGE", "Other", "Duck peek assist"),
    onshot = { ui.reference("AA", "Other", "On shot anti-aim") },

    pos = { },
    last_fl = 0
}

local ui_set, ui_get, math_sqrt = ui.set, ui.get, math.sqrt
local entity_get_prop = entity.get_prop
local entity_is_alive = entity.is_alive
local globals_tickinterval = globals.tickinterval
local client_trace_line = client.trace_line
local client_trace_bullet = client.trace_bullet
local entity_is_enemy = entity.is_enemy
local entity_get_local_player = entity.get_local_player
local entity_get_players = entity.get_players
local entity_hitbox_position = entity.hitbox_position

local function invoke_cache_callback(condition, should_call, VAR)
    local hotkey_modes = {
        [0] = "always on",
        [1] = "on hotkey",
        [2] = "toggle",
        [3] = "off hotkey"
    }

    local _cond = ui_get(condition)
    local _type = type(_cond)

    local name = tostring(condition)

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

local function is_moving(index)
    local x, y, z = entity_get_prop(index, "m_vecVelocity")
    return math.sqrt(x*x + y*y + z*z) > 1.0
end

local function vec_add(a, b) 
    return { a[1] + b[1], a[2] + b[2], a[3] + b[3] }
end

local lag_data = { 
    count = 0, 
    passed = false,
    phase = 0,
    extrapolated = { }
}

lag_data.should_lag = function() return (lag_data.count > 0) end
lag_data.reset = function()
    lag_data.count = 0
    lag_data.extrapolated = { }
    reference.pos = { }
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

local function menu_callback(arg)
    local active = ui_get(reference.is_active)

    ui.set_visible(reference.nervos, active)
    ui.set_visible(reference.nervos_key, active)

    ui.set_visible(reference.condition, active)
    ui.set_visible(reference.extrapolation, active)

    ui.set_visible(reference.normal_choke, active)
    ui.set_visible(reference.maximum_choke, active)

    ui.set_visible(reference.vizualise, active)
    ui.set_visible(reference.vizualise_color, active)

    if arg == nil then
        ui.set_callback(reference.is_active, menu_callback)
    end
end

menu_callback()

client.set_event_callback("paint", function()
    local me = entity_get_local_player()

    if not ui_get(reference.is_active) or not me or not entity_is_alive(me) then
        return
    end

    if ui_get(reference.nervos) and ui_get(reference.nervos_key) then
        renderer.indicator(255, 255, 255, 150, "NV")
    end

    if not ui_get(reference.vizualise) then
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

    -- Setup fake lag
    local new_triggers = { }
    local cur_triggers = ui_get(reference.fl_triggers)
    local blacklist_triggers = { } -- { "On accelerate", "On enemy visible", "While enemy visible", "While moving" }

    for i=1, #cur_triggers do
        if not compare(blacklist_triggers, cur_triggers[i]) then
            new_triggers[#new_triggers+1] = cur_triggers[i]
        end
    end

    ui_set(reference.fl_customize, true)
    ui_set(reference.fl_triggers, new_triggers)

    lag_data.reset() -- Reset previous command
    
    -- Process prediction
    if not is_moving(me) then reference.pos[1] = eye_pos else
        local v_offset = { entity_get_prop(me, "m_vecViewOffset") }

        for i = 1, ui_ticks do
            local predicted_data = lag_data.predict_player(me, i, true)
            reference.pos[i] = vec_add(predicted_data.origin, v_offset)
        end
    end

    for i=1, #players do
        if entity_get_prop(players[i], "m_bGunGameImmunity") == 0 then
            local hitboxes = {
                { entity_hitbox_position(players[i], 0) },
                { entity_hitbox_position(players[i], 4) },
                { entity_hitbox_position(players[i], 2) }
            }

            local pass, rpos = 
                false, reference.pos

            for i = 1, #rpos do
                if not pass and lag_data.trace_positions(me, rpos[i], hitboxes) then
                    pass = true
                end
            end

            if pass then
                lag_data.count = lag_data.count + 1
            end
        end
    end

    local should_lag = lag_data.should_lag() and not ui_get(reference.fake_duck)
    local is_nervos = ui_get(reference.nervos) and ui_get(reference.nervos_key)

    invoke_cache_callback(reference.onshot[1], is_nervos, true)
    invoke_cache_callback(reference.onshot[2], is_nervos, "Always on")

    ui_set(reference.fl_limit, ui_get(reference.normal_choke))

    if should_lag then
        if is_nervos then ui_set(reference.onshot[2], "On Hotkey") else
            if lag_data.phase == 0 then
                ui_set(reference.fl_limit, 1)
                lag_data.phase = 1
            else
                if reference.last_fl > 3 and cmd.chokedcommands < reference.last_fl then
                    lag_data.passed = true
                end
            
                if condition == cond[2] or not lag_data.passed then
                    ui_set(reference.fl_limit, ui_get(reference.maximum_choke))
                    cmd.allow_send_packet = false
                end
            end
        end
    elseif lag_data.passed or lag_data.phase ~= 0 then
        lag_data.passed = false
        lag_data.phase = 0
    end

    reference.last_fl = cmd.chokedcommands
end)
