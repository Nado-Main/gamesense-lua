local ui_get, ui_set = ui.get, ui.set
local e_get_all, e_get_prop = entity.get_all, entity.get_prop
local ps_warning = ui.new_checkbox("VISUALS", "Other ESP", "Ping spike warning")

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

local function g_DormantPlayers(enemy_only, alive_only)
	local enemy_only = enemy_only ~= nil and enemy_only or false
	local alive_only = alive_only ~= nil and alive_only or true
	local result = {}

	local player_resource = e_get_all("CCSPlayerResource")[1]
	for player=1, globals.maxplayers() do
		if e_get_prop(player_resource, "m_bConnected", player) == 1 then
			local local_player_team, is_enemy, is_alive = nil, true, true
			if enemy_only then local_player_team = e_get_prop(entity.get_local_player(), "m_iTeamNum") end
			if enemy_only and e_get_prop(player, "m_iTeamNum") == local_player_team then is_enemy = false end
			if is_enemy then
				if alive_only and e_get_prop(player_resource, "m_bAlive", player) ~= 1 then is_alive = false end
				if is_alive then table.insert(result, player) end
			end
		end
	end

	return result
end

local g_Num, g_Curtime = {}, {}
client.set_event_callback("paint", function(c)
	local g_Local = entity.get_local_player()
	if not ui_get(ps_warning) or not g_Local then
		return
	end

	local g_Players = g_DormantPlayers(true, true)
	local g_CSPlayerResource = e_get_all("CCSPlayerResource")[1]

	if #g_Players == 0 then return end
	for i=1, #g_Players do
		if not g_Num[i] or not g_Curtime[i] then
			g_Num[i] = 0
			g_Curtime[i] = 0
		end

		local g_iLatency = e_get_prop(g_CSPlayerResource, string.format("%03d", g_Players[i]))
		local max_latency = (g_iLatency > 400 and 350 or g_iLatency)

		if g_Num[i] ~= g_iLatency and g_Curtime[i] < globals.realtime() then
			d = g_Num[i] > g_iLatency and -1 or 1
			g_Curtime[i] = globals.realtime() + 0.01

			g_Num[i] = g_Num[i] + d
		end

		local name = entity.get_player_name(g_Players[i])
		local y_additional = name == "" and -8 or 0
		local x1, y1, x2, y2, a_multiplier = entity.get_bounding_box(c, g_Players[i])
		if x1 ~= nil and a_multiplier > 0 then
			local x_center = x1 + (x2-x1)/2
			local r, g, b = g_ColorByInt(g_Num[i], 450)

			if x_center ~= nil then
				local d_number = (255 * a_multiplier)
				client.draw_text(c, x_center, y1 - 15 + y_additional, r, g, b, g_Num[i] > 75 and d_number or g_Num[i], "c-", 0, g_Num[i], " MS")
			end
		end
	end
end)