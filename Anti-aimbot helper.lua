local ui_get, ui_set = ui.get, ui.set
local e_get_all, e_get_prop = entity.get_all, entity.get_prop

local rf = {
	freestanding = ui.reference("AA", "Anti-aimbot angles", "Freestanding"),
	fr_realyaw = ui.reference("AA", "Anti-aimbot angles", "Freestanding real yaw offset"),
	fr_fakeyaw = ui.reference("AA", "Anti-aimbot angles", "Freestanding fake yaw offset"),

	crooked = ui.reference("AA", "Anti-aimbot angles", "Crooked"),
	twist = ui.reference("AA", "Anti-aimbot angles", "Twist"),

	flag_amount = ui.reference("AA", "Fake lag", "Amount")
}

local vars = { "Accurate yaw on unlag", "Reset LBY in air", "Refine fake lag" }
local aa_helper = ui.new_multiselect("AA", "Other", "Anti-aimbot helper", vars)
local aa_hotkey = ui.new_hotkey("AA", "Other", "Anti-aimbot hotkey")

local function contains(tab, val)
    for index, value in ipairs(tab) do
        if value == val then return true end
    end

    return false
end

local function is_ent_moving(ent, speed)
	local x, y, z = entity.get_prop(ent, "m_vecVelocity")
	return math.sqrt(x*x + y*y + z*z) > speed
end

local function is_ent_onground(ent)
	local x, y, z = entity.get_prop(ent, "m_vecVelocity")
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
				if alive_only and not entity.is_alive(player) then  is_alive = false end
				if is_alive then table.insert(result, player) end
			end

		end
	end

	return result
end

client.set_event_callback("run_command", function(c)
	local g_pAAHelper = ui_get(aa_helper)
	local g_pLocal = entity.get_local_player()
	
	if not g_pLocal or not entity.is_alive(g_pLocal) or #g_pAAHelper == 0 then
		return
	end

	-- Some stuff
	local g_Players = g_DormantPlayers(true, true)
	local g_PingAmount = { ["over"] = {}, ["normal"] = {} }
	local g_CSPlayerResource = e_get_all("CCSPlayerResource")[1]

	if contains(g_pAAHelper, vars[3]) and #g_Players then -- Adaptive fakelag
		for i=1, #g_Players do
			local Latency = e_get_prop(g_CSPlayerResource, string.format("%03d", g_Players[i]))
			if entity.is_alive(g_Players[i]) and Latency > 0 then
				table.insert(Latency > 45 and g_PingAmount["over"] or g_PingAmount["normal"], Latency)
			end
		end

		ui_set(rf.flag_amount, #g_PingAmount.over > #g_PingAmount.normal and "Maximum" or "Dynamic")
	end

	if  contains(g_pAAHelper, vars[1]) then -- Breaking resolvers
		if not is_ent_moving(g_pLocal, 1) and is_ent_onground(g_pLocal) and ui_get(aa_hotkey) then
			ui_set(rf.crooked, true)
			ui_set(rf.twist, true)
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
end)