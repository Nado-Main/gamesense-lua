local ui_get, ui_set, g_realtime = ui.get, ui.set, globals.realtime
local e_get_all, e_get_prop = entity.get_all, entity.get_prop

local actions = { "Lock anti-aim", "Disable freestanding", "Disable feetyaw breaker" }

local yaw, yaw_num = ui.reference("AA", "Anti-aimbot angles", "Yaw")
local yaw_run, yaw_run_num = ui.reference("AA", "Anti-aimbot angles", "Yaw while running")
local yaw_jitter, yaw_jitter_num = ui.reference("AA", "Anti-aimbot angles", "Yaw jitter")
local fakeyaw, fakeyaw_num = ui.reference("AA", "Anti-aimbot angles", "Fake yaw")

local accuracy_boost = ui.reference("RAGE", "Other", "Accuracy boost options")
local freestanding = ui.reference("AA", "Anti-aimbot angles", "Freestanding")
local freestanding_real_yaw = ui.reference("AA", "Anti-aimbot angles", "Freestanding real yaw offset")
local freestanding_fake_yaw = ui.reference("AA", "Anti-aimbot angles", "Freestanding fake yaw offset")

local script_active = ui.new_checkbox("AA", "Other", "Anti-aim corrections")
local aa_opposite = ui.new_checkbox("AA", "Other", "Opposite fake yaw")
local freestand_jitter = ui.new_multiselect("AA", "Other", "Freestand jitter", { "Default", "Running" })
local aa_actions = ui.new_multiselect("AA", "Other", "Anti-aim functions", actions)
local actions_do = ui.new_hotkey("AA", "Other", "Anti-aim hotkey")

-- RED: 255, 0, 0
-- GREEN: 124, 195, 13

local function contains(tab, val)
    for index, value in ipairs(tab) do
        if value == val then return true end
    end

    return false
end

local function is_ent_moving(ent, speed)
    local x, y, z = e_get_prop(ent, "m_vecVelocity")
    return math.sqrt(x*x + y*y + z*z) > speed
end

local function g_Math(int, max, declspec)
	local int = (int > max and max or int)

	local tmp = max / int;
	local i = (declspec / tmp)
	i = (i >= 0 and math.floor(i + 0.5) or math.ceil(i - 0.5))

	return i
end

local function g_ColorByInt(number, max)
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

	i = g_Math(number, max, #Colors)
	return
		Colors[i <= 1 and 1 or i][1], 
		Colors[i <= 1 and 1 or i][2],
		Colors[i <= 1 and 1 or i][3]
end

function meta(v)
	local t = {v or 0}
	function postinc(t, i)
		local old = t[1]
		t[1] = t[1] + (i or 1)
		return old
	end

	setmetatable(t, {__call=postinc})
	return t
end

function clamp(angle)
    angle = angle % 360 
    angle = (angle + 360) % 360
    if angle > 180 then
        angle = angle - 360
    end

    return angle
end

local text = "AUTO"
local stored, set = false, true
local cached_freestand, cached_fr_fake, cached_fakeyaw, cached_fakeyaw_num, time = nil, nil, nil, nil, 0
local old_yaw, old_yaw_num, old_fakeyaw, old_fakeyaw_num, old_yaw_run, old_yaw_jitter, old_freestanding = nil, nil, nil, nil, nil, nil, nil

client.set_event_callback("run_command", function(c)
    if ui_get(script_active) and ui_get(yaw) and ui_get(fakeyaw) and c.chokedcommands == 0 then 
        text = "AUTO"

        -- Anti-aim locker
        local p_local = entity.get_local_player()
        if entity.is_alive(p_local) then
            _, zyaw = e_get_prop(p_local, "m_angAbsRotation")
            _, zfake, _ = e_get_prop(p_local, "m_angEyeAngles")

            if zyaw ~= nil then
                bodyyaw = e_get_prop(p_local, "m_flPoseParameter", 11)
                if bodyyaw ~= nil then
                    bodyyaw = bodyyaw * 120 - 60
                end
            end

            if zyaw ~= nil and bodyyaw ~= nil then
                if contains(ui_get(aa_actions), actions[1]) and ui_get(actions_do) then
                    if not stored then
                        old_yaw = ui_get(yaw)
                        old_yaw_num = ui_get(yaw_num)
                        old_fakeyaw = ui_get(fakeyaw)
                        old_fakeyaw_num = ui_get(fakeyaw_num)
                        old_yaw_run = ui_get(yaw_run)
                        old_yaw_jitter = ui_get(yaw_jitter)
                        old_freestanding = ui_get(freestanding)
                        stored = true
                    end

                    if not set then
                        ui_set(yaw, "Static")
                        ui_set(yaw_num, clamp(zyaw + bodyyaw))
                        ui_set(fakeyaw, "Static")
                        ui_set(fakeyaw_num, contains(ui_get(aa_actions), actions[3]) and clamp(zyaw + bodyyaw) or clamp(zfake))
                        ui_set(yaw_jitter,"Off")
                        ui_set(yaw_run, "Off")
                        ui_set(freestanding, "")
                        set = true
                    end

                    text = "STATIC"
                    return
                else
                    set = false
                    if old_yaw ~= nil then
                        ui_set(yaw, old_yaw)
                        ui_set(yaw_num, old_yaw_num)
                        ui_set(fakeyaw, old_fakeyaw)
                        ui_set(fakeyaw_num, old_fakeyaw_num)
                        ui_set(yaw_run, old_yaw_run)
                        ui_set(yaw_jitter, old_yaw_jitter)
                        ui_set(freestanding, old_freestanding)
                    end
                end
            end
        end

        -- Disable feetyaw breaker
        if cached_fr_fake == nil then
            cached_fr_fake = ui_get(freestanding_fake_yaw)
            cached_fakeyaw = ui_get(fakeyaw)
            cached_fakeyaw_num = ui_get(fakeyaw_num)            
        end

        if contains(ui_get(aa_actions), actions[3]) and ui_get(actions_do) then
            ui_set(freestanding_fake_yaw, 0)
            ui_set(fakeyaw, "Opposite")
            ui_set(fakeyaw_num, 180)
            text = "STATIC"
        else
            if cached_fr_fake ~= nil then
                ui_set(freestanding_fake_yaw, cached_fr_fake)
                ui_set(fakeyaw, cached_fakeyaw)
                ui_set(fakeyaw_num, cached_fakeyaw_num)
                cached_fr_fake = nil
            end
        end

        -- Disable freestanding on hotkey
        if cached_freestand == nil then
            cached_freestand = ui_get(freestanding)
        end

        if contains(ui_get(aa_actions), actions[2]) and ui_get(actions_do) then
            ui_set(freestanding, { "" })
            text = "OFF"
        else
            if cached_freestand ~= nil then
                ui_set(freestanding, cached_freestand)
                cached_freestand = nil
            end
        end

        -- Opposite fakeyaw
        if ui_get(aa_opposite) then
            ui_set(fakeyaw, "Opposite")

            n = ui_get(freestanding_fake_yaw) < 0 and -180 or 180
            ui_set(fakeyaw_num, n - ui_get(freestanding_fake_yaw))
        end

        -- Freestanding jitter
        local jitter_yaw, jitter_num =  ui_get(yaw_jitter),
                                        ui_get(yaw_jitter_num)

        if #ui_get(freestand_jitter) == 0 or jitter_yaw == "Off" then
            return
        end

        -- Movement checks
        local is_moving = is_ent_moving(entity.get_local_player(), 50)
        local get_default = contains(ui_get(freestand_jitter), "Default")
        local get_running = contains(ui_get(freestand_jitter), "Running")

        if not get_default or not get_running then
            if (not get_running and is_moving) or (get_running and not is_moving) then
                return
            end
        end

        if jitter_num > 60 then
            jitter_num = 60
        elseif jitter_num < -60 then
            jitter_num = -60
        end

        if (jitter_yaw == "Offset" or jitter_yaw == "Center") and g_realtime() > time then
            if(ui_get(freestanding_real_yaw) == jitter_num) then
                ui_set(freestanding_real_yaw, -jitter_num)
            else
                ui_set(freestanding_real_yaw, jitter_num)
            end

            time = g_realtime() + 0.01
        elseif jitter_yaw == "Random" then
            local random_counter = client.random_int(-jitter_num / 2, jitter_num / 2)
            ui_set(freestanding_real_yaw, random_counter)
        end
    end
end)

client.set_event_callback("paint", function(c)
	if ui_get(script_active) and ui_get(yaw) and ui_get(fakeyaw) then
        local r, g, b = 255, 0, 0
        local _, h = client.screen_size()
        h = (h / 2) + 5

        if not (contains(ui_get(aa_actions), actions[1]) and ui_get(actions_do)) then
            r, g, b = 124, 195, 13
        end

        local ind_value = meta(v)
        local ping = tonumber(string.format("%.f", client.latency() * 1000))
        local p_r, p_g, p_b = g_ColorByInt(ping - 35, 75)

        if contains(ui_get(accuracy_boost), "Extended backtrack") then
            renderer.text(10, h + (25 * ind_value()), 124, 195, 13, 255, "+", 0, "EXT")
        end

        renderer.text(10, h + (25 * ind_value()), r, g, b, 255, "+", 0, text)
        renderer.text(10, h + (25 * ind_value()), p_r, p_g, p_b, 255, "+", 0, "PING: ", ping)
    end
end)