local ui_get, ui_set = ui.get, ui.set
local e_get_all, e_get_prop = entity.get_all, entity.get_prop

local fr_y, rf = { }, {
	freestanding = ui.reference("AA", "Anti-aimbot angles", "Freestanding"),
	fr_realyaw = ui.reference("AA", "Anti-aimbot angles", "Freestanding real yaw offset"),
	fr_fakeyaw = ui.reference("AA", "Anti-aimbot angles", "Freestanding fake yaw offset"),

	crooked = ui.reference("AA", "Anti-aimbot angles", "Crooked"),
	twist = ui.reference("AA", "Anti-aimbot angles", "Twist"),

	flag_amount = ui.reference("AA", "Fake lag", "Amount")
}

for i = -90, 90 do
	if i > -36 and i < 36 then
		fr_y[i] = "Danger: " .. i
	elseif i > -61 and i < 61 then
		fr_y[i] = "Unsafe: " .. i
	end
end

local vars = { "Yaw correction", "Fake lowerbody in air", "Refine fake lag" }
local a_var = { "Default", "Basic" }

local aa_helper = ui.new_multiselect("AA", "Other", "Anti-aimbot helper", vars)
local aa_d = ui.new_combobox("AA", "Other", "Override yaw correction", a_var)
local aa_hotkey = ui.new_hotkey("AA", "Other", "Yaw correction hotkey")
local aa_fr_hotkey = ui.new_hotkey("AA", "Other", "Disable freestanding on key")

local aa_fr_breaker = ui.new_checkbox("AA", "Other", "Smart yaw direction")
local aa_fr_offset = ui.new_slider("AA", "Other", "Override freestanding offset", -90, 90, 63, true, "°", 1, fr_y)

local function contains(tab, val)
    for index, value in ipairs(tab) do
        if value == val then 
        	return true
        end
    end

    return false
end

local function is_ent_moving(ent, speed)
	local x, y, z = e_get_prop(ent, "m_vecVelocity")
	return math.sqrt(x*x + y*y + z*z) > speed
end

local function is_ent_onground(ent)
	local x, y, z = e_get_prop(ent, "m_vecVelocity")
	return math.sqrt(z^2) == 0
end

local function g_DormantPlayers(enemy_only, alive_only)
	local enemy_only = enemy_only ~= nil and enemy_only or false
	local alive_only = alive_only ~= nil and alive_only or true
	local result = {}

	local player_resource = e_get_all("CCSPlayerResource")[1]
	for player=1, globals.maxplayers() do
		if e_get_prop(player_resource, "m_bConnected", player) == 1 then

			local is_enemy, is_alive = true, true
			if enemy_only and not entity.is_enemy(player) then is_enemy = false end

			if is_enemy then
				if alive_only and not entity.is_alive(player) then is_alive = false end
				if is_alive then table.insert(result, player) end
			end

		end
	end

	return result
end

local function getAngles(cmd, ent)
	local lby = e_get_prop(ent, "m_flLowerBodyYawTarget")
	local _, yaw = e_get_prop(ent, "m_angAbsRotation")
	local _, fake, _ = e_get_prop(ent, "m_angEyeAngles")

	local real = nil
	if yaw ~= nil then
		local bodyyaw = e_get_prop(ent, "m_flPoseParameter", 11)
		if bodyyaw ~= nil then
			bodyyaw = bodyyaw * 120 - 60
			real = yaw + bodyyaw
		end
	end

	return { ["real"] = real, ["fake"] = fake, ["lby"] = lby, ["cam"] = camera }
end

local can_flick, last_act, last_fake, fr_cache = false, nil, nil, nil
client.set_event_callback("run_command", function(c)
	local g_pAAHelper = ui_get(aa_helper)
	local g_pLocal = entity.get_local_player()
	
	if fr_cache == nil then
        fr_cache = ui_get(rf.freestanding)
    end

    if ui_get(aa_fr_hotkey) then
        ui_set(rf.freestanding, { "" })
    else
        if fr_cache ~= nil then
            ui_set(rf.freestanding, fr_cache)
            fr_cache = nil
        end
    end
	
	if not g_pLocal or not entity.is_alive(g_pLocal) or #g_pAAHelper == 0 then
		return
	end

	-- Some stuff
	local g_Players = g_DormantPlayers(true, true)
	local g_PingAmount = { ["over"] = {}, ["normal"] = {} }
	local g_CSPlayerResource = e_get_all("CCSPlayerResource")[1]
	local angs = getAngles(c, g_pLocal)

	if contains(g_pAAHelper, vars[3]) and #g_Players then -- Adaptive fakelag
		for i=1, #g_Players do
			local Latency = e_get_prop(g_CSPlayerResource, string.format("%03d", g_Players[i]))
			if entity.is_alive(g_Players[i]) and Latency > 0 then
				table.insert(Latency > 45 and g_PingAmount["over"] or g_PingAmount["normal"], Latency)
			end
		end

		ui_set(rf.flag_amount, #g_PingAmount.over > #g_PingAmount.normal and "Maximum" or "Dynamic")
	end

	if ui_get(aa_fr_breaker) then
		if cache == nil then
			cache = ui_get(rf.fr_fakeyaw)
		end

		if ui_get(aa_hotkey) and not is_ent_moving(g_pLocal, 1) then
			ui_set(rf.fr_fakeyaw, ui_get(aa_fr_offset))
		else
			if cache ~= nil then
				ui_set(rf.fr_fakeyaw, cache)
				cache = nil
			end
		end
	end

	if contains(g_pAAHelper, vars[1]) then -- Breaking resolvers
		if not is_ent_moving(g_pLocal, 1) and is_ent_onground(g_pLocal) then

			local n = ui_get(aa_d)
			local cr, tw = false, false

			if n == a_var[1] then -- Full
				if ui_get(aa_hotkey) then
					cr, tw = true, true
				end
			elseif n == a_var[2] then -- Dynamic
				cr = true
				if ui_get(aa_hotkey) then
					tw = true
				end
			end

			if ui_get(aa_fr_breaker) then

				if can_flick == false and last_fake ~= angs.lby then
					can_flick = ui_get(aa_hotkey)
				end

				cr, tw = can_flick, can_flick
			end

			ui_set(rf.crooked, cr)
			ui_set(rf.twist, tw)
		elseif contains(g_pAAHelper, vars[2]) then
			-- Crooked in AIR
			ui_set(rf.crooked, not is_ent_onground(g_pLocal))
			ui_set(rf.twist, not is_ent_onground(g_pLocal))
		else
			ui_set(rf.crooked, false)
			ui_set(rf.twist, false)
		end
	elseif contains(g_pAAHelper, vars[2]) then -- Crooked in AIR
		ui_set(rf.crooked, not is_ent_onground(g_pLocal))
	else
		ui_set(rf.crooked, false)
		ui_set(rf.twist, false)
	end

	if ui_get(aa_hotkey) ~= last_act then
		last_fake = angs.lby
		can_flick = false
	end

	last_act = ui_get(aa_hotkey)
end)

local function visibility()
	local a = ui_get(aa_helper)
	local fr_b = ui_get(aa_fr_breaker)
	local cyaw_active = contains(a, vars[1])

	ui.set_visible(aa_d, cyaw_active)
	ui.set_visible(aa_hotkey, cyaw_active)
	ui.set_visible(aa_fr_breaker, cyaw_active)
	ui.set_visible(aa_fr_offset, cyaw_active and fr_b)
end

visibility()
ui.set_callback(aa_helper, visibility)
ui.set_callback(aa_fr_breaker, visibility)
